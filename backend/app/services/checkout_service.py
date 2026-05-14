from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4

from fastapi import Depends
from fastapi import HTTPException, status

from app.models.auth import UserResponse
from app.models.checkout import (
    BankTransferInfoResponse,
    CartResponse,
    CartSyncRequest,
    CheckoutItemResponse,
    CheckoutRequest,
    CheckoutResponse,
    CheckoutValidationResponse,
    IngredientShortageResponse,
    OrderDetailItemResponse,
    OrderDetailResponse,
    OrderSummaryResponse,
    OrderTimelineEntryResponse,
)
from app.repositories.admin_repository import AdminRepository, get_admin_repository
from app.repositories.cart_repository import CartRepository, get_cart_repository
from app.repositories.order_repository import OrderRepository, get_order_repository
from app.repositories.user_repository import UserRepository, get_user_repository
from app.repositories.voucher_repository import VoucherRepository, get_voucher_repository


PAYMENT_COD = "cod"
PAYMENT_BANK_TRANSFER = "bank_transfer"

ORDER_STATUS_PENDING = "pending"
ORDER_STATUS_PROCESSING = "processing"
ORDER_STATUS_SHIPPING = "shipping"
ORDER_STATUS_DELIVERED = "delivered"
ORDER_STATUS_COMPLETED = "completed"
ORDER_STATUS_CANCELLED = "cancelled"
ORDER_STATUS_REFUND_PENDING = "refund_pending"
ORDER_STATUS_REFUNDED = "refunded"

PAYMENT_STATUS_PENDING_COD = "pending_cod"
PAYMENT_STATUS_AWAITING_TRANSFER = "awaiting_transfer"
PAYMENT_STATUS_PAID = "paid"
PAYMENT_STATUS_CANCELLED = "cancelled"
PAYMENT_STATUS_REFUND_PENDING = "refund_pending"
PAYMENT_STATUS_REFUNDED = "refunded"


class CheckoutService:
    def __init__(
        self,
        order_repository: OrderRepository,
        user_repository: UserRepository,
        voucher_repository: VoucherRepository,
        admin_repository: AdminRepository,
        cart_repository: CartRepository,
    ):
        self._order_repository = order_repository
        self._user_repository = user_repository
        self._voucher_repository = voucher_repository
        self._admin_repository = admin_repository
        self._cart_repository = cart_repository

    async def get_cart(self, user: UserResponse) -> CartResponse:
        document = await self._cart_repository.get_cart_by_user_id(user.id)
        items = self._normalize_items(document.get("items", []) if document else [])
        return self._build_cart_response(items)

    async def replace_cart(self, user: UserResponse, payload: CartSyncRequest) -> CartResponse:
        items = self._normalize_items([item.model_dump() for item in payload.items])
        await self._cart_repository.save_cart(user.id, items)
        return self._build_cart_response(items)

    async def merge_cart(self, user: UserResponse, payload: CartSyncRequest) -> CartResponse:
        remote_document = await self._cart_repository.get_cart_by_user_id(user.id)
        remote_items = self._normalize_items(remote_document.get("items", []) if remote_document else [])
        merged = self._merge_items(remote_items, [item.model_dump() for item in payload.items])
        await self._cart_repository.save_cart(user.id, merged)
        return self._build_cart_response(merged)

    async def validate_checkout(
        self,
        user: UserResponse,
        payload: CheckoutRequest,
    ) -> CheckoutValidationResponse:
        target_user = await self._resolve_target_user(user, payload.customerUserId)
        subtotal = sum(item.priceValue * item.quantity for item in payload.items)
        delivery_fee = payload.deliveryFee
        discount_amount = 0
        applied_voucher_code = None

        # Check stock status for all products in cart
        product_ids = list({item.productId for item in payload.items if item.productId})
        out_of_stock = await self._admin_repository.check_products_stock(product_ids)
        if out_of_stock:
            names = ", ".join(p["title"] for p in out_of_stock)
            return CheckoutValidationResponse(
                canCheckout=False,
                subtotal=subtotal,
                deliveryFee=delivery_fee,
                discountAmount=0,
                total=subtotal + delivery_fee,
                paymentMethod=payload.paymentMethod,
                paymentStatus=self._initial_payment_status(payload.paymentMethod),
                voucherCode=payload.voucherCode,
                shortages=[],
                message=f"Sản phẩm đã hết hàng: {names}. Vui lòng xoá khỏi giỏ và thử lại.",
                bankTransferInfo=self._bank_transfer_info()
                if payload.paymentMethod == PAYMENT_BANK_TRANSFER
                else None,
            )

        shortages = await self._admin_repository.validate_ingredients_for_order_items(
            [item.model_dump() for item in payload.items]
        )
        if shortages:
            return CheckoutValidationResponse(
                canCheckout=False,
                subtotal=subtotal,
                deliveryFee=delivery_fee,
                discountAmount=0,
                total=subtotal + delivery_fee,
                paymentMethod=payload.paymentMethod,
                paymentStatus=self._initial_payment_status(payload.paymentMethod),
                voucherCode=payload.voucherCode,
                shortages=[
                    IngredientShortageResponse(**shortage) for shortage in shortages
                ],
                message="Không đủ nguyên liệu để xử lý đơn hàng hiện tại.",
                bankTransferInfo=self._bank_transfer_info()
                if payload.paymentMethod == PAYMENT_BANK_TRANSFER
                else None,
            )

        if payload.voucherCode:
            (
                applied_voucher_code,
                delivery_fee,
                discount_amount,
            ) = await self._apply_voucher(
                target_user_id=target_user.id,
                voucher_code=payload.voucherCode,
                subtotal=subtotal,
                delivery_fee=delivery_fee,
            )

        total = subtotal + delivery_fee - discount_amount
        return CheckoutValidationResponse(
            canCheckout=True,
            subtotal=subtotal,
            deliveryFee=delivery_fee,
            discountAmount=discount_amount,
            total=total,
            paymentMethod=payload.paymentMethod,
            paymentStatus=self._initial_payment_status(payload.paymentMethod),
            voucherCode=applied_voucher_code,
            message=(
                "Đơn hàng hợp lệ. Vui lòng chuyển khoản theo thông tin bên dưới."
                if payload.paymentMethod == PAYMENT_BANK_TRANSFER
                else "Đơn hàng hợp lệ và sẵn sàng xác nhận."
            ),
            bankTransferInfo=self._bank_transfer_info()
            if payload.paymentMethod == PAYMENT_BANK_TRANSFER
            else None,
            paymentGateway=self._payment_gateway(payload.paymentMethod),
            paymentActionUrl=self._payment_action_url(None, payload.paymentMethod),
        )

    async def place_order(
        self,
        user: UserResponse,
        payload: CheckoutRequest,
    ) -> CheckoutResponse:
        target_user = await self._resolve_target_user(user, payload.customerUserId)
        validation = await self.validate_checkout(user, payload)
        if not validation.canCheckout:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=validation.message,
            )

        item_count = sum(item.quantity for item in payload.items)
        order_id = f"OD-{uuid4().hex[:10].upper()}"
        created_at = datetime.now(timezone.utc).isoformat()
        timeline = self._build_order_timeline(payload.paymentMethod, created_at)
        items = [
            {
                "productId": item.productId,
                "title": item.title,
                "priceValue": item.priceValue,
                "quantity": item.quantity,
                "lineTotal": item.priceValue * item.quantity,
                "category": item.category,
                "imageUrl": item.imageUrl,
                "price": item.price,
                "variantKey": item.variantKey,
                "variantLabel": item.variantLabel,
                "boxItems": [
                    {
                        "productId": box_item.productId,
                        "title": box_item.title,
                        "variantLabel": box_item.variantLabel,
                        "price": box_item.price,
                        "priceValue": box_item.priceValue,
                        "imageUrl": box_item.imageUrl,
                    }
                    for box_item in item.boxItems
                ],
            }
            for item in payload.items
        ]

        try:
            await self._admin_repository.deduct_ingredients_for_order_items(
                items,
                reference_type="order",
                reference_id=order_id,
            )
        except ValueError as error:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(error),
            ) from error

        payment_status = self._initial_payment_status(payload.paymentMethod)
        order_status = self._initial_order_status(payload.paymentMethod)
        await self._order_repository.create_order(
            {
                "orderId": order_id,
                "userId": target_user.id,
                "customerName": target_user.fullName,
                "customerEmail": target_user.email,
                "customerPhone": target_user.phone,
                "customerAddress": target_user.address,
                "paymentMethod": payload.paymentMethod,
                "status": order_status,
                "paymentStatus": payment_status,
                "itemCount": item_count,
                "subtotal": validation.subtotal,
                "discountAmount": validation.discountAmount,
                "deliveryFee": validation.deliveryFee,
                "total": validation.total,
                "voucherCode": validation.voucherCode,
                "orderNote": payload.orderNote,
                "deliveryDate": payload.deliveryDate,
                "deliveryTimeSlot": payload.deliveryTimeSlot,
                "items": items,
                "createdAt": created_at,
                "timeline": [entry.model_dump() for entry in timeline],
            }
        )

        if validation.voucherCode is not None:
            await self._user_repository.mark_voucher_used(target_user.id, validation.voucherCode)

        if not user.isAdmin or target_user.id == user.id:
            await self._cart_repository.clear_cart(user.id)

        invoice_html = self._build_invoice_html(
            order_id=order_id,
            customer_name=target_user.fullName,
            customer_email=target_user.email,
            customer_phone=target_user.phone,
            customer_address=target_user.address,
            items=items,
            subtotal=validation.subtotal,
            discount_amount=validation.discountAmount,
            delivery_fee=validation.deliveryFee,
            total=validation.total,
            payment_method=payload.paymentMethod,
            created_at=created_at,
        )

        return CheckoutResponse(
            orderId=order_id,
            status=order_status,
            paymentMethod=payload.paymentMethod,
            paymentStatus=payment_status,
            itemCount=item_count,
            subtotal=validation.subtotal,
            discountAmount=validation.discountAmount,
            deliveryFee=validation.deliveryFee,
            total=validation.total,
            voucherCode=validation.voucherCode,
            items=[self._to_checkout_item_response(item) for item in items],
            message=(
                "Đơn hàng đã được tạo. Vui lòng hoàn tất chuyển khoản."
                if payload.paymentMethod == PAYMENT_BANK_TRANSFER
                else "Đơn hàng đã được tạo. Thanh toán khi nhận hàng."
            ),
            timeline=timeline,
            invoiceHtml=invoice_html,
            bankTransferInfo=self._bank_transfer_info()
            if payload.paymentMethod == PAYMENT_BANK_TRANSFER
            else None,
            paymentGateway=self._payment_gateway(payload.paymentMethod),
            paymentActionUrl=self._payment_action_url(order_id, payload.paymentMethod),
            canCancel=self._can_cancel_by_values(order_status, payment_status),
            canConfirmTransfer=self._can_confirm_transfer_by_values(
                payload.paymentMethod,
                payment_status,
            ),
            canRequestRefund=self._can_request_refund_by_values(
                order_status,
                payment_status,
            ),
        )

    async def list_orders(self, user: UserResponse) -> list[OrderSummaryResponse]:
        orders = await self._order_repository.list_orders_by_user_id(user.id)
        return [self._to_order_summary_response(document) for document in orders]

    async def get_order_detail(
        self,
        user: UserResponse,
        order_id: str,
    ) -> OrderDetailResponse:
        document = await self._order_repository.get_order_by_user_and_order_id(user.id, order_id)
        if document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        return self._to_order_detail_response(document)

    async def confirm_bank_transfer(
        self,
        user: UserResponse,
        order_id: str,
    ) -> OrderDetailResponse:
        document = await self._order_repository.get_order_by_user_and_order_id(user.id, order_id)
        if document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        payment_method = str(document.get("paymentMethod") or "").strip()
        payment_status = str(document.get("paymentStatus") or "").strip()
        if not self._can_confirm_transfer_by_values(payment_method, payment_status):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Đơn hàng này không thể xác nhận chuyển khoản.",
            )
        next_order_status = ORDER_STATUS_PROCESSING
        next_payment_status = PAYMENT_STATUS_PAID
        updated = await self._update_order_with_timeline(
            order_id=order_id,
            updates={
                "status": next_order_status,
                "paymentStatus": next_payment_status,
            },
            timeline_code="confirmed_transfer",
            timeline_title="Đã xác nhận chuyển khoản",
            timeline_description="Khách hàng đã xác nhận chuyển khoản và đơn đang được xử lý.",
        )
        return self._to_order_detail_response(updated)

    async def cancel_order(
        self,
        user: UserResponse,
        order_id: str,
    ) -> OrderDetailResponse:
        document = await self._order_repository.get_order_by_user_and_order_id(user.id, order_id)
        if document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        order_status = str(document.get("status") or "").strip()
        payment_status = str(document.get("paymentStatus") or "").strip()
        if not self._can_cancel_by_values(order_status, payment_status):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Đơn hàng này không thể hủy.",
            )
        await self._admin_repository.restore_ingredients_for_reference(
            reference_type="order",
            reference_id=order_id,
            restore_reference_type="order_cancel",
            restore_reference_id=order_id,
            note="Hoàn kho do hủy đơn hàng",
        )
        if document.get("voucherCode"):
            await self._user_repository.release_used_voucher(
                user.id,
                str(document.get("voucherCode") or ""),
            )
        next_payment_status = (
            PAYMENT_STATUS_REFUNDED
            if payment_status == PAYMENT_STATUS_PAID
            else PAYMENT_STATUS_CANCELLED
        )
        updated = await self._update_order_with_timeline(
            order_id=order_id,
            updates={
                "status": ORDER_STATUS_CANCELLED,
                "paymentStatus": next_payment_status,
            },
            timeline_code="cancelled",
            timeline_title="Đã hủy đơn",
            timeline_description="Khách hàng đã hủy đơn hàng.",
        )
        return self._to_order_detail_response(updated)

    async def request_refund(
        self,
        user: UserResponse,
        order_id: str,
    ) -> OrderDetailResponse:
        document = await self._order_repository.get_order_by_user_and_order_id(user.id, order_id)
        if document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        order_status = str(document.get("status") or "").strip()
        payment_status = str(document.get("paymentStatus") or "").strip()
        if not self._can_request_refund_by_values(order_status, payment_status):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Đơn hàng này chưa đủ điều kiện yêu cầu hoàn tiền.",
            )
        updated = await self._update_order_with_timeline(
            order_id=order_id,
            updates={
                "status": ORDER_STATUS_REFUND_PENDING,
                "paymentStatus": PAYMENT_STATUS_REFUND_PENDING,
            },
            timeline_code="refund_pending",
            timeline_title="Yêu cầu hoàn tiền",
            timeline_description="Hệ thống đã ghi nhận yêu cầu hoàn tiền của khách hàng.",
        )
        return self._to_order_detail_response(updated)

    async def _resolve_target_user(
        self,
        user: UserResponse,
        customer_user_id: Optional[str],
    ) -> UserResponse:
        if not user.isAdmin:
            return user
        target_user_id = (customer_user_id or "").strip()
        if not target_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin cần chọn khách hàng để tạo đơn.",
            )
        target_user_document = await self._user_repository.get_non_admin_user_by_id(target_user_id)
        if target_user_document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy khách hàng hợp lệ.",
            )
        return UserResponse(
            id=str(target_user_document.get("id") or ""),
            fullName=str(target_user_document.get("fullName") or ""),
            email=str(target_user_document.get("email") or ""),
            phone=target_user_document.get("phone"),
            address=target_user_document.get("address"),
            isAdmin=bool(target_user_document.get("isAdmin", False)),
        )

    async def _apply_voucher(
        self,
        *,
        target_user_id: str,
        voucher_code: str,
        subtotal: int,
        delivery_fee: int,
    ) -> tuple[str, int, int]:
        normalized_code = voucher_code.upper().strip()
        user_document = await self._user_repository.get_user_by_id(target_user_id)
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

        voucher = await self._voucher_repository.get_voucher_by_code(normalized_code)
        if voucher is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voucher không tồn tại.",
            )
        if subtotal < voucher.get("minOrderValue", 0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Đơn hàng chưa đạt điều kiện áp dụng voucher.",
            )

        discount_amount = 0
        next_delivery_fee = delivery_fee
        if voucher["discountType"] == "shipping":
            discount_amount = min(delivery_fee, voucher["discountValue"])
            next_delivery_fee = max(0, delivery_fee - discount_amount)
        elif voucher["discountType"] == "percent":
            discount_amount = subtotal * voucher["discountValue"] // 100

        return normalized_code, next_delivery_fee, discount_amount

    def _normalize_items(self, raw_items: list[dict]) -> list[dict]:
        normalized: list[dict] = []
        for item in raw_items:
            quantity = max(1, int(item.get("quantity") or 1))
            price_value = max(0, int(item.get("priceValue") or 0))
            normalized.append(
                {
                    "productId": int(item.get("productId") or 0),
                    "title": str(item.get("title") or ""),
                    "priceValue": price_value,
                    "quantity": quantity,
                    "lineTotal": price_value * quantity,
                    "category": item.get("category"),
                    "imageUrl": item.get("imageUrl"),
                    "price": item.get("price"),
                    "variantKey": item.get("variantKey"),
                    "variantLabel": item.get("variantLabel"),
                    "boxItems": [
                        {
                            "productId": int(box_item.get("productId") or 0),
                            "title": str(box_item.get("title") or ""),
                            "variantLabel": str(box_item.get("variantLabel") or ""),
                            "price": str(box_item.get("price") or ""),
                            "priceValue": int(box_item.get("priceValue") or 0),
                            "imageUrl": box_item.get("imageUrl"),
                        }
                        for box_item in (item.get("boxItems") or [])
                    ],
                }
            )
        return normalized

    def _merge_items(self, remote_items: list[dict], local_items: list[dict]) -> list[dict]:
        by_product: dict[str, dict] = {}
        for item in remote_items:
            product_id = int(item.get("productId") or 0)
            if product_id <= 0:
                continue
            identity_key = self._item_identity_key(item)
            by_product[identity_key] = dict(item)
        for item in local_items:
            product_id = int(item.get("productId") or 0)
            if product_id <= 0:
                continue
            identity_key = self._item_identity_key(item)
            existing = by_product.get(identity_key)
            if existing is None:
                by_product[identity_key] = {
                    **item,
                    "quantity": max(1, int(item.get("quantity") or 1)),
                    "lineTotal": int(item.get("priceValue") or 0) * max(1, int(item.get("quantity") or 1)),
                }
                continue
            next_quantity = int(existing.get("quantity") or 0) + max(1, int(item.get("quantity") or 1))
            by_product[identity_key] = {
                **existing,
                "quantity": next_quantity,
                "lineTotal": int(existing.get("priceValue") or 0) * next_quantity,
            }
        return sorted(
            by_product.values(),
            key=lambda item: (
                int(item.get("productId") or 0),
                str(item.get("variantKey") or ""),
            ),
        )

    def _build_cart_response(self, items: list[dict]) -> CartResponse:
        return CartResponse(
            items=[self._to_checkout_item_response(item) for item in items],
            itemCount=sum(int(item.get("quantity") or 0) for item in items),
            subtotal=sum(int(item.get("lineTotal") or 0) for item in items),
        )

    def _item_identity_key(self, item: dict) -> str:
        return f"{int(item.get('productId') or 0)}::{str(item.get('variantKey') or 'default')}"

    def _to_checkout_item_response(self, item: dict) -> CheckoutItemResponse:
        return CheckoutItemResponse(
            productId=int(item.get("productId") or 0),
            title=str(item.get("title") or ""),
            priceValue=int(item.get("priceValue") or 0),
            quantity=int(item.get("quantity") or 0),
            lineTotal=int(item.get("lineTotal") or 0),
            category=item.get("category"),
            imageUrl=item.get("imageUrl"),
            price=item.get("price"),
            variantKey=item.get("variantKey"),
            variantLabel=item.get("variantLabel"),
            boxItems=[
                {
                    "productId": int(box_item.get("productId") or 0),
                    "title": str(box_item.get("title") or ""),
                    "variantLabel": str(box_item.get("variantLabel") or ""),
                    "price": str(box_item.get("price") or ""),
                    "priceValue": int(box_item.get("priceValue") or 0),
                    "imageUrl": box_item.get("imageUrl"),
                }
                for box_item in (item.get("boxItems") or [])
            ],
        )

    def _build_order_timeline(
        self,
        payment_method: str,
        created_at: str,
    ) -> list[OrderTimelineEntryResponse]:
        timeline = [
            OrderTimelineEntryResponse(
                code="created",
                title="Đơn hàng đã tạo",
                description="Hệ thống đã ghi nhận đơn hàng của bạn.",
                createdAt=created_at,
            ),
        ]
        if payment_method == PAYMENT_BANK_TRANSFER:
            timeline.append(
                OrderTimelineEntryResponse(
                    code="awaiting_transfer",
                    title="Chờ chuyển khoản",
                    description="Đơn hàng đang chờ xác nhận chuyển khoản.",
                    createdAt=created_at,
                )
            )
        else:
            timeline.append(
                OrderTimelineEntryResponse(
                    code="pending_cod",
                    title="Thanh toán khi nhận hàng",
                    description="Đơn hàng sẽ được thanh toán theo hình thức COD khi nhận hàng.",
                    createdAt=created_at,
                )
            )
        return timeline

    def _initial_order_status(self, payment_method: str) -> str:
        if payment_method == PAYMENT_BANK_TRANSFER:
            return ORDER_STATUS_PENDING
        return ORDER_STATUS_PROCESSING

    def _initial_payment_status(self, payment_method: str) -> str:
        if payment_method == PAYMENT_BANK_TRANSFER:
            return PAYMENT_STATUS_AWAITING_TRANSFER
        return PAYMENT_STATUS_PENDING_COD

    def _payment_gateway(self, payment_method: str) -> Optional[str]:
        if payment_method == PAYMENT_BANK_TRANSFER:
            return "manual_bank_transfer"
        return None

    def _payment_action_url(self, order_id: Optional[str], payment_method: str) -> Optional[str]:
        if payment_method != PAYMENT_BANK_TRANSFER or not order_id:
            return None
        return f"/orders-detail?id={order_id}"

    def _can_cancel_by_values(self, order_status: str, payment_status: str) -> bool:
        normalized_order = order_status.strip().lower()
        normalized_payment = payment_status.strip().lower()
        return (
            normalized_order in {ORDER_STATUS_PENDING, ORDER_STATUS_PROCESSING}
            and normalized_payment
            not in {
                PAYMENT_STATUS_CANCELLED,
                PAYMENT_STATUS_REFUND_PENDING,
                PAYMENT_STATUS_REFUNDED,
            }
        )

    def _can_confirm_transfer_by_values(
        self,
        payment_method: str,
        payment_status: str,
    ) -> bool:
        return (
            payment_method == PAYMENT_BANK_TRANSFER
            and payment_status.strip().lower() == PAYMENT_STATUS_AWAITING_TRANSFER
        )

    def _can_request_refund_by_values(self, order_status: str, payment_status: str) -> bool:
        normalized_order = order_status.strip().lower()
        normalized_payment = payment_status.strip().lower()
        return (
            normalized_payment == PAYMENT_STATUS_PAID
            and normalized_order
            in {
                ORDER_STATUS_PROCESSING,
                ORDER_STATUS_SHIPPING,
                ORDER_STATUS_DELIVERED,
                ORDER_STATUS_COMPLETED,
            }
        )

    async def _update_order_with_timeline(
        self,
        *,
        order_id: str,
        updates: dict,
        timeline_code: str,
        timeline_title: str,
        timeline_description: str,
    ) -> dict:
        document = await self._order_repository.get_order_by_order_id(order_id)
        if document is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        next_timeline = list(document.get("timeline", []))
        next_timeline.append(
            {
                "code": timeline_code,
                "title": timeline_title,
                "description": timeline_description,
                "createdAt": datetime.now(timezone.utc).isoformat(),
            }
        )
        updated = await self._order_repository.update_order(
            order_id,
            {
                **updates,
                "timeline": next_timeline,
            },
        )
        if updated is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy đơn hàng.",
            )
        return updated

    def _to_order_summary_response(self, document: dict) -> OrderSummaryResponse:
        return OrderSummaryResponse(
            orderId=(document.get("orderId") or "").strip(),
            status=(document.get("status") or "").strip(),
            paymentMethod=(document.get("paymentMethod") or "").strip(),
            paymentStatus=(document.get("paymentStatus") or "").strip(),
            itemCount=int(document.get("itemCount") or 0),
            subtotal=int(document.get("subtotal") or 0),
            discountAmount=int(document.get("discountAmount") or 0),
            deliveryFee=int(document.get("deliveryFee") or 0),
            total=int(document.get("total") or 0),
            voucherCode=document.get("voucherCode"),
            createdAt=(document.get("createdAt") or "").strip(),
        )

    def _to_order_detail_response(self, document: dict) -> OrderDetailResponse:
        payment_method = (document.get("paymentMethod") or "").strip()
        payment_status = (document.get("paymentStatus") or "").strip()
        order_status = (document.get("status") or "").strip()
        return OrderDetailResponse(
            orderId=(document.get("orderId") or "").strip(),
            customerName=(document.get("customerName") or "").strip(),
            customerEmail=(document.get("customerEmail") or "").strip(),
            customerPhone=document.get("customerPhone"),
            customerAddress=document.get("customerAddress"),
            status=order_status,
            paymentMethod=payment_method,
            paymentStatus=payment_status,
            itemCount=int(document.get("itemCount") or 0),
            subtotal=int(document.get("subtotal") or 0),
            discountAmount=int(document.get("discountAmount") or 0),
            deliveryFee=int(document.get("deliveryFee") or 0),
            total=int(document.get("total") or 0),
            voucherCode=document.get("voucherCode"),
            orderNote=document.get("orderNote"),
            deliveryDate=document.get("deliveryDate"),
            deliveryTimeSlot=document.get("deliveryTimeSlot"),
            createdAt=(document.get("createdAt") or "").strip(),
            items=[
                OrderDetailItemResponse(
                    productId=int(item.get("productId") or 0),
                    title=(item.get("title") or "").strip(),
                    priceValue=int(item.get("priceValue") or 0),
                    quantity=int(item.get("quantity") or 0),
                    lineTotal=int(item.get("lineTotal") or 0),
                    category=item.get("category"),
                    imageUrl=item.get("imageUrl"),
                    price=item.get("price"),
                    variantKey=item.get("variantKey"),
                    variantLabel=item.get("variantLabel"),
                )
                for item in document.get("items", [])
            ],
            timeline=[
                OrderTimelineEntryResponse(
                    code=str(entry.get("code") or ""),
                    title=str(entry.get("title") or ""),
                    description=str(entry.get("description") or ""),
                    createdAt=str(entry.get("createdAt") or ""),
                )
                for entry in document.get("timeline", [])
            ],
            invoiceHtml=self._build_invoice_html(
                order_id=(document.get("orderId") or "").strip(),
                customer_name=(document.get("customerName") or "").strip(),
                customer_email=(document.get("customerEmail") or "").strip(),
                customer_phone=document.get("customerPhone"),
                customer_address=document.get("customerAddress"),
                items=document.get("items", []),
                subtotal=int(document.get("subtotal") or 0),
                discount_amount=int(document.get("discountAmount") or 0),
                delivery_fee=int(document.get("deliveryFee") or 0),
                total=int(document.get("total") or 0),
                payment_method=payment_method,
                created_at=(document.get("createdAt") or "").strip(),
            ),
            bankTransferInfo=self._bank_transfer_info()
            if payment_method == PAYMENT_BANK_TRANSFER
            else None,
            paymentGateway=self._payment_gateway(payment_method),
            paymentActionUrl=self._payment_action_url(
                (document.get("orderId") or "").strip(),
                payment_method,
            ),
            canCancel=self._can_cancel_by_values(order_status, payment_status),
            canConfirmTransfer=self._can_confirm_transfer_by_values(
                payment_method,
                payment_status,
            ),
            canRequestRefund=self._can_request_refund_by_values(
                order_status,
                payment_status,
            ),
        )

    def _bank_transfer_info(self) -> BankTransferInfoResponse:
        return BankTransferInfoResponse(
            bankName="Vietcombank",
            accountName="PIXEL BAKERY",
            accountNumber="0123456789",
            transferNotePrefix="PIXELBAKERY",
        )

    def _payment_method_label(self, payment_method: str) -> str:
        if payment_method == PAYMENT_BANK_TRANSFER:
            return "Chuyển khoản ngân hàng"
        return "Thanh toán khi nhận hàng (COD)"

    def _build_invoice_html(
        self,
        *,
        order_id: str,
        customer_name: str,
        customer_email: str,
        customer_phone: Optional[str],
        customer_address: Optional[str],
        items: list[dict],
        subtotal: int,
        discount_amount: int,
        delivery_fee: int,
        total: int,
        payment_method: str,
        created_at: str,
    ) -> str:
        rows = "".join(
            f"<tr><td>{item.get('title') or ''}</td><td>{int(item.get('quantity') or 0)}</td><td>{self._format_currency(int(item.get('priceValue') or 0))}</td><td>{self._format_currency(int(item.get('lineTotal') or 0))}</td></tr>"
            for item in items
        )
        return f"""
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>Hoa don {order_id}</title>
  <style>
    body {{ font-family: Arial, sans-serif; padding: 24px; color: #111827; }}
    h1 {{ margin: 0 0 8px; }}
    table {{ width: 100%; border-collapse: collapse; margin-top: 16px; }}
    th, td {{ border: 1px solid #d1d5db; padding: 8px; text-align: left; }}
    .summary {{ margin-top: 16px; }}
  </style>
</head>
<body>
  <h1>Pixel Bakery</h1>
  <p>Ma don: <strong>{order_id}</strong></p>
  <p>Ngay tao: {created_at}</p>
  <p>Khach hang: {customer_name} - {customer_email}</p>
  <p>Dien thoai: {customer_phone or ''}</p>
  <p>Dia chi: {customer_address or ''}</p>
  <p>Thanh toan: {self._payment_method_label(payment_method)}</p>
  <table>
    <thead>
      <tr><th>San pham</th><th>SL</th><th>Don gia</th><th>Thanh tien</th></tr>
    </thead>
    <tbody>{rows}</tbody>
  </table>
  <div class="summary">
    <p>Tam tinh: {self._format_currency(subtotal)}</p>
    <p>Giam gia: {self._format_currency(discount_amount)}</p>
    <p>Phi giao hang: {self._format_currency(delivery_fee)}</p>
    <p><strong>Tong cong: {self._format_currency(total)}</strong></p>
  </div>
</body>
</html>
""".strip()

    def _format_currency(self, value: int) -> str:
        return f"{value:,}đ".replace(",", ".")


def get_checkout_service(
    order_repository: OrderRepository = Depends(get_order_repository),
    user_repository: UserRepository = Depends(get_user_repository),
    voucher_repository: VoucherRepository = Depends(get_voucher_repository),
    admin_repository: AdminRepository = Depends(get_admin_repository),
    cart_repository: CartRepository = Depends(get_cart_repository),
) -> CheckoutService:
    return CheckoutService(
        order_repository,
        user_repository,
        voucher_repository,
        admin_repository,
        cart_repository,
    )
