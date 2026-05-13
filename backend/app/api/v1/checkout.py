from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from fastapi.responses import HTMLResponse

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


@router.get("/orders/{order_id}/invoice", response_class=HTMLResponse)
async def get_order_invoice(
    order_id: str,
    user: UserResponse = Depends(_require_current_user),
    checkout_service: CheckoutService = Depends(get_checkout_service),
) -> HTMLResponse:
    order = await checkout_service.get_order_detail(user, order_id)
    html = _build_invoice_html(order)
    return HTMLResponse(content=html)


def _fmt(amount: int) -> str:
    return f"{amount:,}đ".replace(",", ".")


def _build_invoice_html(order: OrderDetailResponse) -> str:
    rows = ""
    for item in order.items:
        rows += f"""
        <tr>
          <td>{item.title}{f'<br><small style="color:#888">{item.variantLabel}</small>' if item.variantLabel else ''}</td>
          <td style="text-align:center">{item.quantity}</td>
          <td style="text-align:right">{_fmt(item.priceValue)}</td>
          <td style="text-align:right">{_fmt(item.lineTotal)}</td>
        </tr>"""

    payment_map = {"cod": "Thanh toán khi nhận hàng", "bank_transfer": "Chuyển khoản ngân hàng"}
    payment_label = payment_map.get(order.paymentMethod, order.paymentMethod)

    return f"""<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Hóa đơn {order.orderId}</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: 'Segoe UI', sans-serif; color: #111; padding: 32px; max-width: 720px; margin: auto; }}
  .header {{ display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px; }}
  .brand {{ font-size: 26px; font-weight: 900; color: #E53935; letter-spacing: 1px; }}
  .brand small {{ display: block; font-size: 12px; font-weight: 400; color: #888; margin-top: 2px; }}
  .invoice-title {{ text-align: right; }}
  .invoice-title h2 {{ font-size: 20px; font-weight: 700; color: #1E88E5; }}
  .invoice-title p {{ font-size: 12px; color: #888; margin-top: 4px; }}
  .info-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; }}
  .info-box {{ background: #f8f8f8; border-radius: 8px; padding: 14px; }}
  .info-box h4 {{ font-size: 11px; text-transform: uppercase; color: #888; margin-bottom: 8px; letter-spacing: 0.5px; }}
  .info-box p {{ font-size: 13px; line-height: 1.6; }}
  table {{ width: 100%; border-collapse: collapse; margin-bottom: 16px; }}
  thead {{ background: #E53935; color: white; }}
  thead th {{ padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 700; }}
  tbody tr:nth-child(even) {{ background: #fafafa; }}
  tbody td {{ padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #eee; vertical-align: top; }}
  .totals {{ margin-left: auto; width: 280px; }}
  .totals-row {{ display: flex; justify-content: space-between; padding: 6px 0; font-size: 13px; border-bottom: 1px solid #eee; }}
  .totals-row.total {{ font-weight: 900; font-size: 16px; color: #E53935; border-bottom: none; padding-top: 10px; }}
  .footer {{ margin-top: 40px; text-align: center; font-size: 11px; color: #aaa; }}
  @media print {{
    body {{ padding: 16px; }}
    .no-print {{ display: none; }}
  }}
</style>
</head>
<body>
<div class="header">
  <div class="brand">🍞 Pixel Bakery<small>pixelbakery.vn</small></div>
  <div class="invoice-title">
    <h2>HÓA ĐƠN</h2>
    <p>#{order.orderId}</p>
    <p>{order.createdAt[:10] if order.createdAt else ''}</p>
  </div>
</div>

<div class="info-grid">
  <div class="info-box">
    <h4>Khách hàng</h4>
    <p><strong>{order.customerName}</strong><br>
    {order.customerEmail}<br>
    {order.customerPhone or ''}<br>
    {order.customerAddress or ''}</p>
  </div>
  <div class="info-box">
    <h4>Thông tin đơn hàng</h4>
    <p>Thanh toán: {payment_label}<br>
    Trạng thái TT: {order.paymentStatus}<br>
    Trạng thái đơn: {order.status}</p>
  </div>
</div>

<table>
  <thead>
    <tr>
      <th>Sản phẩm</th>
      <th style="text-align:center">SL</th>
      <th style="text-align:right">Đơn giá</th>
      <th style="text-align:right">Thành tiền</th>
    </tr>
  </thead>
  <tbody>{rows}</tbody>
</table>

<div class="totals">
  <div class="totals-row"><span>Tạm tính</span><span>{_fmt(order.subtotal)}</span></div>
  <div class="totals-row"><span>Phí giao hàng</span><span>{_fmt(order.deliveryFee)}</span></div>
  {'<div class="totals-row"><span>Giảm giá</span><span>-' + _fmt(order.discountAmount) + '</span></div>' if order.discountAmount else ''}
  <div class="totals-row total"><span>Tổng cộng</span><span>{_fmt(order.total)}</span></div>
</div>

<div class="footer">
  <p>Cảm ơn bạn đã ủng hộ Pixel Bakery! ❤️</p>
  <p style="margin-top:4px">Mọi thắc mắc vui lòng liên hệ: support@pixelbakery.vn</p>
</div>

<div class="no-print" style="margin-top:32px; text-align:center">
  <button onclick="window.print()" style="padding:10px 28px;background:#E53935;color:white;border:none;border-radius:6px;font-size:14px;font-weight:700;cursor:pointer">
    🖨️ In / Lưu PDF
  </button>
</div>
</body>
</html>"""


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
