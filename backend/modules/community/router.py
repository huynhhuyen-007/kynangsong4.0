import os, uuid, shutil
from fastapi import APIRouter, UploadFile, File, HTTPException
from .schemas import PostCreate, CommentCreate, LikeRequest, ReportRequest
from . import service

router = APIRouter(tags=["Community"])

# Thư mục lưu ảnh community
_UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "static", "community")
os.makedirs(_UPLOAD_DIR, exist_ok=True)

_MAX_SIZE = 5 * 1024 * 1024  # 5 MB


@router.post("/api/community/upload-image")
async def upload_community_image(file: UploadFile = File(...)):
    """Upload ảnh bài đăng cộng đồng. Max 5MB. Trả về image_url."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Chỉ chấp nhận file ảnh (image/*).")
    contents = await file.read()
    if len(contents) > _MAX_SIZE:
        raise HTTPException(status_code=400, detail="Ảnh quá lớn (tối đa 5MB).")
    ext = os.path.splitext(file.filename or "img.jpg")[1] or ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    dest = os.path.join(_UPLOAD_DIR, filename)
    with open(dest, "wb") as f:
        f.write(contents)
    return {"image_url": f"/static/community/{filename}"}




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
