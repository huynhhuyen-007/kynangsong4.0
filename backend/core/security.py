from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Mã hóa mật khẩu bằng bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    """Kiểm tra mật khẩu plaintext với hash đã lưu."""
    return pwd_context.verify(plain, hashed)
