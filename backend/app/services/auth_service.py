from datetime import datetime, timezone
from uuid import uuid4

from fastapi import Depends, HTTPException, status

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_password_reset_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.models.auth import (
    AuthResponse,
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LoginRequest,
    MessageResponse,
    PasswordResetRequestResponse,
    RefreshTokenRequest,
    RegisterRequest,
    ResetPasswordRequest,
    UpdateProfileRequest,
    UserResponse,
    UserRole,
)
from app.repositories.user_repository import UserRepository, get_user_repository


class AuthService:
    def __init__(self, user_repository: UserRepository):
        self._user_repository = user_repository

    async def register(self, payload: RegisterRequest) -> AuthResponse:
        existing = await self._user_repository.get_user_by_email(payload.email)
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already exists.",
            )

        user_id = str(uuid4())
        access_token, access_expires_at = create_access_token(user_id)
        refresh_token, refresh_expires_at = create_refresh_token(user_id)
        document = {
            "id": user_id,
            "fullName": payload.fullName,
            "email": payload.email.lower().strip(),
            "phone": payload.phone,
            "address": payload.address,
            "role": UserRole.customer.value,
            "isAdmin": False,
            "createdAt": datetime.now(timezone.utc).isoformat(),
            "hashedPassword": hash_password(payload.password),
            "accessToken": access_token,
            "refreshToken": refresh_token,
            "accessTokenExpiresAt": access_expires_at.isoformat(),
            "refreshTokenExpiresAt": refresh_expires_at.isoformat(),
        }
        user = await self._user_repository.create_user(document)
        return AuthResponse(
            accessToken=access_token,
            refreshToken=refresh_token,
            accessTokenExpiresAt=access_expires_at,
            refreshTokenExpiresAt=refresh_expires_at,
            user=_to_user_response(user),
        )

    async def login(self, payload: LoginRequest) -> AuthResponse:
        user = await self._user_repository.get_user_by_email(payload.email)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )
        if self._user_repository.is_login_locked(user):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Tài khoản tạm thời bị khóa do đăng nhập sai quá nhiều lần. "
                    f"Vui lòng thử lại sau {settings.login_lock_minutes} phút."
                ),
            )
        if not verify_password(payload.password, user["hashedPassword"]):
            await self._user_repository.register_failed_login_attempt(user["id"])
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )

        access_token, access_expires_at = create_access_token(user["id"])
        refresh_token, refresh_expires_at = create_refresh_token(user["id"])
        await self._user_repository.clear_failed_login_attempts(user["id"])
        await self._user_repository.save_session(
            user["id"],
            access_token=access_token,
            refresh_token=refresh_token,
            access_token_expires_at=access_expires_at,
            refresh_token_expires_at=refresh_expires_at,
        )
        return AuthResponse(
            accessToken=access_token,
            refreshToken=refresh_token,
            accessTokenExpiresAt=access_expires_at,
            refreshTokenExpiresAt=refresh_expires_at,
            user=_to_user_response(user),
        )

    async def request_password_reset(
        self,
        payload: ForgotPasswordRequest,
    ) -> PasswordResetRequestResponse:
        user = await self._user_repository.get_user_by_email(payload.email)
        debug_token = None
        if user is not None:
            reset_token, expires_at = create_password_reset_token(user["id"])
            await self._user_repository.save_password_reset_token(
                user["id"],
                token=reset_token,
                expires_at=expires_at,
            )
            if settings.app_debug:
                debug_token = reset_token
        return PasswordResetRequestResponse(
            message=(
                "Nếu email tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu "
                "đã được gửi."
            ),
            debugToken=debug_token,
        )

    async def reset_password(
        self,
        payload: ResetPasswordRequest,
    ) -> MessageResponse:
        user = await self._user_repository.get_user_document_by_password_reset_token(
            payload.token
        )
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.",
            )
        await self._user_repository.update_password(
            user["id"],
            hash_password(payload.newPassword),
        )
        await self._user_repository.clear_password_reset_token(user["id"])
        await self._user_repository.clear_session(user["id"])
        await self._user_repository.clear_failed_login_attempts(user["id"])
        return MessageResponse(
            message="Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."
        )

    async def refresh(self, payload: RefreshTokenRequest) -> AuthResponse:
        user = await self._user_repository.get_user_document_by_refresh_token(
            payload.refreshToken
        )
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token không hợp lệ hoặc đã hết hạn.",
            )
        access_token, access_expires_at = create_access_token(user["id"])
        refresh_token, refresh_expires_at = create_refresh_token(user["id"])
        await self._user_repository.save_session(
            user["id"],
            access_token=access_token,
            refresh_token=refresh_token,
            access_token_expires_at=access_expires_at,
            refresh_token_expires_at=refresh_expires_at,
        )
        return AuthResponse(
            accessToken=access_token,
            refreshToken=refresh_token,
            accessTokenExpiresAt=access_expires_at,
            refreshTokenExpiresAt=refresh_expires_at,
            user=_to_user_response(user),
        )

    async def logout(self, user_id: str) -> MessageResponse:
        await self._user_repository.clear_session(user_id)
        return MessageResponse(message="Đăng xuất thành công.")

    async def update_profile(
        self,
        user_id: str,
        payload: UpdateProfileRequest,
    ) -> UserResponse:
        user = await self._user_repository.update_address(user_id, payload.address)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )
        return user

    async def change_password(
        self,
        user_id: str,
        payload: ChangePasswordRequest,
    ) -> MessageResponse:
        user = await self._user_repository.get_user_by_id(user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        if not verify_password(payload.currentPassword, user["hashedPassword"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mật khẩu hiện tại không đúng.",
            )

        if payload.currentPassword == payload.newPassword:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mật khẩu mới phải khác mật khẩu hiện tại.",
            )

        await self._user_repository.update_password(
            user_id,
            hash_password(payload.newPassword),
        )
        return MessageResponse(message="Cập nhật mật khẩu thành công.")


def get_auth_service(
    user_repository: UserRepository = Depends(get_user_repository),
) -> AuthService:
    return AuthService(user_repository)


def _to_user_response(user: dict) -> UserResponse:
    role_value = str(
        user.get("role") or ("admin" if user.get("isAdmin") else "customer")
    )
    try:
        role = UserRole(role_value)
    except ValueError:
        role = UserRole.customer
    permissions = _permissions_for_role(role)
    return UserResponse(
        id=user["id"],
        fullName=user["fullName"],
        email=user["email"],
        phone=user.get("phone"),
        address=user.get("address"),
        role=role,
        permissions=permissions,
        isAdmin=bool(user.get("isAdmin", False)) or role in {UserRole.admin, UserRole.manager},
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
