from typing import List, Optional

from pydantic import Field

from app.models.common import ApiModel


class CheckoutItemRequest(ApiModel):
    productId: int
    title: str = Field(min_length=1, max_length=180)
    priceValue: int = Field(ge=0)
    quantity: int = Field(ge=1)
    category: Optional[str] = None
    imageUrl: Optional[str] = None
    price: Optional[str] = None
    variantKey: Optional[str] = None
    variantLabel: Optional[str] = None
    boxItems: List["CheckoutBoxItemRequest"] = Field(default_factory=list)


class CheckoutBoxItemRequest(ApiModel):
    productId: int
    title: str = Field(min_length=1, max_length=180)
    variantLabel: str = Field(min_length=1, max_length=180)
    price: str = Field(min_length=1, max_length=80)
    priceValue: int = Field(ge=0)
    imageUrl: Optional[str] = None


class CartSyncRequest(ApiModel):
    items: List["CheckoutItemRequest"] = Field(default_factory=list)


class CheckoutRequest(ApiModel):
    paymentMethod: str = Field(min_length=1, max_length=80)
    deliveryFee: int = Field(ge=0)
    items: List[CheckoutItemRequest] = Field(min_length=1)
    voucherCode: Optional[str] = None
    customerUserId: Optional[str] = None


class CheckoutItemResponse(ApiModel):
    productId: int
    title: str
    priceValue: int
    quantity: int
    lineTotal: int
    category: Optional[str] = None
    imageUrl: Optional[str] = None
    price: Optional[str] = None
    variantKey: Optional[str] = None
    variantLabel: Optional[str] = None
    boxItems: List["CheckoutBoxItemResponse"] = Field(default_factory=list)


class CheckoutBoxItemResponse(ApiModel):
    productId: int
    title: str
    variantLabel: str
    price: str
    priceValue: int
    imageUrl: Optional[str] = None


class PaymentMethodOptionResponse(ApiModel):
    code: str
    label: str
    description: str
    enabled: bool = True


class BankTransferInfoResponse(ApiModel):
    bankName: str
    accountName: str
    accountNumber: str
    transferNotePrefix: str


class OrderTimelineEntryResponse(ApiModel):
    code: str
    title: str
    description: str
    createdAt: str


class IngredientShortageResponse(ApiModel):
    ingredientId: str
    ingredientName: str
    requiredQuantity: int
    availableQuantity: int
    unit: str


class CheckoutValidationResponse(ApiModel):
    canCheckout: bool
    subtotal: int
    deliveryFee: int
    discountAmount: int
    total: int
    paymentMethod: str
    paymentStatus: str
    voucherCode: Optional[str] = None
    shortages: List[IngredientShortageResponse] = Field(default_factory=list)
    message: str
    bankTransferInfo: Optional[BankTransferInfoResponse] = None
    paymentGateway: Optional[str] = None
    paymentActionUrl: Optional[str] = None


class CartResponse(ApiModel):
    items: List[CheckoutItemResponse] = Field(default_factory=list)
    itemCount: int
    subtotal: int


class CheckoutResponse(ApiModel):
    orderId: str
    status: str
    paymentMethod: str
    paymentStatus: str
    itemCount: int
    subtotal: int
    discountAmount: int
    deliveryFee: int
    total: int
    voucherCode: Optional[str] = None
    items: List[CheckoutItemResponse]
    message: str
    timeline: List[OrderTimelineEntryResponse] = Field(default_factory=list)
    invoiceHtml: Optional[str] = None
    bankTransferInfo: Optional[BankTransferInfoResponse] = None
    paymentGateway: Optional[str] = None
    paymentActionUrl: Optional[str] = None
    canCancel: bool = False
    canConfirmTransfer: bool = False
    canRequestRefund: bool = False


class OrderSummaryResponse(ApiModel):
    orderId: str
    status: str
    paymentMethod: str
    paymentStatus: str
    itemCount: int
    subtotal: int
    discountAmount: int
    deliveryFee: int
    total: int
    voucherCode: Optional[str] = None
    createdAt: str


class OrderDetailItemResponse(ApiModel):
    productId: int
    title: str
    priceValue: int
    quantity: int
    lineTotal: int
    category: Optional[str] = None
    imageUrl: Optional[str] = None
    price: Optional[str] = None
    variantKey: Optional[str] = None
    variantLabel: Optional[str] = None
    boxItems: List[CheckoutBoxItemResponse] = Field(default_factory=list)


class OrderDetailResponse(ApiModel):
    orderId: str
    customerName: str
    customerEmail: str
    customerPhone: Optional[str] = None
    customerAddress: Optional[str] = None
    status: str
    paymentMethod: str
    paymentStatus: str
    itemCount: int
    subtotal: int
    discountAmount: int
    deliveryFee: int
    total: int
    voucherCode: Optional[str] = None
    createdAt: str
    items: List[OrderDetailItemResponse]
    timeline: List[OrderTimelineEntryResponse] = Field(default_factory=list)
    invoiceHtml: Optional[str] = None
    bankTransferInfo: Optional[BankTransferInfoResponse] = None
    paymentGateway: Optional[str] = None
    paymentActionUrl: Optional[str] = None
    canCancel: bool = False
    canConfirmTransfer: bool = False
    canRequestRefund: bool = False
