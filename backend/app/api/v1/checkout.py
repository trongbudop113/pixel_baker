from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.models.auth import UserResponse
from typing import List

from app.models.checkout import (
    CartResponse,
    CartSyncRequest,
    OrderDetailResponse,
    CheckoutRequest,
    CheckoutResponse,
    CheckoutValidationResponse,
    OrderSummaryResponse,
)
from app.repositories.user_repository import UserRepository, get_user_repository
from app.services.checkout_service import CheckoutService, get_checkout_service

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


@router.post("/place", response_model=CheckoutResponse)
async def place_checkout(
    payload: CheckoutRequest,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> CheckoutResponse:
    return await checkout_service.place_order(user, payload)


@router.post("/validate", response_model=CheckoutValidationResponse)
async def validate_checkout(
    payload: CheckoutRequest,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> CheckoutValidationResponse:
    return await checkout_service.validate_checkout(user, payload)


@router.get("/cart", response_model=CartResponse)
async def get_cart(
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> CartResponse:
    return await checkout_service.get_cart(user)


@router.put("/cart", response_model=CartResponse)
async def replace_cart(
    payload: CartSyncRequest,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> CartResponse:
    return await checkout_service.replace_cart(user, payload)


@router.post("/cart/merge", response_model=CartResponse)
async def merge_cart(
    payload: CartSyncRequest,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> CartResponse:
    return await checkout_service.merge_cart(user, payload)


@router.get("/orders/mine", response_model=List[OrderSummaryResponse])
async def list_my_orders(
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> List[OrderSummaryResponse]:
    return await checkout_service.list_orders(user)


@router.get("/orders/{order_id}", response_model=OrderDetailResponse)
async def get_order_detail(
    order_id: str,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> OrderDetailResponse:
    return await checkout_service.get_order_detail(user, order_id)


@router.post("/orders/{order_id}/confirm-bank-transfer", response_model=OrderDetailResponse)
async def confirm_bank_transfer(
    order_id: str,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> OrderDetailResponse:
    return await checkout_service.confirm_bank_transfer(user, order_id)


@router.post("/orders/{order_id}/cancel", response_model=OrderDetailResponse)
async def cancel_order(
    order_id: str,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> OrderDetailResponse:
    return await checkout_service.cancel_order(user, order_id)


@router.post("/orders/{order_id}/refund-request", response_model=OrderDetailResponse)
async def request_refund(
    order_id: str,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> OrderDetailResponse:
    return await checkout_service.request_refund(user, order_id)
