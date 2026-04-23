from fastapi import APIRouter
from .schemas import ChatRequest, ContextChatRequest, RecommendRequest
from . import service

router = APIRouter(tags=["AI"])


@router.post("/api/ai/chat")
async def ai_chat(body: ChatRequest):
    return await service.ai_chat(body)


@router.post("/api/ai/context-chat")
async def ai_context_chat(body: ContextChatRequest):
    return await service.ai_context_chat(body)


@router.post("/api/ai/recommend-path")
async def ai_recommend_path(body: RecommendRequest):
    return await service.ai_recommend_path(body)


@router.get("/api/ai/recommendation/{user_id}")
async def get_ai_recommendation(user_id: str):
    return await service.get_ai_recommendation(user_id)
