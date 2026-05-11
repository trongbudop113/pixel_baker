from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.models.auth import (
    AuthPageResponse,
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
)
from app.repositories.auth_page_repository import (
    AuthPageRepository,
    get_auth_page_repository,
)
from app.repositories.user_repository import UserRepository, get_user_repository
from app.services.auth_service import AuthService, get_auth_service

router = APIRouter()


async def _require_current_user(
    authorization: Optional[str] = Header(default=None),
    repository: UserRepository = Depends(get_user_repository),
) -> UserResponse:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token.",
        )

    token = authorization.removeprefix("Bearer ").strip()
    user = await repository.get_user_by_access_token(token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token.",
        )

    return user


@router.get("/pages/login", response_model=AuthPageResponse)
async def get_login_page(
    repository: AuthPageRepository = Depends(get_auth_page_repository),
) -> AuthPageResponse:
    return await repository.get_page("login")


@router.get("/pages/register", response_model=AuthPageResponse)
async def get_register_page(
    repository: AuthPageRepository = Depends(get_auth_page_repository),
) -> AuthPageResponse:
    return await repository.get_page("register")


@router.post("/register", response_model=AuthResponse)
async def register(
    payload: RegisterRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    return await auth_service.register(payload)


@router.post("/login", response_model=AuthResponse)
async def login(
    payload: LoginRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    return await auth_service.login(payload)


@router.post("/forgot-password", response_model=PasswordResetRequestResponse)
async def forgot_password(
    payload: ForgotPasswordRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> PasswordResetRequestResponse:
    return await auth_service.request_password_reset(payload)


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(
    payload: ResetPasswordRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> MessageResponse:
    return await auth_service.reset_password(payload)


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    payload: RefreshTokenRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    return await auth_service.refresh(payload)


@router.get("/me", response_model=UserResponse)
async def me(
    user: UserResponse = Depends(_require_current_user),
) -> UserResponse:
    return user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    payload: UpdateProfileRequest,
    user: UserResponse = Depends(_require_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await auth_service.update_profile(user.id, payload)


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    payload: ChangePasswordRequest,
    user: UserResponse = Depends(_require_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> MessageResponse:
    return await auth_service.change_password(user.id, payload)


@router.post("/logout", response_model=MessageResponse)
async def logout(
    user: UserResponse = Depends(_require_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> MessageResponse:
    return await auth_service.logout(user.id)
