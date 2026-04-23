from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from core.database import get_db
from core.helpers import serialize_doc, serialize_list
from .schemas import SkillUpsert


async def get_all_skills(category: str = None) -> list:
    db = get_db()
    query = {"category": category} if category else {}
    cursor = db.skills.find(query).sort("created_at", -1)
    skills = await cursor.to_list(length=500)
    return serialize_list(skills)


async def get_skill_by_id(skill_id: str) -> dict:
    db = get_db()
    try:
        skill = await db.skills.find_one({"_id": ObjectId(skill_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="skill_id không hợp lệ.")
    if not skill:
        raise HTTPException(status_code=404, detail="Không tìm thấy kỹ năng.")
    return serialize_doc(skill)


async def create_skill(body: SkillUpsert) -> dict:
    db = get_db()
    doc = {
        "title": body.title,
        "category": body.category,
        "description": body.description,
        "image_url": body.image_url,
        "content": body.content,
        "duration_minutes": body.duration_minutes,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await db.skills.insert_one(doc)
    doc.pop("_id", None)
    return {"id": str(result.inserted_id), **doc}


async def update_skill(skill_id: str, body: SkillUpsert) -> dict:
    db = get_db()
    result = await db.skills.update_one(
        {"_id": ObjectId(skill_id)},
        {"$set": {
            "title": body.title,
            "category": body.category,
            "description": body.description,
            "image_url": body.image_url,
            "content": body.content,
            "duration_minutes": body.duration_minutes,
        }}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy kỹ năng.")
    return {"status": "updated"}


async def delete_skill(skill_id: str) -> dict:
    db = get_db()
    await db.skills.delete_one({"_id": ObjectId(skill_id)})
    return {"status": "deleted"}


async def get_skill_categories() -> list:
    db = get_db()
    categories = await db.skills.distinct("category")
    result = []
    for cat in sorted(categories):
        count = await db.skills.count_documents({"category": cat})
        result.append({"name": cat, "count": count})
    return result
