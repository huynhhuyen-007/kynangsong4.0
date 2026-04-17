from fastapi import APIRouter
import main
import random

router = APIRouter()

@router.get("/api/news")
async def get_news(sort: str = "new"):
    col = main.mongo_client[main.DB_NAME]["news"]
    sort_field = "created_at"
    cursor = col.find().sort(sort_field, -1)
    news_items = await cursor.to_list(length=100)
    result = [
        {
            "id": str(n["_id"]),
            "title": n.get("title", ""),
            "summary": n.get("summary", ""),
            "content": n.get("content", ""),
            "image_url": n.get("image_url", ""),
            "created_at": n.get("created_at", ""),
            "author": n.get("author", "Admin")
        } for n in news_items
    ]
    if sort == "hot":
        random.shuffle(result)
    return result
