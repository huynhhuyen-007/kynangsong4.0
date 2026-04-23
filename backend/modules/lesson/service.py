from __future__ import annotations

from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from core.database import get_db
from .schemas import ProgressUpdate, QuizSubmit


async def get_lessons_by_skill(skill_id: str) -> list:
    db = get_db()
    cursor = db.lessons.find({"skill_id": skill_id}).sort("order", 1)
    lessons = await cursor.to_list(length=100)
    return [
        {
            "id": str(ls["_id"]),
            "skill_id": ls.get("skill_id"),
            "title": ls.get("title", ""),
            "type": ls.get("type", "mp4"),
            "content_url": ls.get("content_url", ""),
            "duration": ls.get("duration", 5),
            "order": ls.get("order", 1),
        }
        for ls in lessons
    ]


async def update_learning_progress(body: ProgressUpdate) -> dict:
    db = get_db()
    doc = {
        "progress": body.progress,
        "status": body.status,
        "score": body.score,
        "time_spent": body.time_spent,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    if body.status == "completed":
        doc["completed_at"] = datetime.now(timezone.utc).isoformat()

    await db.learning_progress.update_one(
        {"user_id": body.user_id, "lesson_id": body.lesson_id},
        {"$set": doc},
        upsert=True,
    )
    return {"status": "success", "progress": body.progress}


async def get_lesson_quiz(lesson_id: str) -> list:
    db = get_db()
    cursor = db.lesson_quizzes.find({"lesson_id": lesson_id})
    questions = await cursor.to_list(length=50)
    return [
        {
            "id": str(q["_id"]),
            "content": q.get("content", ""),
            "options": q.get("options", []),
            "explanation": q.get("explanation", ""),
        }
        for q in questions
    ]


async def submit_lesson_quiz(body: QuizSubmit) -> dict:
    db = get_db()
    correct_count = 0
    results = []

    for ans in body.answers:
        try:
            q = await db.lesson_quizzes.find_one({"_id": ObjectId(ans["question_id"])})
        except Exception:
            continue
        if not q:
            continue
        is_correct = ans.get("selected") == q.get("correct_answer")
        if is_correct:
            correct_count += 1
        results.append({
            "question_id": ans["question_id"],
            "selected": ans.get("selected"),
            "correct_answer": q.get("correct_answer"),
            "is_correct": is_correct,
            "explanation": q.get("explanation", ""),
        })

    points_earned = correct_count * 10
    await db.quiz_results.insert_one({
        "user_id": body.user_id,
        "lesson_id": body.lesson_id,
        "score": correct_count,
        "total": len(body.answers),
        "points_earned": points_earned,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })

    return {
        "status": "success",
        "correct_count": correct_count,
        "total": len(body.answers),
        "points_earned": points_earned,
        "results": results,
    }


async def health_check() -> dict:
    from core.database import _client
    try:
        await _client.admin.command("ping")
        return {"status": "ok", "database": "MongoDB connected"}
    except Exception as e:
        return {"status": "error", "database": str(e)}
