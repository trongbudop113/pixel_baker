from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
from uuid import uuid4

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

password_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    return password_context.verify(password, hashed_password)


def create_access_token(subject: str) -> tuple[str, datetime]:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_expire_minutes
    )
    payload = {
        "sub": subject,
        "typ": "access",
        "jti": uuid4().hex,
        "exp": expires_at,
    }
    token = jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, expires_at


def create_refresh_token(subject: str) -> tuple[str, datetime]:
    expires_at = datetime.now(timezone.utc) + timedelta(
        days=settings.jwt_refresh_expire_days
    )
    payload = {
        "sub": subject,
        "typ": "refresh",
        "jti": uuid4().hex,
        "exp": expires_at,
    }
    token = jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, expires_at


def create_password_reset_token(subject: str) -> tuple[str, datetime]:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.password_reset_expire_minutes
    )
    payload = {
        "sub": subject,
        "typ": "reset",
        "jti": uuid4().hex,
        "exp": expires_at,
    }
    token = jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, expires_at


def decode_token(token: str) -> Dict[str, Any]:
    return jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
    )


def read_token_subject(token: str, *, expected_type: str) -> Optional[str]:
    try:
        payload = decode_token(token)
    except JWTError:
        return None
    if payload.get("typ") != expected_type:
        return None
    subject = payload.get("sub")
    if not isinstance(subject, str) or not subject.strip():
        return None
    return subject
