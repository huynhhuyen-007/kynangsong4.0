from __future__ import annotations

import random
from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from core.database import get_db
from .schemas import ExamSubmit, QuestionCreate


async def get_questions_by_round(round_id: int) -> list:
    db = get_db()
    cursor = db.questions.find({"round_id": round_id})
    questions = await cursor.to_list(length=100)

    if not questions:
        raise HTTPException(
            status_code=404,
            detail=f"Chưa có câu hỏi cho vòng {round_id}. Hãy seed data trước."
        )

    sampled = random.sample(questions, min(5, len(questions)))
    return [
        {
            "id": str(q["_id"]),
            "content": q.get("content", ""),
            "options": q.get("options", []),
            "skill_tag": q.get("skill_tag", ""),
            # KHÔNG trả về correct_answer để tránh gian lận
        }
        for q in sampled
    ]


async def _get_or_create_progress(user_id: str) -> dict:
    db = get_db()
    doc = await db.user_exam_progress.find_one({"user_id": user_id})
    if not doc:
        doc = {
            "user_id": user_id,
            "current_round": 1,
            "total_exam_points": 0,
            "skill_stats": {
                "communication": 0, "emotion": 0, "finance": 0,
                "critical_thinking": 0, "teamwork": 0, "health": 0,
            },
            "completed_rounds": [],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        result = await db.user_exam_progress.insert_one(doc)
        doc["_id"] = result.inserted_id
    return doc


async def submit_exam(body: ExamSubmit) -> dict:
    db = get_db()
    results = []
    correct_count = 0
    skill_delta: dict[str, int] = {}

    for ans in body.answers:
        try:
            q = await db.questions.find_one({"_id": ObjectId(ans["question_id"])})
        except Exception:
            continue
        if not q:
            continue

        is_correct = ans.get("selected") == q.get("correct_answer")
        skill_tag = q.get("skill_tag", "communication")

        if is_correct:
            correct_count += 1
            skill_delta[skill_tag] = skill_delta.get(skill_tag, 0) + 10
        else:
            skill_delta[skill_tag] = skill_delta.get(skill_tag, 0) - 5

        results.append({
            "question_id": ans["question_id"],
            "content": q.get("content", ""),
            "selected": ans.get("selected"),
            "correct_answer": q.get("correct_answer"),
            "is_correct": is_correct,
            "skill_tag": skill_tag,
            "explanation": q.get("explanation", ""),
        })

    total_questions = len(results)
    passed = correct_count >= max(1, total_questions * 0.6)
    points_earned = correct_count * 20

    progress = await _get_or_create_progress(body.user_id)
    current_round = progress.get("current_round", 1)
    completed_rounds = list(progress.get("completed_rounds", []))

    new_skill_stats = dict(progress.get("skill_stats", {}))
    for tag, delta in skill_delta.items():
        new_skill_stats[tag] = max(0, new_skill_stats.get(tag, 0) + delta)

    if passed and body.round_id not in completed_rounds:
        completed_rounds.append(body.round_id)
        new_round = max(current_round, body.round_id + 1)
    else:
        new_round = current_round

    await db.user_exam_progress.update_one(
        {"user_id": body.user_id},
        {
            "$set": {
                "current_round": new_round,
                "skill_stats": new_skill_stats,
                "completed_rounds": completed_rounds,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            },
            "$inc": {"total_exam_points": points_earned},
        },
        upsert=True,
    )

    return {
        "passed": passed,
        "correct_count": correct_count,
        "total_questions": total_questions,
        "points_earned": points_earned,
        "new_round": new_round,
        "skill_stats": new_skill_stats,
        "results": results,
    }


async def get_exam_progress(user_id: str) -> dict:
    progress = await _get_or_create_progress(user_id)
    return {
        "current_round": progress.get("current_round", 1),
        "total_exam_points": progress.get("total_exam_points", 0),
        "skill_stats": progress.get("skill_stats", {}),
        "completed_rounds": progress.get("completed_rounds", []),
    }


async def create_question(body: QuestionCreate) -> dict:
    db = get_db()
    doc = {
        "round_id": body.round_id,
        "content": body.content,
        "options": body.options,
        "correct_answer": body.correct_answer,
        "skill_tag": body.skill_tag,
        "explanation": body.explanation,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = await db.questions.insert_one(doc)
    return {"id": str(result.inserted_id), **doc}


async def list_all_questions() -> list:
    db = get_db()
    cursor = db.questions.sort("round_id", 1)
    questions = await cursor.to_list(length=1000)
    return [
        {
            "id": str(q["_id"]),
            "round_id": q.get("round_id"),
            "content": q.get("content", ""),
            "options": q.get("options", []),
            "correct_answer": q.get("correct_answer"),
            "skill_tag": q.get("skill_tag", ""),
            "explanation": q.get("explanation", ""),
        }
        for q in questions
    ]
