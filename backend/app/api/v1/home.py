from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.models.auth import UserResponse
from app.models.home import (
    CreateHomeTestimonialRequest,
    HomePageResponse,
    HomeTestimonial,
)
from app.repositories.home_repository import HomeRepository, get_home_repository
from app.repositories.user_repository import UserRepository, get_user_repository

router = APIRouter()


async def _require_current_user(
    authorization: Optional[str] = Header(default=None),
    repository: UserRepository = Depends(get_user_repository),
) -> UserResponse:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Vui lòng đăng nhập để gửi đánh giá.",
        )

    token = authorization.removeprefix("Bearer ").strip()
    user = await repository.get_user_by_access_token(token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Phiên đăng nhập không hợp lệ.",
        )

    return user


@router.get("", response_model=HomePageResponse)
async def get_home_page(
    repository: HomeRepository = Depends(get_home_repository),
) -> HomePageResponse:
    return await repository.get_home_page()


@router.get("/testimonials", response_model=List[HomeTestimonial])
async def get_home_testimonials(
    repository: HomeRepository = Depends(get_home_repository),
) -> List[HomeTestimonial]:
    return await repository.list_testimonials()


@router.post("/testimonials", response_model=HomeTestimonial)
async def create_home_testimonial(
    payload: CreateHomeTestimonialRequest,
    user: UserResponse = Depends(_require_current_user),
    repository: HomeRepository = Depends(get_home_repository),
) -> HomeTestimonial:
    normalized = payload.content.strip()
    if len(normalized) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nội dung đánh giá phải có ít nhất 10 ký tự.",
        )
    return await repository.create_testimonial(
        user,
        CreateHomeTestimonialRequest(content=normalized),
    )
