from fastapi import APIRouter, UploadFile, File
from modules.skill.schemas import SkillUpsert
from modules.news.schemas import NewsUpsert
from modules.exam.schemas import QuestionCreate
from .schemas import RoleUpdate, FunUpsert
from . import service

router = APIRouter(tags=["Admin"])

# ── Users ─────────────────────────────────────────────────────────────────────
@router.get("/api/admin/users")
async def get_all_users(admin_id: str):
    return await service.get_all_users(admin_id)


@router.delete("/api/admin/users/{user_id}")
async def delete_user(user_id: str, admin_id: str):
    return await service.delete_user(user_id, admin_id)


@router.post("/api/admin/set_role")
async def set_role(body: RoleUpdate):
    return await service.set_role(body)

# ── Stats ──────────────────────────────────────────────────────────────────────
@router.get("/api/admin/stats")
async def get_stats(admin_id: str):
    return await service.get_stats(admin_id)

# ── Upload ────────────────────────────────────────────────────────────────────
@router.post("/api/admin/upload/image")
async def upload_media(admin_id: str, file: UploadFile = File(...)):
    return await service.upload_media(admin_id, file)

# ── Skills CMS ────────────────────────────────────────────────────────────────
@router.get("/api/admin/skills/categories")
async def get_skill_categories(admin_id: str):
    return await service.get_skill_categories_admin(admin_id)


@router.post("/api/admin/skills")
async def create_skill(body: SkillUpsert):
    from modules.skill.service import create_skill
    await service.check_admin(body.admin_id)
    return await create_skill(body)


@router.put("/api/admin/skills/{skill_id}")
async def update_skill(skill_id: str, body: SkillUpsert):
    from modules.skill.service import update_skill
    await service.check_admin(body.admin_id)
    return await update_skill(skill_id, body)


@router.delete("/api/admin/skills/{skill_id}")
async def delete_skill(skill_id: str, admin_id: str):
    from modules.skill.service import delete_skill
    await service.check_admin(admin_id)
    return await delete_skill(skill_id)

# ── News CMS ──────────────────────────────────────────────────────────────────
@router.post("/api/admin/news")
async def create_news(body: NewsUpsert):
    from modules.news.service import create_news
    await service.check_admin(body.admin_id)
    return await create_news(body)


@router.put("/api/admin/news/{news_id}")
async def update_news(news_id: str, body: NewsUpsert):
    from modules.news.service import update_news
    await service.check_admin(body.admin_id)
    return await update_news(news_id, body)


@router.delete("/api/admin/news/{news_id}")
async def delete_news(news_id: str, admin_id: str):
    from modules.news.service import delete_news
    await service.check_admin(admin_id)
    return await delete_news(news_id)

# ── Fun CMS ───────────────────────────────────────────────────────────────────
@router.post("/api/admin/fun")
async def create_fun(body: FunUpsert):
    return await service.create_fun(body)


@router.put("/api/admin/fun/{fun_id}")
async def update_fun(fun_id: str, body: FunUpsert):
    return await service.update_fun(fun_id, body)


@router.delete("/api/admin/fun/{fun_id}")
async def delete_fun(fun_id: str, admin_id: str):
    return await service.delete_fun(fun_id, admin_id)

# ── Community Moderation ──────────────────────────────────────────────────────
@router.get("/api/admin/community/posts")
async def admin_get_posts(admin_id: str):
    return await service.get_admin_posts(admin_id)


@router.post("/api/admin/community/posts/{post_id}/toggle_hide")
async def toggle_hide_post(post_id: str, admin_id: str):
    return await service.toggle_hide_post(post_id, admin_id)


@router.get("/api/admin/community/comments")
async def admin_get_all_comments(admin_id: str):
    return await service.get_all_comments(admin_id)


@router.delete("/api/admin/community/comments/{comment_id}")
async def admin_delete_comment(comment_id: str, admin_id: str):
    return await service.delete_comment(comment_id, admin_id)

# ── Exam Admin ────────────────────────────────────────────────────────────────
@router.post("/api/admin/exam/questions")
async def create_question(body: QuestionCreate):
    from modules.exam.service import create_question as svc_create_question
    await service.check_admin(body.admin_id)
    return await svc_create_question(body)


@router.get("/api/admin/exam/questions")
async def list_all_questions(admin_id: str):
    from modules.exam.service import list_all_questions as svc_list_questions
    await service.check_admin(admin_id)
    return await svc_list_questions()
