from fastapi import APIRouter, UploadFile, File
from .schemas import UserInRegister, UserInLogin, UserPublic, ForgotPasswordRequest, ResetPasswordRequest
from . import service

router = APIRouter(tags=["Auth"])


@router.post("/api/auth/register", response_model=UserPublic)
async def register(body: UserInRegister):
    return await service.register_user(body)


@router.post("/api/auth/login", response_model=UserPublic)
async def login(body: UserInLogin):
    return await service.login_user(body)


@router.post("/api/auth/forgot-password")
async def forgot_password(body: ForgotPasswordRequest):
    return await service.forgot_password(body)


@router.post("/api/auth/reset-password")
async def reset_password(body: ResetPasswordRequest):
    return await service.reset_password(body)


@router.post("/api/users/{user_id}/avatar")
async def upload_avatar(user_id: str, file: UploadFile = File(...)):
    return await service.upload_avatar(user_id, file)
