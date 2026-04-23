from fastapi import APIRouter
from . import service

router = APIRouter(tags=["News"])


@router.get("/api/news")
async def get_news():
    return await service.get_all_news()


@router.get("/api/news/{news_id}")
async def get_news_detail(news_id: str):
    return await service.get_news_by_id(news_id)
