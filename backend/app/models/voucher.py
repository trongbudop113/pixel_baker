from typing import List, Optional

from app.models.common import ApiModel


class VoucherResponse(ApiModel):
    code: str
    title: str
    note: str
    accent: str
    discountType: str
    discountValue: int
    minOrderValue: int = 0
    collected: bool = False
    used: bool = False


class CollectVoucherResponse(ApiModel):
    code: str
    message: str


class VoucherListResponse(ApiModel):
    items: List[VoucherResponse]


class ValidateVoucherRequest(ApiModel):
    code: str
    subtotal: int
    deliveryFee: int
    customerUserId: Optional[str] = None


class ValidateVoucherResponse(ApiModel):
    code: str
    discountAmount: int
    deliveryFeeAfterDiscount: int
    totalAfterDiscount: int
    message: str
