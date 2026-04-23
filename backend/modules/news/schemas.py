from pydantic import BaseModel


class NewsUpsert(BaseModel):
    admin_id: str
    title: str
    summary: str
    content: str
    image_url: str = ""
    author: str = "Admin"
