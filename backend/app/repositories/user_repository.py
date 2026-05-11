from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.config import settings
from app.core.security import read_token_subject
from app.core.database import get_database
from app.models.auth import UserResponse, UserRole


class UserRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["users"]

    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"email": email.lower().strip()})

    async def create_user(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        await self._collection.insert_one(payload)
        created = await self._collection.find_one({"email": payload["email"]})
        if created is None:
            raise RuntimeError("Failed to create user.")
        return created

    async def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"id": user_id})

    async def get_non_admin_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"id": user_id, "isAdmin": {"$ne": True}})

    async def save_session(
        self,
        user_id: str,
        *,
        access_token: str,
        refresh_token: str,
        access_token_expires_at: datetime,
        refresh_token_expires_at: datetime,
    ) -> None:
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "accessToken": access_token,
                    "refreshToken": refresh_token,
                    "accessTokenExpiresAt": access_token_expires_at.isoformat(),
                    "refreshTokenExpiresAt": refresh_token_expires_at.isoformat(),
                    "lastLoginAt": datetime.now(timezone.utc).isoformat(),
                }
            },
        )

    async def get_user_by_access_token(self, token: str) -> Optional[UserResponse]:
        user_id = read_token_subject(token, expected_type="access")
        if user_id is None:
            return None
        document = await self._collection.find_one({"id": user_id, "accessToken": token})
        if document is None:
            return None
        if _is_expired(document.get("accessTokenExpiresAt")):
            return None
        return _to_user_response(document)

    async def get_user_document_by_refresh_token(self, token: str) -> Optional[Dict[str, Any]]:
        user_id = read_token_subject(token, expected_type="refresh")
        if user_id is None:
            return None
        document = await self._collection.find_one({"id": user_id, "refreshToken": token})
        if document is None:
            return None
        if _is_expired(document.get("refreshTokenExpiresAt")):
            return None
        return document

    async def clear_session(self, user_id: str) -> None:
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "accessToken": None,
                    "refreshToken": None,
                    "accessTokenExpiresAt": None,
                    "refreshTokenExpiresAt": None,
                }
            },
        )

    async def register_failed_login_attempt(self, user_id: str) -> None:
        document = await self.get_user_by_id(user_id)
        if document is None:
            return
        failed_count = int(document.get("failedLoginCount") or 0) + 1
        locked_until = None
        if failed_count >= settings.login_max_attempts:
            locked_until = (
                datetime.now(timezone.utc)
                + timedelta(minutes=settings.login_lock_minutes)
            ).isoformat()
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "failedLoginCount": failed_count,
                    "lastFailedLoginAt": datetime.now(timezone.utc).isoformat(),
                    "loginLockedUntil": locked_until,
                }
            },
        )

    async def clear_failed_login_attempts(self, user_id: str) -> None:
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "failedLoginCount": 0,
                    "lastFailedLoginAt": None,
                    "loginLockedUntil": None,
                }
            },
        )

    async def save_password_reset_token(
        self,
        user_id: str,
        *,
        token: str,
        expires_at: datetime,
    ) -> None:
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "passwordResetToken": token,
                    "passwordResetExpiresAt": expires_at.isoformat(),
                }
            },
        )

    async def get_user_document_by_password_reset_token(
        self,
        token: str,
    ) -> Optional[Dict[str, Any]]:
        user_id = read_token_subject(token, expected_type="reset")
        if user_id is None:
            return None
        document = await self._collection.find_one(
            {"id": user_id, "passwordResetToken": token}
        )
        if document is None:
            return None
        if _is_expired(document.get("passwordResetExpiresAt")):
            return None
        return document

    async def clear_password_reset_token(self, user_id: str) -> None:
        await self._collection.update_one(
            {"id": user_id},
            {
                "$set": {
                    "passwordResetToken": None,
                    "passwordResetExpiresAt": None,
                }
            },
        )

    def is_login_locked(self, document: Dict[str, Any]) -> bool:
        return not _is_expired(document.get("loginLockedUntil"))

    async def update_address(self, user_id: str, address: str) -> Optional[UserResponse]:
        await self._collection.update_one(
            {"id": user_id},
            {"$set": {"address": address.strip()}},
        )
        document = await self._collection.find_one({"id": user_id})
        if document is None:
            return None
        return _to_user_response(document)

    async def update_password(self, user_id: str, hashed_password: str) -> bool:
        result = await self._collection.update_one(
            {"id": user_id},
            {"$set": {"hashedPassword": hashed_password}},
        )
        return result.matched_count > 0

    async def update_customer_by_admin(
        self,
        user_id: str,
        *,
        full_name: str,
        email: str,
        phone: Optional[str],
        address: Optional[str],
    ) -> Optional[UserResponse]:
        await self._collection.update_one(
            {"id": user_id, "isAdmin": {"$ne": True}},
            {
                "$set": {
                    "fullName": full_name.strip(),
                    "email": email.lower().strip(),
                    "phone": phone.strip() if phone else None,
                    "address": address.strip() if address else None,
                }
            },
        )
        document = await self._collection.find_one({"id": user_id, "isAdmin": {"$ne": True}})
        if document is None:
            return None
        return _to_user_response(document)

    async def collect_voucher(self, user_id: str, code: str) -> bool:
        result = await self._collection.update_one(
            {"id": user_id},
            {"$addToSet": {"collectedVoucherCodes": code.upper().strip()}},
        )
        return result.matched_count > 0

    async def mark_voucher_used(self, user_id: str, code: str) -> bool:
        normalized_code = code.upper().strip()
        result = await self._collection.update_one(
            {"id": user_id},
            {
                "$addToSet": {"usedVoucherCodes": normalized_code},
                "$pull": {"collectedVoucherCodes": normalized_code},
            },
        )
        return result.matched_count > 0

    async def release_used_voucher(self, user_id: str, code: str) -> bool:
        normalized_code = code.upper().strip()
        result = await self._collection.update_one(
            {"id": user_id},
            {
                "$pull": {"usedVoucherCodes": normalized_code},
                "$addToSet": {"collectedVoucherCodes": normalized_code},
            },
        )
        return result.matched_count > 0


def get_user_repository() -> UserRepository:
    return UserRepository(get_database())


def _to_user_response(document: Dict[str, Any]) -> UserResponse:
    role_value = str(document.get("role") or ("admin" if document.get("isAdmin") else "customer"))
    try:
        role = UserRole(role_value)
    except ValueError:
        role = UserRole.customer
    return UserResponse(
        id=document["id"],
        fullName=document["fullName"],
        email=document["email"],
        phone=document.get("phone"),
        address=document.get("address"),
        role=role,
        permissions=_permissions_for_role(role),
        isAdmin=bool(document.get("isAdmin", False)) or role in {UserRole.admin, UserRole.manager},
    )


def _permissions_for_role(role: UserRole) -> list[str]:
    if role == UserRole.admin:
        return ["*"]
    if role == UserRole.manager:
        return [
            "admin:access",
            "reports:view",
            "imports:view",
            "orders:manage",
            "orders:view",
            "products:manage",
            "products:view",
            "inventory:manage",
            "inventory:view",
            "recipes:manage",
            "recipes:view",
            "customers:manage",
            "customers:view",
            "vouchers:manage",
            "vouchers:view",
            "testimonials:manage",
            "testimonials:view",
            "content:manage",
            "content:view",
        ]
    if role == UserRole.staff:
        return [
            "admin:access",
            "reports:view",
            "imports:view",
            "orders:manage",
            "orders:view",
            "products:view",
            "inventory:view",
            "recipes:view",
            "customers:view",
            "vouchers:view",
            "testimonials:view",
            "content:view",
        ]
    return []


def _is_expired(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, datetime):
        expires_at = value
    else:
        try:
            expires_at = datetime.fromisoformat(str(value))
        except ValueError:
            return True
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at <= datetime.now(timezone.utc)
