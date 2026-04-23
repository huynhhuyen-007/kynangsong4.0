from __future__ import annotations
from pydantic import BaseModel


class ExamSubmit(BaseModel):
    user_id: str
    round_id: int
    answers: list[dict]  # [{"question_id": "...", "selected": 0}, ...]


class QuestionCreate(BaseModel):
    admin_id: str
    round_id: int
    content: str
    options: list[str]       # 4 đáp án
    correct_answer: int      # index 0-3
    skill_tag: str           # "communication" | "emotion" | "finance" | ...
    explanation: str = ""
