from __future__ import annotations
from pydantic import BaseModel
from typing import Optional


class ProgressUpdate(BaseModel):
    user_id: str
    lesson_id: str
    progress: float   # 10.0 = 10%, 100.0 = 100%
    status: str       # "in_progress" | "completed"
    score: Optional[int] = 0
    time_spent: Optional[int] = 0


class QuizSubmit(BaseModel):
    user_id: str
    lesson_id: str
    answers: list[dict]
