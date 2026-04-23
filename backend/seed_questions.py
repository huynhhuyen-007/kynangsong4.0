"""
seed_questions.py - Seed cau hoi mau cho he thong San Choi (Phase 2)
Chay: python seed_questions.py

Cau hinh MongoDB lay tu file .env (thong qua core/config.py).
Khong hardcode credential trong file nay.
"""
import asyncio
import sys
import certifi
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime, timezone

# Lay MONGO_URL va DB_NAME tu .env thong qua core/config.py
from core.config import settings

# Fix encoding tren Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

QUESTIONS = [
    # ── Vòng 1: Kỹ năng giao tiếp ──────────────────────────────────────────
    {
        "round_id": 1,
        "content": "Khi đang trình bày ý kiến trong cuộc họp nhóm và bị ngắt lời, bạn nên làm gì?",
        "options": [
            "A. Im lặng và bỏ qua ý kiến của mình",
            "B. Tiếp tục nói to hơn để lấn át",
            "C. Nói lịch sự: 'Cho mình nói hết ý này nhé' rồi tiếp tục",
            "D. Tức giận và rời khỏi cuộc họp",
        ],
        "correct_answer": 2,
        "skill_tag": "communication",
        "explanation": "Nói lịch sự nhưng quyết đoán giúp bạn bảo vệ ý kiến mà không tạo xung đột."
    },
    {
        "round_id": 1,
        "content": "Kỹ thuật lắng nghe chủ động (Active Listening) bao gồm điều nào sau đây?",
        "options": [
            "A. Nghĩ về câu trả lời trong khi người kia đang nói",
            "B. Gật đầu, duy trì ánh mắt và phản chiếu lại ý người nói",
            "C. Nhìn điện thoại để tỏ ra bận rộn",
            "D. Ngắt lời để kể câu chuyện tương tự của mình",
        ],
        "correct_answer": 1,
        "skill_tag": "communication",
        "explanation": "Lắng nghe chủ động giúp người nói cảm thấy được tôn trọng và bạn hiểu đúng vấn đề hơn."
    },
    {
        "round_id": 1,
        "content": "Khi gửi email chuyên nghiệp, điều nào sau đây là KHÔNG nên làm?",
        "options": [
            "A. Viết tiêu đề email rõ ràng, súc tích",
            "B. Dùng chữ viết hoa toàn bộ để nhấn mạnh",
            "C. Kiểm tra lỗi chính tả trước khi gửi",
            "D. Kết thúc bằng lời chào và tên đầy đủ",
        ],
        "correct_answer": 1,
        "skill_tag": "communication",
        "explanation": "Viết hoa toàn bộ trong email được hiểu là đang hét to, rất thiếu chuyên nghiệp."
    },
    {
        "round_id": 1,
        "content": "Ngôn ngữ cơ thể (body language) chiếm bao nhiêu % trong giao tiếp?",
        "options": [
            "A. Khoảng 7%",
            "B. Khoảng 38%",
            "C. Khoảng 55%",
            "D. Khoảng 80%",
        ],
        "correct_answer": 2,
        "skill_tag": "communication",
        "explanation": "Theo nghiên cứu Mehrabian: 55% ngôn ngữ cơ thể, 38% giọng điệu, chỉ 7% lời nói."
    },
    {
        "round_id": 1,
        "content": "Kỹ năng phản hồi hiệu quả (STAR Feedback) gồm: Tình huống, Hành động, Kết quả, và...?",
        "options": [
            "A. Tác hại",
            "B. Giải pháp thay thế",
            "C. Thời gian",
            "D. Người gây ra",
        ],
        "correct_answer": 1,
        "skill_tag": "communication",
        "explanation": "STAR = Situation, Task/Action, Alternative (giải pháp thay thế), Result."
    },

    # ── Vòng 2: Lắng nghe hiệu quả / Quản lý cảm xúc ──────────────────────
    {
        "round_id": 2,
        "content": "Khi cảm thấy rất tức giận trong tranh luận, bước đầu tiên nên làm là?",
        "options": [
            "A. Nói thẳng ngay những gì đang nghĩ",
            "B. Hít thở sâu và đếm đến 10 trước khi phản hồi",
            "C. Rời đi mà không giải thích",
            "D. Phán xét ngay đối phương là sai",
        ],
        "correct_answer": 1,
        "skill_tag": "emotion",
        "explanation": "Kỹ thuật 'hít thở sâu + đếm đến 10' giúp hệ thần kinh bình tĩnh lại trước khi phản ứng."
    },
    {
        "round_id": 2,
        "content": "Trí tuệ cảm xúc (EQ) cao giúp ích gì trong công việc?",
        "options": [
            "A. Tăng khả năng ghi nhớ thông tin kỹ thuật",
            "B. Cải thiện quan hệ đồng nghiệp và xử lý xung đột tốt hơn",
            "C. Giúp tính toán số liệu nhanh hơn",
            "D. Tăng tốc độ gõ phím",
        ],
        "correct_answer": 1,
        "skill_tag": "emotion",
        "explanation": "EQ cao giúp bạn nhận diện cảm xúc người khác, xây dựng quan hệ tốt và giải quyết xung đột hiệu quả."
    },
    {
        "round_id": 2,
        "content": "Kỹ thuật 'đặt tên cho cảm xúc' (Name it to Tame it) có tác dụng gì?",
        "options": [
            "A. Làm tăng cảm xúc tiêu cực",
            "B. Giúp não bộ kiểm soát cảm xúc dễ dàng hơn",
            "C. Giúp người khác hiểu lầm bạn",
            "D. Không có tác dụng khoa học nào",
        ],
        "correct_answer": 1,
        "skill_tag": "emotion",
        "explanation": "Nghiên cứu thần kinh học: đặt tên cảm xúc giúp vỏ não trước trán kiểm soát hạch hạnh nhân."
    },
    {
        "round_id": 2,
        "content": "Khi một người bạn chia sẻ vấn đề cá nhân với bạn, họ muốn gì nhất?",
        "options": [
            "A. Nghe lời khuyên giải quyết ngay lập tức",
            "B. Được bạn đồng cảm và lắng nghe trước",
            "C. Bị so sánh với người khác tệ hơn",
            "D. Nghe bạn kể chuyện của chính mình",
        ],
        "correct_answer": 1,
        "skill_tag": "emotion",
        "explanation": "Hầu hết mọi người muốn được lắng nghe và thấu hiểu trước. Lời khuyên chỉ nên đến khi được hỏi."
    },
    {
        "round_id": 2,
        "content": "Self-compassion (lòng tự trắc ẩn) trong tâm lý học có nghĩa là gì?",
        "options": [
            "A. Luôn khen ngợi bản thân dù sai",
            "B. Đối xử với bản thân như đối xử với người bạn tốt khi thất bại",
            "C. Tự ti và tự trách mình",
            "D. Phớt lờ cảm xúc tiêu cực",
        ],
        "correct_answer": 1,
        "skill_tag": "emotion",
        "explanation": "Self-compassion của Kristin Neff: nhận ra lỗi, không tự trừng phạt, đối xử tử tế với bản thân."
    },

    # ── Vòng 3: Quản lý thời gian / Tư duy phản biện ───────────────────────
    {
        "round_id": 3,
        "content": "Ma trận Eisenhower phân loại công việc theo 2 trục chính là?",
        "options": [
            "A. Dễ - Khó và Ngắn - Dài",
            "B. Khẩn cấp - Không khẩn cấp và Quan trọng - Không quan trọng",
            "C. Cá nhân - Nhóm và Ngắn hạn - Dài hạn",
            "D. Chi phí cao - Chi phí thấp và Rủi ro cao - Rủi ro thấp",
        ],
        "correct_answer": 1,
        "skill_tag": "critical_thinking",
        "explanation": "Eisenhower Matrix chia 4 ô: Q1 (khẩn+quan trọng), Q2 (quan trọng), Q3 (khẩn), Q4 (loại bỏ)."
    },
    {
        "round_id": 3,
        "content": "Kỹ thuật Pomodoro giúp tập trung bằng cách nào?",
        "options": [
            "A. Làm việc liên tục 4 tiếng không nghỉ",
            "B. Làm 25 phút, nghỉ 5 phút, lặp lại theo chu kỳ",
            "C. Chỉ làm việc vào buổi sáng sớm",
            "D. Chia bài việc cho nhiều người",
        ],
        "correct_answer": 1,
        "skill_tag": "critical_thinking",
        "explanation": "Pomodoro (Francesco Cirillo): làm 25 phút focus, nghỉ 5 phút, sau 4 vòng nghỉ dài 15-30 phút."
    },
    {
        "round_id": 3,
        "content": "Nguyên tắc Pareto (80/20) trong quản lý thời gian có nghĩa là?",
        "options": [
            "A. Dành 80% thời gian cho email",
            "B. 20% công việc tạo ra 80% kết quả, hãy ưu tiên 20% đó",
            "C. Nghỉ ngơi 80% thời gian, làm 20%",
            "D. Họp nhóm chiếm 80% hiệu quả",
        ],
        "correct_answer": 1,
        "skill_tag": "critical_thinking",
        "explanation": "Tập trung vào 20% tác vụ có giá trị cao nhất → đạt 80% kết quả. Ưu tiên đúng chỗ."
    },
    {
        "round_id": 3,
        "content": "Khi một thông tin viral trên mạng xã hội, bước đầu tư duy phản biện là?",
        "options": [
            "A. Chia sẻ ngay vì nhiều người đồng ý",
            "B. Kiểm tra nguồn gốc và đối chiếu nhiều nguồn uy tín",
            "C. Tin tưởng vì có ảnh minh họa",
            "D. Hỏi ý kiến bạn bè rồi tin theo số đông",
        ],
        "correct_answer": 1,
        "skill_tag": "critical_thinking",
        "explanation": "Fact-checking: luôn xác minh nguồn trước khi tin và chia sẻ thông tin."
    },
    {
        "round_id": 3,
        "content": "SMART Goal nghĩa là mục tiêu phải có những yếu tố nào?",
        "options": [
            "A. Specific, Measurable, Achievable, Relevant, Time-bound",
            "B. Simple, Modern, Accurate, Realistic, Timely",
            "C. Smart, Mindful, Agile, Reasonable, Total",
            "D. Strategic, Manageable, Actionable, Reliable, Trackable",
        ],
        "correct_answer": 0,
        "skill_tag": "critical_thinking",
        "explanation": "SMART = Cụ thể, Đo được, Khả thi, Liên quan, Có thời hạn — tiêu chuẩn vàng đặt mục tiêu."
    },
]


async def main():
    print("[*] Dang ket noi MongoDB...")
    client = AsyncIOMotorClient(settings.MONGO_URL, tls=True, tlsCAFile=certifi.where())
    db = client[settings.DB_NAME]
    col = db["questions"]

    # Xoa cau hoi cu (neu co) de seed lai sach
    deleted = await col.delete_many({})
    print(f"[-] Da xoa {deleted.deleted_count} cau hoi cu.")

    # Insert moi
    now = datetime.now(timezone.utc).isoformat()
    docs = [{**q, "created_at": now} for q in QUESTIONS]
    result = await col.insert_many(docs)
    print(f"[+] Da seed {len(result.inserted_ids)} cau hoi thanh cong!")
    print("    Vong 1: 5 cau | Vong 2: 5 cau | Vong 3: 5 cau")

    client.close()


if __name__ == "__main__":
    asyncio.run(main())
