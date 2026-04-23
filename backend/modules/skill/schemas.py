from pydantic import BaseModel, Field
from typing import Optional


class SkillUpsert(BaseModel):
    admin_id: str
    title: str
    category: str = "Kỹ năng chung"
    description: str
    image_url: str = ""
    content: str
    duration_minutes: int = 5
