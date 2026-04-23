from typing import Optional
from fastapi import APIRouter
from .schemas import SkillUpsert
from . import service

router = APIRouter(tags=["Skills"])


@router.get("/api/skills")
async def get_skills(category: Optional[str] = None):
    return await service.get_all_skills(category)


@router.get("/api/skills/{skill_id}")
async def get_skill(skill_id: str):
    return await service.get_skill_by_id(skill_id)
