from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from core.database import get_db
from core.helpers import serialize_doc, serialize_list
from .schemas import NewsUpsert


async def get_all_news() -> list:
    db = get_db()
    cursor = db.news.find().sort("created_at", -1)
    news_list = await cursor.to_list(length=200)
    return serialize_list(news_list)


async def get_news_by_id(news_id: str) -> dict:
    db = get_db()
    try:
        item = await db.news.find_one({"_id": ObjectId(news_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="news_id không hợp lệ.")
    if not item:
        raise HTTPException(status_code=404, detail="Không tìm thấy tin tức.")
    return serialize_doc(item)


async def create_news(body: NewsUpsert) -> dict:
    db = get_db()
    doc = {
        "title": body.title,
        "summary": body.summary,
        "content": body.content,
        "image_url": body.image_url,
        "author": body.author,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await db.news.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}


async def update_news(news_id: str, body: NewsUpsert) -> dict:
    db = get_db()
    result = await db.news.update_one(
        {"_id": ObjectId(news_id)},
        {"$set": {
            "title": body.title,
            "summary": body.summary,
            "content": body.content,
            "image_url": body.image_url,
            "author": body.author,
        }}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy tin tức.")
    return {"status": "updated"}


async def delete_news(news_id: str) -> dict:
    db = get_db()
    await db.news.delete_one({"_id": ObjectId(news_id)})
    return {"status": "deleted"}
