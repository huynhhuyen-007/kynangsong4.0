from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    query: str
    user_id: str


class ContextChatRequest(BaseModel):
    query: str
    user_id: str
    include_progress: bool = True
    # Conversation memory — gửi từ Flutter
    history: list[dict] = []        # [{"role": "user|assistant", "content": "..."}]
    session_summary: str = ""       # Tóm tắt đầu session để tránh token overflow
    # Context awareness — Flutter gửi kèm để intent detection chính xác hơn
    conversation_state: dict = {}   # {"topic": "...", "last_intent": 1, "turn_count": 0}


class RecommendRequest(BaseModel):
    user_id: str
    round_id: int
    correct_count: int
    total_questions: int
    skill_stats: dict
    passed: bool
