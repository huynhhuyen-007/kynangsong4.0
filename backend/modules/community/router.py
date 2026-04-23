from fastapi import APIRouter
from .schemas import PostCreate, CommentCreate, LikeRequest, ReportRequest
from . import service

router = APIRouter(tags=["Community"])


@router.get("/api/community/posts")
async def get_posts(sort: str = "new"):
    return await service.get_posts(sort)


@router.post("/api/community/posts")
async def create_post(body: PostCreate):
    return await service.create_post(body)


@router.post("/api/community/posts/{post_id}/like")
async def toggle_like(post_id: str, body: LikeRequest):
    return await service.toggle_like(post_id, body)


@router.post("/api/community/posts/{post_id}/report")
async def report_post(post_id: str, body: ReportRequest):
    return await service.report_post(post_id, body)


@router.delete("/api/community/posts/{post_id}")
async def delete_post(post_id: str, admin_id: str):
    return await service.delete_post(post_id)


@router.get("/api/community/posts/{post_id}/comments")
async def get_comments(post_id: str):
    return await service.get_comments(post_id)


@router.post("/api/community/posts/{post_id}/comments")
async def add_comment(post_id: str, body: CommentCreate):
    return await service.add_comment(post_id, body)


@router.post("/api/community/comments/{comment_id}/report")
async def report_comment(comment_id: str, body: ReportRequest):
    return await service.report_comment(comment_id, body)
