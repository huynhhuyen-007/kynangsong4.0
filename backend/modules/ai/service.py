from datetime import datetime, timezone

from fastapi import HTTPException

from core.config import settings
from core.database import get_db

from google import genai

_client = genai.Client(api_key=settings.GEMINI_API_KEY)
_MODEL = "gemini-2.5-flash-preview-04-17"

# Mapping skill_tag → tiếng Việt
_SKILL_TAG_VI = {
    "communication":     "Kỹ năng Giao Tiếp",
    "emotion":           "Quản lý Cảm Xúc",
    "finance":           "Quản lý Tài Chính",
    "critical_thinking": "Tư Duy Phản Biện & Quản Lý Thời Gian",
    "teamwork":          "Làm Việc Nhóm",
    "health":            "Sức Khỏe & Thể Chất",
}

from .schemas import ChatRequest, ContextChatRequest, RecommendRequest


async def _find_related_skills(query_lower: str) -> list:
    """Tìm kỹ năng liên quan dựa trên từ khóa trong câu hỏi."""
    db = get_db()
    search_keywords = []
    if any(w in query_lower for w in ["cháy", "lửa", "hỏa hoạn"]):
        search_keywords.extend(["cháy", "hỏa hoạn", "sơ cứu"])
    elif any(w in query_lower for w in ["máu", "cấp cứu", "thương", "ngất", "sơ cứu"]):
        search_keywords.extend(["sơ cứu", "máu"])
    elif any(w in query_lower for w in ["tiền", "tài chính", "ngân hàng", "lừa đảo", "tiết kiệm"]):
        search_keywords.extend(["tài chính", "ngân hàng"])
    elif any(w in query_lower for w in ["giao tiếp", "thuyết trình", "căng thẳng", "stress", "tự tin"]):
        search_keywords.extend(["giao tiếp", "thuyết trình"])
    else:
        search_keywords.extend(query_lower.split()[:3])

    if not search_keywords:
        return []

    regex_pattern = "|".join([k for k in search_keywords if len(k) > 2])
    if not regex_pattern:
        return []

    cursor = db.skills.find({
        "$or": [
            {"title": {"$regex": regex_pattern, "$options": "i"}},
            {"description": {"$regex": regex_pattern, "$options": "i"}},
        ]
    }).limit(2)
    skills = await cursor.to_list(length=2)
    return [
        {"id": str(s["_id"]), "title": s.get("title"),
         "image_url": s.get("image_url"), "category": s.get("category")}
        for s in skills
    ]


async def ai_chat(body: ChatRequest) -> dict:
    prompt = f"""Bạn là AI Life Skill Copilot - Trợ lý kỹ năng sống thông minh dành cho sinh viên Việt Nam.
Yêu cầu:
- NẾU câu hỏi KHÔNG LIÊN QUAN đến kỹ năng sống, học tập, môi trường làm việc hay tâm lý, BẮT BUỘC trả lời đúng 1 câu: "Tôi chỉ hỗ trợ các nội dung học tập có trong ứng dụng." Không giải thích thêm.
- Nếu liên quan, trả lời ngắn gọn, rõ ràng, thực tiễn.
- Format Markdown chính xác:
✅ **Tình huống:** [Phân tích ngắn 1 dòng]
⚠️ **Điều cần tránh:** [Lưu ý những sai lầm]
📌 **Các bước xử lý:**
- [Bước 1]
- ...
💡 **Lời khuyên thêm:** [Tip hay]

Câu hỏi: {body.query}"""

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL, contents=prompt
        )
        related_skills = await _find_related_skills(body.query.lower())
        return {"answer": response.text, "related_skills": related_skills}
    except Exception as e:
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


async def ai_context_chat(body: ContextChatRequest) -> dict:
    from modules.exam.service import _get_or_create_progress
    context_block = ""

    if body.include_progress:
        try:
            progress = await _get_or_create_progress(body.user_id)
            skill_stats = progress.get("skill_stats", {})
            current_round = progress.get("current_round", 1)
            total_points = progress.get("total_exam_points", 0)
            active_skills = {k: v for k, v in skill_stats.items() if v > 0}
            weakest_name = _SKILL_TAG_VI.get(min(active_skills, key=lambda k: active_skills[k]), "chưa xác định") if active_skills else "chưa xác định"
            skill_desc = ", ".join([f"{_SKILL_TAG_VI.get(k, k)}: {int(v)}đ" for k, v in skill_stats.items() if v > 0]) or "chưa có dữ liệu thi"
            context_block = f"\n[THÔNG TIN HỌC VIÊN]: Vòng {current_round}/16, {total_points} XP, Kỹ năng yếu: {weakest_name}, Bảng điểm: {skill_desc}\n"
        except Exception:
            pass

    prompt = f"""Bạn là AI Life Skill Copilot "Owl" - Trợ lý kỹ năng sống thông minh dành cho sinh viên Việt Nam.
{context_block}
- NẾU không liên quan kỹ năng sống: chỉ trả lời "Tôi chỉ hỗ trợ các nội dung học tập có trong ứng dụng."
- Format Markdown: ✅ **Tình huống:** | ⚠️ **Điều cần tránh:** | 📌 **Các bước xử lý:** | 💡 **Lời khuyên thêm:**
Câu hỏi: {body.query}"""

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL, contents=prompt
        )
        related_skills = await _find_related_skills(body.query.lower())
        return {"answer": response.text, "related_skills": related_skills}
    except Exception as e:
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


async def ai_recommend_path(body: RecommendRequest) -> dict:
    skill_lines, weak_skills, strong_skills = [], [], []
    for tag, score in body.skill_stats.items():
        vi_name = _SKILL_TAG_VI.get(tag, tag)
        score_int = int(score)
        if score_int > 0:
            skill_lines.append(f"  - {vi_name}: {score_int} điểm")
            (strong_skills if score_int >= 20 else weak_skills if score_int < 10 else []).append(vi_name)

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
        response = await _client.aio.models.generate_content(
            model=_MODEL, contents=prompt
        )
        advice = response.text.strip()
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
        raise HTTPException(status_code=500, detail=str(e))


async def get_ai_recommendation(user_id: str) -> dict:
    db = get_db()
    from bson import ObjectId
    prog_col = db.learning_progress
    cursor = prog_col.find({"user_id": user_id, "status": "completed"})
    completed_lessons = await cursor.to_list(length=100)
    lesson_ids = [ls["lesson_id"] for ls in completed_lessons]
    history_text = "Học viên này là người mới, chưa hoàn thành kỹ năng nào."
    if lesson_ids:
        obj_ids = []
        for lid in lesson_ids:
            try: obj_ids.append(ObjectId(lid))
            except: pass
        cursor_lessons = db.lessons.find({"_id": {"$in": obj_ids}})
        lessons_info = await cursor_lessons.to_list(length=100)
        learned_titles = [l.get("title", "") for l in lessons_info]
        history_text = ("Học viên vừa hoàn thành: " + ", ".join(learned_titles)) if learned_titles else history_text

    prompt = f"""Bạn là Mentor AI "Owl" của ứng dụng Kỹ Năng Sống 4.0.
Lịch sử: {history_text}
Đề xuất 1 kỹ năng tiếp theo theo mô hình Explainable AI.
Format chính xác:
🎯 **Đề Xuất**: [Tên Kỹ năng]
💡 **Lý do**: [Giải thích 1 dòng dựa trên dữ liệu]"""

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL, contents=prompt
        )
        return {"recommendation_text": response.text.strip()}
    except Exception as e:
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
