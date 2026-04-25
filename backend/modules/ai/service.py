"""
AI Service — Kỹ Năng Sống 4.0
===============================
Kiến trúc:
  1. RAG Layer     : Embedding-based semantic search trong MongoDB
  2. Memory Layer  : Conversation history (3 msgs + session summary)
  3. Personalization: Dựa trên skill_stats của user
  4. Fallback Logic: Khi không có tài liệu → general knowledge + warning
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from functools import lru_cache

import numpy as np
from fastapi import HTTPException

from core.config import settings
from core.database import get_db
from google import genai

# ── Gemini client ─────────────────────────────────────────────────────────────
_client = genai.Client(api_key=settings.GEMINI_API_KEY)
_MODELS = [
    "gemini-flash-lite-latest",   # ✅ Đang hoạt động
    "gemini-pro-latest",          # Fallback pro
    "gemini-2.5-flash",           # Fallback mạnh
    "gemini-2.5-flash-lite",      # Fallback lite
]

# ── Embedding model (lazy load để tránh chậm startup) ─────────────────────────
_embedder = None
_embedder_lock = asyncio.Lock()

async def _get_embedder():
    """Lazy-load SentenceTransformer lần đầu gọi."""
    global _embedder
    if _embedder is not None:
        return _embedder
    async with _embedder_lock:
        if _embedder is None:
            from sentence_transformers import SentenceTransformer
            # Chạy trong thread pool để không block event loop
            loop = asyncio.get_event_loop()
            _embedder = await loop.run_in_executor(
                None,
                lambda: SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
            )
    return _embedder

async def _encode(text: str) -> list[float]:
    """Tạo embedding vector cho 1 đoạn text."""
    model = await _get_embedder()
    loop = asyncio.get_event_loop()
    vec = await loop.run_in_executor(None, lambda: model.encode(text))
    return vec.tolist()

def _cosine_similarity(a: list[float], b: list[float]) -> float:
    """Tính cosine similarity giữa 2 vector."""
    va, vb = np.array(a), np.array(b)
    denom = np.linalg.norm(va) * np.linalg.norm(vb)
    if denom == 0:
        return 0.0
    return float(np.dot(va, vb) / denom)

# ── Mapping skill tag → tiếng Việt ────────────────────────────────────────────
_SKILL_TAG_VI = {
    "communication":     "Kỹ năng Giao Tiếp",
    "emotion":           "Quản lý Cảm Xúc",
    "finance":           "Quản lý Tài Chính",
    "critical_thinking": "Tư Duy Phản Biện & Quản Lý Thời Gian",
    "teamwork":          "Làm Việc Nhóm",
    "health":            "Sức Khỏe & Thể Chất",
}

# ── AI Persona (enforce nhất quán ở mọi level) ────────────────────────────────
OWL_PERSONA = (
    'Bạn là AI Mentor "Owl" của ứng dụng Kỹ Năng Sống 4.0.\n'
    'Tính cách: thân thiện như người bạn, coaching style (hỏi–gợi ý, không giảng bài), '
    'ngắn gọn và rõ ràng, dùng emoji vừa phải. '
    'KHÔNG dùng giọng điệu formal hay academic. KHÔNG giảng bài khi user chưa yêu cầu.\n'
)

# ── Hybrid Intent Detection ───────────────────────────────────────────────────
_GREETING_WORDS = {"chào", "hi", "hello", "hey", "xin chào", "alo", "helo", "chao"}
_CASUAL_WORDS   = {"cảm ơn", "ok", "oke", "okay", "được rồi", "cảm ơn bạn", "tốt", "tuyệt", "hiểu rồi"}
_DEEP_WORDS     = {"chi tiết", "giải thích kỹ", "hướng dẫn từng bước", "ví dụ cụ thể", "phân tích sâu", "cho mình biết thêm"}
_OFF_WORDS      = {"toán", "lập trình", "code", "nấu ăn", "thể thao", "bóng đá", "phim", "âm nhạc"}


def _rule_intent(text: str, word_count: int) -> int | None:
    """
    Rule-based layer — fast path, covers ~80% cases.
    Returns intent level (0-4) or None if ambiguous → cần LLM fallback.
    """
    t = text.lower().strip()
    has_question = any(w in t for w in ["?", "làm sao", "tại sao", "như thế nào", "cách", "giúp", "hỏi"])

    # Off-topic check trước
    if any(w in t for w in _OFF_WORDS) and not any(w in t for w in ["kỹ năng", "giao tiếp", "cảm xúc"]):
        return 0

    # Greeting: ngắn + có từ chào + không có câu hỏi đi kèm
    if word_count <= 5 and any(w in t for w in _GREETING_WORDS) and not has_question:
        return 1

    # Casual: cảm ơn / xác nhận ngắn
    if word_count <= 6 and any(w in t for w in _CASUAL_WORDS):
        return 2

    # Deep: yêu cầu giải thích kỹ
    if any(w in t for w in _DEEP_WORDS):
        return 4

    # Ambiguous → cần LLM
    return None


async def _llm_intent(text: str) -> int:
    """
    LLM classify — cheap 1-shot prompt, chỉ gọi khi rule-based không kết luận được.
    """
    prompt = (
        f'Phân loại câu sau thành 1 số duy nhất (không giải thích):\n'
        f'1=chào hỏi đơn thuần  2=casual/cảm ơn/xác nhận  3=hỏi về kỹ năng sống  '
        f'4=muốn học sâu/chi tiết  0=ngoài chủ đề kỹ năng sống\n'
        f'Câu: "{text[:200]}"\n'
        f'Trả về đúng 1 chữ số:'
    )
    try:
        raw = await _generate_with_fallback(prompt)
        digit = raw.strip()[0]
        if digit in "01234":
            return int(digit)
    except Exception:
        pass
    return 3  # safe default


async def _detect_intent(text: str, conversation_state: dict) -> int:
    """
    Hybrid Intent Detector:
    - Layer 1: Context awareness (nếu đang trong topic → bias về question)
    - Layer 2: Rule-based (fast, 80% cases)
    - Layer 3: LLM fallback (chính xác, 20% ambiguous cases)
    """
    word_count = len(text.split())

    # Layer 1: Context awareness
    # Nếu đang trong hội thoại về 1 topic + câu ngắn → vẫn là question (không phải greeting)
    if conversation_state.get("topic") and word_count > 2:
        # Chỉ override nếu không phải clearly greeting
        t = text.lower().strip()
        if not (word_count <= 3 and any(w in t for w in _GREETING_WORDS)):
            return 3

    # Layer 2: Rule-based
    result = _rule_intent(text, word_count)
    if result is not None:
        return result

    # Layer 3: LLM fallback
    return await _llm_intent(text)

from .schemas import ChatRequest, ContextChatRequest, RecommendRequest


# ── Gemini call với fallback model ────────────────────────────────────────────
async def _generate_with_fallback(prompt: str) -> str:
    """Thử lần lượt các model, bỏ qua 503/404, raise nếu tất cả fail."""
    last_error = None
    for model in _MODELS:
        try:
            response = await _client.aio.models.generate_content(
                model=model, contents=prompt
            )
            return response.text
        except Exception as e:
            err_str = str(e)
            if any(code in err_str for code in ["503", "404", "UNAVAILABLE", "NOT_FOUND", "ServerError"]):
                last_error = e
                continue
            raise
    raise last_error


# ── RAG: Semantic search trong MongoDB ────────────────────────────────────────
async def _rag_search(query: str, top_k: int = 3) -> tuple[list[str], list[dict]]:
    """
    Tìm kiếm ngữ nghĩa (semantic) tài liệu liên quan đến query.
    
    Returns:
        docs_for_prompt : danh sách đoạn text đưa vào prompt
        skill_cards     : danh sách skill object trả về cho Flutter UI
    """
    db = get_db()
    query_vec = await _encode(query)

    # Lấy tất cả skills có embedding
    skills_with_emb = await db.skills.find(
        {"embedding": {"$exists": True, "$ne": []}}
    ).to_list(length=500)

    # Tính similarity
    scored: list[tuple[float, dict]] = []
    for s in skills_with_emb:
        sim = _cosine_similarity(query_vec, s["embedding"])
        if sim > 0.25:  # Threshold: bỏ qua nếu quá khác nhau
            scored.append((sim, s))

    # Nếu không đủ kết quả qua embedding → fallback sang regex search
    if len(scored) < 1:
        keywords = query.lower().split()[:4]
        regex = "|".join([k for k in keywords if len(k) > 2])
        if regex:
            cursor = db.skills.find({
                "$or": [
                    {"title": {"$regex": regex, "$options": "i"}},
                    {"description": {"$regex": regex, "$options": "i"}},
                ]
            }).limit(top_k)
            skills_fallback = await cursor.to_list(length=top_k)
            for s in skills_fallback:
                scored.append((0.3, s))  # dummy score

    # Sort và lấy top-k
    scored.sort(key=lambda x: x[0], reverse=True)
    top_docs = scored[:top_k]

    # Tạo context text cho prompt
    docs_text: list[str] = []
    skill_cards: list[dict] = []

    for _, s in top_docs:
        # Lấy nội dung: ưu tiên content > description
        content = s.get("content") or s.get("description") or ""
        chunk = f"[{s['title']}]: {content[:400]}"
        docs_text.append(chunk)
        skill_cards.append({
            "id": str(s["_id"]),
            "title": s.get("title"),
            "image_url": s.get("image_url"),
            "category": s.get("category"),
        })

    return docs_text, skill_cards


# ── Conversation Memory ───────────────────────────────────────────────────────
def _build_memory_block(history: list[dict], session_summary: str) -> str:
    """
    Tạo memory block từ history + summary.
    Giữ tối đa 3 cặp messages gần nhất để tránh token overflow.
    """
    if not history and not session_summary:
        return ""

    lines = ["[LỊCH SỬ HỘI THOẠI]:"]
    if session_summary:
        lines.append(f"(Tóm tắt đầu phiên: {session_summary})")

    # Lấy 6 messages gần nhất (3 cặp user/assistant)
    recent = history[-6:]
    for msg in recent:
        role = "Học viên" if msg.get("role") == "user" else "Owl"
        content = str(msg.get("content", ""))[:200]  # Giới hạn độ dài mỗi msg
        lines.append(f"{role}: {content}")

    return "\n".join(lines)


# ── Personalization block ─────────────────────────────────────────────────────
def _build_personalization_block(progress: dict) -> str:
    skill_stats = progress.get("skill_stats", {})
    current_round = progress.get("current_round", 1)
    total_points = progress.get("total_exam_points", 0)

    active = {k: v for k, v in skill_stats.items() if v > 0}
    weakest = ""
    strongest = ""
    if active:
        weakest = _SKILL_TAG_VI.get(min(active, key=lambda k: active[k]), "chưa xác định")
        strongest = _SKILL_TAG_VI.get(max(active, key=lambda k: active[k]), "chưa xác định")

    skill_desc = ", ".join([
        f"{_SKILL_TAG_VI.get(k, k)}: {int(v)}đ"
        for k, v in skill_stats.items() if v > 0
    ]) or "chưa có dữ liệu thi"

    return (
        f"[THÔNG TIN HỌC VIÊN]:\n"
        f"- Tiến độ: Vòng {current_round}/16 ({total_points} XP)\n"
        f"- Kỹ năng yếu nhất: {weakest or 'chưa xác định'} → ưu tiên ví dụ liên quan\n"
        f"- Kỹ năng mạnh nhất: {strongest or 'chưa xác định'}\n"
        f"- Bảng điểm: {skill_desc}\n"
    )


# ── Suggested questions ───────────────────────────────────────────────────────
async def _generate_suggested_questions(query: str, docs: list[str]) -> list[str]:
    """Tạo 2 câu hỏi gợi ý dựa trên RAG docs."""
    if not docs:
        return []
    try:
        context_title = docs[0][:80] if docs else query
        suggest_prompt = (
            f'Dựa trên nội dung: "{context_title}"\n'
            f'và câu hỏi: "{query}"\n'
            f'Tạo đúng 2 câu hỏi ngắn (< 10 từ) mà người dùng có thể hỏi tiếp.\n'
            f'Chỉ trả về JSON array, ví dụ: ["Câu hỏi 1?", "Câu hỏi 2?"]'
        )
        raw = await _generate_with_fallback(suggest_prompt)
        # Parse JSON từ response
        import json, re
        match = re.search(r'\[.*?\]', raw, re.DOTALL)
        if match:
            return json.loads(match.group())[:2]
    except Exception:
        pass
    return []


# ── Prompt builders theo từng level ─────────────────────────────────────────
def _prompt_greeting() -> str:
    return (
        OWL_PERSONA
        + "\nUser vừa chào bạn. Hãy:\n"
        "1. Chào lại thân thiện, ngắn gọn (1 câu).\n"
        "2. Giới thiệu mình có thể giúp gì (1 câu).\n"
        "3. Đưa ra menu 3 lựa chọn dạng emoji button để user chọn nhanh.\n\n"
        "Ví dụ format:\n"
        "Chào bạn! 👋 Mình là Owl – trợ lý kỹ năng sống của bạn.\n\n"
        "Bạn muốn bắt đầu với chủ đề nào?\n"
        "🗣️ **Giao tiếp & Thuyết trình**\n"
        "💰 **Quản lý tài chính**\n"
        "🧠 **Cải thiện bản thân**\n\n"
        "Hoặc cứ hỏi thẳng điều bạn đang cần nhé!"
    )


def _prompt_casual(query: str, memory_block: str) -> str:
    return (
        OWL_PERSONA
        + (f"\n{memory_block}\n" if memory_block else "")
        + f"\nUser nói: \"{query}\"\n"
        "Hãy phản hồi thân thiện, ngắn (1-2 câu), và hỏi thêm 1 câu mở để tiếp tục hội thoại.\n"
        "KHÔNG giảng bài, KHÔNG đưa bài học nếu user chưa yêu cầu."
    )


def _prompt_question(
    query: str,
    retrieval_block: str,
    personalization_block: str,
    memory_block: str,
) -> str:
    return (
        OWL_PERSONA
        + f"\n{personalization_block}\n{retrieval_block}\n{memory_block}\n"
        + f"Câu hỏi: {query}\n\n"
        "Trả lời theo format JSON sau (không thêm text ngoài JSON):\n"
        '{"short": "[Trả lời ngắn gọn 2-4 bullet, mỗi bullet 1 dòng, dùng emoji]", '
        '"full": "[Giải thích đầy đủ với format: ✅ Tình huống | ⚠️ Điều cần tránh | 📌 Các bước | 💡 Lời khuyên]"}'
        "\n\nQuy tắc:\n"
        "- short: tối đa 80 từ, coaching tone, KHÔNG lecture\n"
        "- full: format 4-section đầy đủ, chi tiết hơn\n"
        "- Nếu không liên quan kỹ năng sống: short=\"Mình chỉ hỗ trợ kỹ năng sống 😊\", full=\"\""
    )


def _prompt_deep(
    query: str,
    retrieval_block: str,
    personalization_block: str,
    memory_block: str,
) -> str:
    return (
        OWL_PERSONA
        + f"\n{personalization_block}\n{retrieval_block}\n{memory_block}\n"
        + f"Câu hỏi: {query}\n\n"
        "Trả lời đầy đủ, chi tiết. Format Markdown:\n"
        "✅ **Tình huống:** [Phân tích 1 dòng]\n"
        "⚠️ **Điều cần tránh:** [Sai lầm thường gặp]\n"
        "📌 **Các bước xử lý:**\n"
        "  - [Bước 1]\n"
        "  - [Bước 2]\n"
        "  - [Bước 3]\n"
        "💡 **Lời khuyên thêm:** [Tip cá nhân hóa theo profile học viên]\n"
        "Cá nhân hóa dựa trên kỹ năng yếu nhất nếu có dữ liệu."
    )


def _prompt_offtopic() -> str:
    return (
        OWL_PERSONA
        + "\nUser hỏi điều không liên quan đến kỹ năng sống. "
        "Hãy từ chối lịch sự (1 câu) và gợi ý 2 chủ đề kỹ năng sống bạn có thể giúp."
    )


# ── Main: Context Chat (endpoint chính của chatbox) ──────────────────────────
async def ai_context_chat(body: ContextChatRequest) -> dict:
    """
    Chat có ngữ cảnh đầy đủ với Adaptive Response System:
    - Hybrid Intent Detection: rule-based + LLM fallback
    - Context Awareness: conversation_state (topic, last_intent)
    - 4 Response Levels: greeting / casual / question / deep
    - Dual Response: short_answer + full_answer (Flutter expand inline)
    - RAG: tìm tài liệu ngữ nghĩa từ MongoDB
    - Personalization: dựa trên skill_stats
    """
    import json as _json, re as _re

    # ── 1. Detect intent (hybrid) ───────────────────────────────────────────
    level = await _detect_intent(body.query, body.conversation_state)

    # ── 2. Skip RAG cho greeting/casual/off-topic (tiết kiệm latency) ──────
    rag_docs: list[str] = []
    skill_cards: list[dict] = []
    if level in (3, 4):
        rag_docs, skill_cards = await _rag_search(body.query)

    # ── 3. Personalization ──────────────────────────────────────────────────
    personalization_block = ""
    if body.include_progress and level in (3, 4):
        try:
            from modules.exam.service import _get_or_create_progress
            progress = await _get_or_create_progress(body.user_id)
            personalization_block = _build_personalization_block(progress)
        except Exception:
            pass

    # ── 4. Retrieval block ──────────────────────────────────────────────────
    if rag_docs:
        retrieval_block = (
            "[TÀI LIỆU NỘI BỘ]:\n---\n"
            + "\n\n".join(rag_docs)
            + "\n---\nƯu tiên sử dụng thông tin trên.\n"
        )
    else:
        retrieval_block = (
            "[LƯU Ý]: Không tìm thấy tài liệu nội bộ liên quan. "
            "Trả lời dựa trên kiến thức chung về kỹ năng sống.\n"
        )

    # ── 5. Memory block ─────────────────────────────────────────────────────
    memory_block = _build_memory_block(body.history, body.session_summary)

    # ── 6. Chọn prompt theo level ───────────────────────────────────────────
    short_answer = ""
    full_answer = ""
    can_expand = False

    try:
        if level == 0:  # Off-topic
            prompt = _prompt_offtopic()
            short_answer = await _generate_with_fallback(prompt)

        elif level == 1:  # Greeting
            prompt = _prompt_greeting()
            short_answer = await _generate_with_fallback(prompt)

        elif level == 2:  # Casual
            prompt = _prompt_casual(body.query, memory_block)
            short_answer = await _generate_with_fallback(prompt)

        elif level == 3:  # Question → dual response
            prompt = _prompt_question(
                body.query, retrieval_block, personalization_block, memory_block
            )
            raw = await _generate_with_fallback(prompt)
            # Parse dual response JSON
            match = _re.search(r'\{.*\}', raw, _re.DOTALL)
            if match:
                try:
                    parsed = _json.loads(match.group())
                    short_answer = parsed.get("short", raw)
                    full_answer  = parsed.get("full", "")
                    can_expand   = bool(full_answer)
                except _json.JSONDecodeError:
                    short_answer = raw
            else:
                short_answer = raw

        else:  # level == 4, Deep learn
            prompt = _prompt_deep(
                body.query, retrieval_block, personalization_block, memory_block
            )
            full_answer  = await _generate_with_fallback(prompt)
            short_answer = full_answer  # hiển thị full ngay

    except Exception as e:
        import traceback; traceback.print_exc()
        err = str(e)
        if any(c in err for c in ["503", "UNAVAILABLE", "quota", "429"]):
            raise HTTPException(status_code=503, detail="AI đang bận, vui lòng thử lại sau vài giây.")
        raise HTTPException(status_code=500, detail="Lỗi kết nối AI. Vui lòng thử lại.")

    # ── 7. Suggested questions (chỉ cho level 3, 4) ─────────────────────────
    suggested = []
    if level in (3, 4):
        try:
            suggested = await _generate_suggested_questions(body.query, rag_docs)
        except Exception:
            pass

    return {
        "answer":             short_answer,
        "full_answer":        full_answer,
        "intent_level":       level,
        "can_expand":         can_expand,
        "related_skills":     skill_cards,
        "suggested_questions": suggested,
        "rag_used":           len(rag_docs) > 0,
    }


# ── Simple chat (giữ lại cho backward compat) ────────────────────────────────
async def ai_chat(body: ChatRequest) -> dict:
    """Endpoint đơn giản, delegate sang context_chat."""
    ctx = ContextChatRequest(
        query=body.query,
        user_id=body.user_id,
        include_progress=True,
        history=[],
    )
    return await ai_context_chat(ctx)


# ── AI Recommend Path (sau khi thi) ──────────────────────────────────────────
async def ai_recommend_path(body: RecommendRequest) -> dict:
    skill_lines, weak_skills, strong_skills = [], [], []
    for tag, score in body.skill_stats.items():
        vi_name = _SKILL_TAG_VI.get(tag, tag)
        score_int = int(score)
        if score_int > 0:
            skill_lines.append(f"  - {vi_name}: {score_int} điểm")
            if score_int >= 20:
                strong_skills.append(vi_name)
            elif score_int < 10:
                weak_skills.append(vi_name)

    accuracy = round(body.correct_count / max(body.total_questions, 1) * 100)
    status = "PASSED" if body.passed else "FAILED"
    prompt = f"""Bạn là AI Mentor "Owl" của ứng dụng Kỹ Năng Sống 4.0.
Kết quả Vòng {body.round_id}: {status}, {body.correct_count}/{body.total_questions} câu ({accuracy}%)
Điểm mạnh: {', '.join(strong_skills) or 'đang phát triển'}
Cần cải thiện: {', '.join(weak_skills) or 'không có'}
Bảng điểm: {chr(10).join(skill_lines) or 'Chưa có dữ liệu'}

Format chính xác (không thêm text nào khác):
🦉 **Nhận xét:** [1 câu có dữ liệu cụ thể]
💪 **Điểm mạnh:** [1 câu khen]
🎯 **Cần cải thiện:** [1 câu chỉ ra kỹ năng yếu]
🚀 **Gợi ý tiếp theo:** [1 câu cụ thể]"""

    try:
        advice = (await _generate_with_fallback(prompt)).strip()
        db = get_db()
        await db.ai_recommendations.insert_one({
            "user_id": body.user_id, "round_id": body.round_id,
            "passed": body.passed, "accuracy": accuracy,
            "skill_stats": body.skill_stats, "ai_advice": advice,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        return {"advice": advice, "weak_skills": weak_skills,
                "strong_skills": strong_skills, "accuracy": accuracy}
    except Exception as e:
        import traceback; traceback.print_exc()
        err = str(e)
        if any(c in err for c in ["503", "UNAVAILABLE", "quota", "429"]):
            raise HTTPException(status_code=503, detail="AI đang bận, vui lòng thử lại sau vài giây.")
        raise HTTPException(status_code=500, detail="Lỗi kết nối AI. Vui lòng thử lại.")


# ── AI Recommendation (học bài) ───────────────────────────────────────────────
async def get_ai_recommendation(user_id: str) -> dict:
    db = get_db()
    from bson import ObjectId
    cursor = db.learning_progress.find({"user_id": user_id, "status": "completed"})
    completed_lessons = await cursor.to_list(length=100)
    lesson_ids = [ls["lesson_id"] for ls in completed_lessons]

    history_text = "Học viên này là người mới, chưa hoàn thành kỹ năng nào."
    if lesson_ids:
        obj_ids = [ObjectId(lid) for lid in lesson_ids if lid]
        cursor_lessons = db.lessons.find({"_id": {"$in": obj_ids}})
        lessons_info = await cursor_lessons.to_list(length=100)
        learned_titles = [l.get("title", "") for l in lessons_info]
        if learned_titles:
            history_text = "Học viên vừa hoàn thành: " + ", ".join(learned_titles)

    prompt = f"""Bạn là Mentor AI "Owl" của ứng dụng Kỹ Năng Sống 4.0.
Lịch sử: {history_text}
Đề xuất 1 kỹ năng tiếp theo theo mô hình Explainable AI.
Format chính xác:
🎯 **Đề Xuất**: [Tên Kỹ năng]
💡 **Lý do**: [Giải thích 1 dòng dựa trên dữ liệu]"""

    try:
        text = await _generate_with_fallback(prompt)
        return {"recommendation_text": text.strip()}
    except Exception as e:
        import traceback; traceback.print_exc()
        err = str(e)
        if any(c in err for c in ["503", "UNAVAILABLE", "quota", "429"]):
            raise HTTPException(status_code=503, detail="AI đang bận, vui lòng thử lại sau vài giây.")
        raise HTTPException(status_code=500, detail="Lỗi kết nối AI. Vui lòng thử lại.")
