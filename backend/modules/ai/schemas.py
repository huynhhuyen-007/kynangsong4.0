from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    query: str
    user_id: str


class ContextChatRequest(BaseModel):
    query: str
    user_id: str
    include_progress: bool = True


class RecommendRequest(BaseModel):
    user_id: str
    round_id: int
    correct_count: int
    total_questions: int
    skill_stats: dict
    passed: bool
