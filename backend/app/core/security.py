from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class TokenError(Exception):
    """Raised when a JWT cannot be decoded or is invalid."""


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def _create_token(subject: str, expires_delta: timedelta, secret: str, token_type: str) -> str:
    now = datetime.now(timezone.utc)
    to_encode: dict[str, Any] = {
        "sub": subject,
        "iat": now.timestamp(),  # Use float timestamp to include microseconds
        "exp": int((now + expires_delta).timestamp()),
        "type": token_type,
    }
    return jwt.encode(to_encode, secret, algorithm=settings.jwt_algorithm)


def create_access_token(subject: str, expires_minutes: Optional[int] = None) -> str:
    minutes = expires_minutes or settings.access_token_expire_minutes
    return _create_token(subject, timedelta(minutes=minutes), settings.jwt_access_secret, "access")


def create_refresh_token(subject: str, expires_minutes: Optional[int] = None) -> str:
    minutes = expires_minutes or settings.refresh_token_expire_minutes
    return _create_token(subject, timedelta(minutes=minutes), settings.jwt_refresh_secret, "refresh")


def decode_token(token: str, *, refresh: bool = False) -> dict[str, Any]:
    secret = settings.jwt_refresh_secret if refresh else settings.jwt_access_secret
    try:
        payload = jwt.decode(token, secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:  # pragma: no cover - jose-specific error detail
        raise TokenError("Could not validate credentials") from exc

    if refresh and payload.get("type") != "refresh":
        raise TokenError("Invalid refresh token")
    if not refresh and payload.get("type") != "access":
        raise TokenError("Invalid access token")
    return payload
