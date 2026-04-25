from __future__ import annotations

import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from core.database import lifespan as _db_lifespan
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app):
    """Lifespan: khởi tạo DB + preload embedding model."""
    async with _db_lifespan(app):
        # Preload embedding model để lần đầu request không bị lag
        try:
            from modules.ai.service import _get_embedder
            await _get_embedder()
            print("[OK] Embedding model preloaded!")
        except Exception as e:
            print(f"[WARN] Embedding model preload failed: {e}")
        yield

# ── Khởi tạo app ─────────────────────────────────────────────────────────────
app = FastAPI(
    title="Ky Nang Song API",
    description="Backend cho ứng dụng Kỹ Năng Sống 4.0",
    version="2.0.0",
    lifespan=lifespan,
)

# ── Exception handler ─────────────────────────────────────────────────────────
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Lỗi định dạng dữ liệu: " + str(exc.errors()[0]["msg"])
        },
    )

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Static files — dùng absolute path để không bị lỗi sau refactor ───────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
static_dir = os.path.join(BASE_DIR, "static")
os.makedirs(os.path.join(static_dir, "avatars"), exist_ok=True)
os.makedirs(os.path.join(static_dir, "skills"), exist_ok=True)
os.makedirs(os.path.join(static_dir, "community"), exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")


# ── Include Routers (modules mới) ────────────────────────────────────────────
from modules.auth.router import router as auth_router
from modules.skill.router import router as skill_router
from modules.news.router import router as news_router
from modules.exam.router import router as exam_router
from modules.community.router import router as community_router
from modules.admin.router import router as admin_router
from modules.ai.router import router as ai_router
from modules.lesson.router import router as lesson_router

app.include_router(auth_router)
app.include_router(skill_router)
app.include_router(news_router)
app.include_router(exam_router)
app.include_router(community_router)
app.include_router(admin_router)
app.include_router(ai_router)
app.include_router(lesson_router)
