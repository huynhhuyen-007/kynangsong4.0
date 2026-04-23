from fastapi import APIRouter
from .schemas import ExamSubmit, QuestionCreate
from . import service

router = APIRouter(tags=["Exam"])


@router.get("/api/exam/questions/{round_id}")
async def get_exam_questions(round_id: int):
    return await service.get_questions_by_round(round_id)


@router.post("/api/exam/submit")
async def submit_exam(body: ExamSubmit):
    return await service.submit_exam(body)


@router.get("/api/exam/progress/{user_id}")
async def get_exam_progress(user_id: str):
    return await service.get_exam_progress(user_id)
