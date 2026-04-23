from fastapi import APIRouter, UploadFile, File
from .schemas import UserInRegister, UserInLogin, UserPublic
from . import service

router = APIRouter(tags=["Auth"])


@router.post("/api/auth/register", response_model=UserPublic)
async def register(body: UserInRegister):
    return await service.register_user(body)


@router.post("/api/auth/login", response_model=UserPublic)
async def login(body: UserInLogin):
    return await service.login_user(body)


@router.post("/api/users/{user_id}/avatar")
async def upload_avatar(user_id: str, file: UploadFile = File(...)):
    return await service.upload_avatar(user_id, file)
