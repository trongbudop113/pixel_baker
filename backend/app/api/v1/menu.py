from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status

from app.models.auth import UserResponse
from app.models.menu import (
    MenuPageResponse,
    MenuReviewCreateRequest,
    MenuProductDetailResponse,
    MenuProductResponse,
)
from app.repositories.menu_repository import MenuRepository, get_menu_repository
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


@router.get("", response_model=MenuPageResponse)
async def get_menu_page(
    repository: MenuRepository = Depends(get_menu_repository),
) -> MenuPageResponse:
    return await repository.get_menu_page()


@router.get("/products", response_model=List[MenuProductResponse])
async def get_products(
    category: Optional[str] = Query(default=None),
    q: Optional[str] = Query(default=None),
    sort: Optional[str] = Query(default=None),
    repository: MenuRepository = Depends(get_menu_repository),
) -> List[MenuProductResponse]:
    items = await repository.list_products(category=category)
    if q:
        keyword = q.strip().lower()
        items = [
            item
            for item in items
            if keyword in item.title.lower()
            or keyword in item.category.lower()
            or keyword in item.description.lower()
        ]
    if sort == "price_asc":
        items.sort(key=lambda item: item.priceValue)
    elif sort == "price_desc":
        items.sort(key=lambda item: item.priceValue, reverse=True)
    elif sort == "rating_desc":
        items.sort(
            key=lambda item: (item.averageRating, item.reviewCount),
            reverse=True,
        )
    return items


@router.get("/products/{product_id}", response_model=MenuProductDetailResponse)
async def get_product_by_id(
    product_id: int,
    repository: MenuRepository = Depends(get_menu_repository),
) -> MenuProductDetailResponse:
    product = await repository.get_product_by_id(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )
    return product


@router.post("/products/{product_id}/reviews", response_model=MenuProductDetailResponse)
async def create_product_review(
    product_id: int,
    payload: MenuReviewCreateRequest,
    user: UserResponse = Depends(_require_current_user),
    repository: MenuRepository = Depends(get_menu_repository),
) -> MenuProductDetailResponse:
    if not payload.content.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nội dung đánh giá không được để trống.",
        )
    product = await repository.add_review(
        product_id,
        author=user.fullName,
        payload=payload,
    )
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )
    return product
