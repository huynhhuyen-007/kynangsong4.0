# 🔍 QUICK SEARCH MAP — Backend API

> **Cách dùng:** `Ctrl+F` tên function để tìm đúng file ngay lập tức.  
> Không cần nhớ tên file, chỉ cần nhớ tên action.

---

## 🏗️ Core

| Thành phần | File | Ghi chú |
|---|---|---|
| Settings / Config | `core/config.py` | Đọc từ `.env` |
| MongoDB connection | `core/database.py` | `get_db()`, `lifespan` |
| Mã hóa mật khẩu | `core/security.py` | `hash_password()`, `verify_password()` |
| Serialize ObjectId | `core/helpers.py` | `serialize_doc()`, `serialize_list()` |

---

## 🔑 Auth — `modules/auth/`

| Action | File | Function |
|---|---|---|
| Đăng ký | `service.py` | `register_user()` |
| Đăng nhập | `service.py` | `login_user()` |
| Upload avatar | `service.py` | `upload_avatar()` |
| Endpoints | `router.py` | `POST /api/auth/register`, `POST /api/auth/login` |

---

## 🎯 Skill — `modules/skill/`

| Action | File | Function |
|---|---|---|
| Lấy danh sách | `service.py` | `get_all_skills()` |
| Chi tiết kỹ năng | `service.py` | `get_skill_by_id()` |
| Tạo kỹ năng | `service.py` | `create_skill()` |
| Cập nhật | `service.py` | `update_skill()` |
| Xóa | `service.py` | `delete_skill()` |
| Danh mục | `service.py` | `get_skill_categories()` |
| Endpoints | `router.py` | `GET /api/skills`, `GET /api/skills/{id}` |

---

## 📰 News — `modules/news/`

| Action | File | Function |
|---|---|---|
| Lấy danh sách | `service.py` | `get_all_news()` |
| Chi tiết tin tức | `service.py` | `get_news_by_id()` |
| Tạo | `service.py` | `create_news()` |
| Cập nhật | `service.py` | `update_news()` |
| Xóa | `service.py` | `delete_news()` |
| Endpoints | `router.py` | `GET /api/news`, `GET /api/news/{id}` |

---

## 🧪 Exam — `modules/exam/`

| Action | File | Function |
|---|---|---|
| Lấy câu hỏi theo vòng | `service.py` | `get_questions_by_round()` |
| Nộp bài & chấm điểm | `service.py` | `submit_exam()` |
| Xem tiến độ user | `service.py` | `get_exam_progress()` |
| Tạo/lấy progress | `service.py` | `_get_or_create_progress()` |
| Tạo câu hỏi (admin) | `service.py` | `create_question()` |
| Liệt kê câu hỏi (admin) | `service.py` | `list_all_questions()` |
| Endpoints | `router.py` | `GET /api/exam/questions/{round_id}`, `POST /api/exam/submit` |

---

## 💬 Community — `modules/community/`

| Action | File | Function |
|---|---|---|
| Lấy bài đăng | `service.py` | `get_posts()` |
| Tạo bài | `service.py` | `create_post()` |
| Like / Unlike | `service.py` | `toggle_like()` |
| Report bài | `service.py` | `report_post()` |
| Xóa bài | `service.py` | `delete_post()` |
| Lấy bình luận | `service.py` | `get_comments()` |
| Thêm bình luận | `service.py` | `add_comment()` |
| Report bình luận | `service.py` | `report_comment()` |
| Endpoints | `router.py` | `GET /api/community/posts`, `POST /api/community/posts` |

---

## ⚙️ Admin — `modules/admin/`

| Action | File | Function |
|---|---|---|
| Kiểm tra quyền admin | `service.py` | `check_admin()` |
| Thống kê tổng quan | `service.py` | `get_stats()` |
| Danh sách users | `service.py` | `get_all_users()` |
| Xóa user | `service.py` | `delete_user()` |
| Đổi role | `service.py` | `set_role()` |
| Upload media | `service.py` | `upload_media()` |
| Kiểm duyệt bài đăng | `service.py` | `get_admin_posts()`, `toggle_hide_post()` |
| Kiểm duyệt bình luận | `service.py` | `get_all_comments()`, `delete_comment()` |
| Endpoints | `router.py` | `GET /api/admin/stats`, `GET /api/admin/users` |

---

## 📚 Lesson — `modules/lesson/`

| Action | File | Function |
|---|---|---|
| Lấy bài học theo skill | `service.py` | `get_lessons_by_skill()` |
| Cập nhật tiến độ học | `service.py` | `update_learning_progress()` |
| Lấy quiz bài học | `service.py` | `get_lesson_quiz()` |
| Nộp quiz bài học | `service.py` | `submit_lesson_quiz()` |
| Health check | `service.py` | `health_check()` |
| Endpoints | `router.py` | `GET /api/skills/{id}/lessons`, `POST /api/learning/progress` |

---

## 🤖 AI — `modules/ai/`

| Action | File | Function |
|---|---|---|
| Chat cơ bản | `service.py` | `ai_chat()` |
| Chat có context | `service.py` | `ai_context_chat()` |
| Gợi ý lộ trình | `service.py` | `ai_recommend_path()` |
| Gợi ý bài học | `service.py` | `get_ai_recommendation()` |
| Tìm skill liên quan | `service.py` | `_find_related_skills()` |
| Endpoints | `router.py` | `POST /api/ai/chat`, `POST /api/ai/context-chat` |

---

## 📁 Cấu trúc đầy đủ

```
backend/
├── main.py               ← App init + include routers (60 dòng)
├── core/
│   ├── config.py         ← Settings từ .env
│   ├── database.py       ← MongoDB lifespan + get_db()
│   ├── security.py       ← bcrypt hash/verify
│   └── helpers.py        ← serialize_doc(), serialize_list()
├── modules/
│   ├── auth/             ← /api/auth/*, /api/users/*
│   ├── skill/            ← /api/skills/*
│   ├── news/             ← /api/news/*
│   ├── exam/             ← /api/exam/*
│   ├── community/        ← /api/community/*
│   ├── admin/            ← /api/admin/*
│   ├── lesson/           ← /api/learning/*, /api/health
│   └── ai/               ← /api/ai/*
├── data/seeds/           ← youtube_info.json, users.json, get_transcript.py
├── docs/
│   └── dev_map.md        ← 👈 File này
├── .env                  ← Bảo mật: MONGO_URL, GEMINI_API_KEY
└── requirements.txt
```
