from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import EmailStr, Field

from app.models.common import ApiModel


class UserRole(str, Enum):
    customer = "customer"
    staff = "staff"
    manager = "manager"
    admin = "admin"


class RegisterRequest(ApiModel):
    fullName: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=120)
    phone: Optional[str] = None
    address: Optional[str] = Field(default=None, max_length=240)


class LoginRequest(ApiModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=120)


class ForgotPasswordRequest(ApiModel):
    email: EmailStr


class ResetPasswordRequest(ApiModel):
    token: str = Field(min_length=16)
    newPassword: str = Field(min_length=6, max_length=120)


class UpdateProfileRequest(ApiModel):
    address: str = Field(min_length=5, max_length=240)
    addresses: Optional[List[str]] = None


class AddAddressRequest(ApiModel):
    address: str = Field(min_length=5, max_length=240)


class ChangePasswordRequest(ApiModel):
    currentPassword: str = Field(min_length=6, max_length=120)
    newPassword: str = Field(min_length=6, max_length=120)


class MessageResponse(ApiModel):
    message: str


class PasswordResetRequestResponse(MessageResponse):
    debugToken: Optional[str] = None


class UserResponse(ApiModel):
    id: str
    fullName: str
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None
    addresses: List[str] = []
    points: int = 0
    role: UserRole = UserRole.customer
    permissions: List[str] = []
    isAdmin: bool = False


class AuthResponse(ApiModel):
    accessToken: str
    refreshToken: str
    tokenType: str = "bearer"
    accessTokenExpiresAt: datetime
    refreshTokenExpiresAt: datetime
    user: UserResponse


class RefreshTokenRequest(ApiModel):
    refreshToken: str = Field(min_length=16)


class AuthFieldResponse(ApiModel):
    label: str


class AuthPageResponse(ApiModel):
    headerBrand: str
    headerTitle: str
    introTitle: str
    introDescription: str
    fields: list[AuthFieldResponse]
    helpText: Optional[str] = None
    primaryActionLabel: str
    socialActionLabel: str
    switchPrompt: str
    switchActionLabel: str
    footerTagline: str
