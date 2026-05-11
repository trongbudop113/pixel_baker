from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.models.auth import UserResponse
from app.models.voucher import (
    CollectVoucherResponse,
    ValidateVoucherRequest,
    ValidateVoucherResponse,
    VoucherListResponse,
    VoucherResponse,
)
from app.repositories.user_repository import UserRepository, get_user_repository
from app.repositories.voucher_repository import VoucherRepository, get_voucher_repository

router = APIRouter()


async def _try_get_current_user(
    authorization: Optional[str],
    repository: UserRepository,
) -> Optional[UserResponse]:
    if authorization is None or not authorization.startswith("Bearer "):
      return None
    token = authorization.removeprefix("Bearer ").strip()
    return await repository.get_user_by_access_token(token)


async def _require_current_user(
    authorization: Optional[str] = Header(default=None),
    repository: UserRepository = Depends(get_user_repository),
) -> UserResponse:
    user = await _try_get_current_user(authorization, repository)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Vui lòng đăng nhập để thu thập voucher.",
        )
    return user


@router.get("", response_model=VoucherListResponse)
async def list_vouchers(
    authorization: Optional[str] = Header(default=None),
    user_repository: UserRepository = Depends(get_user_repository),
    voucher_repository: VoucherRepository = Depends(get_voucher_repository),
) -> VoucherListResponse:
    user = await _try_get_current_user(authorization, user_repository)
    collected_codes = set()
    used_codes = set()
    if user is not None:
        user_document = await user_repository.get_user_by_id(user.id)
        if user_document:
            collected_codes = set(user_document.get("collectedVoucherCodes", []))
            used_codes = set(user_document.get("usedVoucherCodes", []))

    vouchers = await voucher_repository.list_vouchers()
    return VoucherListResponse(
        items=[
            VoucherResponse(
                code=item["code"],
                title=item["title"],
                note=item["note"],
                accent=item["accent"],
                discountType=item["discountType"],
                discountValue=item["discountValue"],
                minOrderValue=item.get("minOrderValue", 0),
                collected=item["code"] in collected_codes,
                used=item["code"] in used_codes,
            )
            for item in vouchers
        ]
    )


@router.post("/collect/{code}", response_model=CollectVoucherResponse)
async def collect_voucher(
    code: str,
    user: UserResponse = Depends(_require_current_user),
    user_repository: UserRepository = Depends(get_user_repository),
    voucher_repository: VoucherRepository = Depends(get_voucher_repository),
) -> CollectVoucherResponse:
    normalized_code = code.upper().strip()
    voucher = await voucher_repository.get_voucher_by_code(normalized_code)
    if voucher is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voucher không tồn tại.",
        )

    user_document = await user_repository.get_user_by_id(user.id)
    used_codes = set(user_document.get("usedVoucherCodes", [])) if user_document else set()
    if normalized_code in used_codes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Voucher này đã được sử dụng.",
        )

    await user_repository.collect_voucher(user.id, normalized_code)
    return CollectVoucherResponse(
        code=normalized_code,
        message="Thu thập voucher thành công.",
    )


@router.post("/validate", response_model=ValidateVoucherResponse)
async def validate_voucher(
    payload: ValidateVoucherRequest,
    user: UserResponse = Depends(_require_current_user),
    user_repository: UserRepository = Depends(get_user_repository),
    voucher_repository: VoucherRepository = Depends(get_voucher_repository),
) -> ValidateVoucherResponse:
    normalized_code = payload.code.upper().strip()
    target_user_id = user.id
    if user.isAdmin and payload.customerUserId:
        customer_document = await user_repository.get_user_by_id(payload.customerUserId)
        if customer_document is None or bool(customer_document.get("isAdmin", False)):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy khách hàng hợp lệ.",
            )
        target_user_id = str(customer_document.get("id") or "")

    user_document = await user_repository.get_user_by_id(target_user_id)
    collected_codes = set(user_document.get("collectedVoucherCodes", [])) if user_document else set()
    used_codes = set(user_document.get("usedVoucherCodes", [])) if user_document else set()

    if normalized_code in used_codes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Voucher này đã được sử dụng.",
        )
    if normalized_code not in collected_codes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bạn chưa thu thập voucher này.",
        )

    voucher = await voucher_repository.get_voucher_by_code(normalized_code)
    if voucher is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Voucher không tồn tại.",
        )
    if payload.subtotal < voucher.get("minOrderValue", 0):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Đơn hàng chưa đạt điều kiện áp dụng voucher.",
        )

    discount_amount = 0
    delivery_fee_after_discount = payload.deliveryFee
    if voucher["discountType"] == "shipping":
        discount_amount = min(payload.deliveryFee, voucher["discountValue"])
        delivery_fee_after_discount = max(0, payload.deliveryFee - discount_amount)
    elif voucher["discountType"] == "percent":
        discount_amount = payload.subtotal * voucher["discountValue"] // 100

    return ValidateVoucherResponse(
        code=normalized_code,
        discountAmount=discount_amount,
        deliveryFeeAfterDiscount=delivery_fee_after_discount,
        totalAfterDiscount=payload.subtotal + delivery_fee_after_discount - discount_amount,
        message=f"Áp dụng voucher {normalized_code} thành công.",
    )
