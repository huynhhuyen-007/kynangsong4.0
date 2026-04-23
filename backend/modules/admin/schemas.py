from pydantic import BaseModel
from typing import Optional


class RoleUpdate(BaseModel):
    admin_id: str
    target_email: str
    new_role: str


class FunUpsert(BaseModel):
    admin_id: str
    title: str
    type: str = "tip"
    media_url: str = ""
    content: str
