from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from bson import ObjectId
import main

router = APIRouter()

@router.get("/api/skills")
async def get_skills():
    col = main.mongo_client[main.DB_NAME]["skills"]
    cursor = col.find().sort("created_at", -1)
    skills = await cursor.to_list(length=100)
    return [
        {
            "id": str(s["_id"]),
            "title": s.get("title", ""),
            "category": s.get("category", ""),
            "description": s.get("description", ""),
            "image_url": s.get("image_url", ""),
            "content": s.get("content", ""),
            "duration_minutes": s.get("duration_minutes", 5)
        } for s in skills
    ]

@router.get("/api/health")
async def health():
    try:
        await main.mongo_client.admin.command("ping")
        return {"status": "ok", "database": "MongoDB connected"}
    except Exception as e:
        return {"status": "error", "database": str(e)}

@router.get("/api/skills/{skill_id}/lessons")
async def get_lessons(skill_id: str):
    col = main.mongo_client[main.DB_NAME]["lessons"]
    cursor = col.find({"skill_id": skill_id}).sort("order", 1)
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

@router.post("/api/learning/progress")
async def update_learning_progress(body: main.ProgressUpdate):
    col = main.mongo_client[main.DB_NAME]["learning_progress"]
    
    doc = {
        "progress": body.progress,
        "status": body.status,
        "score": body.score,
        "time_spent": body.time_spent,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    if body.status == "completed":
        doc["completed_at"] = datetime.now(timezone.utc).isoformat()
        
    await col.update_one(
        {"user_id": body.user_id, "lesson_id": body.lesson_id},
        {"$set": doc},
        upsert=True
    )
    return {"status": "success", "progress": body.progress}

@router.get("/api/learning/quiz/{lesson_id}")
async def get_lesson_quiz(lesson_id: str):
    col = main.mongo_client[main.DB_NAME]["lesson_quizzes"]
    cursor = col.find({"lesson_id": lesson_id})
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

@router.post("/api/learning/quiz_submit")
async def submit_lesson_quiz(body: main.QuizSubmit):
    q_col = main.mongo_client[main.DB_NAME]["lesson_quizzes"]
    
    correct_count = 0
    results = []
    
    for ans in body.answers:
        try:
            q = await q_col.find_one({"_id": ObjectId(ans["question_id"])})
        except:
            continue
        if not q: continue
        
        is_correct = (ans.get("selected") == q.get("correct_answer"))
        if is_correct:
            correct_count += 1
            
        results.append({
            "question_id": ans["question_id"],
            "selected": ans.get("selected"),
            "correct_answer": q.get("correct_answer"),
            "is_correct": is_correct,
            "explanation": q.get("explanation", "")
        })
        
    points_earned = correct_count * 10
    total_q = len(body.answers)
    
    res_col = main.mongo_client[main.DB_NAME]["quiz_results"]
    await res_col.insert_one({
        "user_id": body.user_id,
        "lesson_id": body.lesson_id,
        "score": correct_count,
        "total": total_q,
        "points_earned": points_earned,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    
    return {
        "status": "success",
        "correct_count": correct_count,
        "total": total_q,
        "points_earned": points_earned,
        "results": results
    }
