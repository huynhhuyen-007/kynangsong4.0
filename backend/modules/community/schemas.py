from pydantic import BaseModel, Field


class PostCreate(BaseModel):
    user_id: str
    user_name: str
    content: str = Field(..., min_length=1, max_length=2000)
    topic: str = "Chung"


class CommentCreate(BaseModel):
    user_id: str
    user_name: str
    content: str = Field(..., min_length=1, max_length=500)


class LikeRequest(BaseModel):
    user_id: str


class ReportRequest(BaseModel):
    user_id: str
