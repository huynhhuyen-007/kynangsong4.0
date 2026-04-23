from fastapi import APIRouter
from .schemas import ProgressUpdate, QuizSubmit
from . import service

router = APIRouter(tags=["Lessons"])


@router.get("/api/health")
async def health():
    return await service.health_check()


@router.get("/api/skills/{skill_id}/lessons")
async def get_lessons(skill_id: str):
    return await service.get_lessons_by_skill(skill_id)


@router.post("/api/learning/progress")
async def update_learning_progress(body: ProgressUpdate):
    return await service.update_learning_progress(body)


@router.get("/api/learning/quiz/{lesson_id}")
async def get_lesson_quiz(lesson_id: str):
    return await service.get_lesson_quiz(lesson_id)


@router.post("/api/learning/quiz_submit")
async def submit_lesson_quiz(body: QuizSubmit):
    return await service.submit_lesson_quiz(body)
