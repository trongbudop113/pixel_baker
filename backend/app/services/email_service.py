import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import aiosmtplib

from app.core.config import settings

logger = logging.getLogger("pixel_bakery.email")


async def _send(to_email: str, subject: str, html: str) -> None:
    if not settings.smtp_user or not settings.smtp_password:
        logger.warning("SMTP not configured — skipping email to %s", to_email)
        return
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{settings.smtp_from_name} <{settings.smtp_user}>"
    msg["To"] = to_email
    msg.attach(MIMEText(html, "html", "utf-8"))
    try:
        await aiosmtplib.send(
            msg,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_user,
            password=settings.smtp_password,
            start_tls=True,
        )
        logger.info("Email sent to %s — %s", to_email, subject)
    except Exception as exc:
        logger.error("Failed to send email to %s: %s", to_email, exc)


def _fmt(amount: int) -> str:
    return f"{amount:,}đ".replace(",", ".")


def _base(content: str) -> str:
    return f"""
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body{{font-family:'Segoe UI',Arial,sans-serif;background:#f4f4f4;margin:0;padding:0}}
  .wrap{{max-width:560px;margin:32px auto;background:#fff;border-radius:10px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08)}}
  .header{{background:#E53935;padding:24px 32px;text-align:center}}
  .header h1{{color:#fff;margin:0;font-size:22px;letter-spacing:1px}}
  .header p{{color:rgba(255,255,255,.85);margin:4px 0 0;font-size:13px}}
  .body{{padding:28px 32px}}
  .footer{{background:#f8f8f8;padding:16px 32px;text-align:center;font-size:11px;color:#aaa;border-top:1px solid #eee}}
  .badge{{display:inline-block;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:700}}
  .btn{{display:inline-block;background:#E53935;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:700;font-size:14px;margin:16px 0}}
  table{{width:100%;border-collapse:collapse;margin:12px 0}}
  th{{background:#f8f8f8;padding:8px 12px;text-align:left;font-size:12px;color:#888;border-bottom:2px solid #eee}}
  td{{padding:8px 12px;font-size:13px;border-bottom:1px solid #f0f0f0}}
  .total-row td{{font-weight:700;font-size:14px;color:#E53935;border-bottom:none}}
  h2{{color:#1E88E5;font-size:18px;margin:0 0 8px}}
  p{{color:#444;font-size:14px;line-height:1.6;margin:8px 0}}
</style>
</head>
<body>
<div class="wrap">
  <div class="header">
    <h1>🍞 PIXEL BAKERY</h1>
    <p>Bánh ngọt thủ công • Giao hàng tận nơi</p>
  </div>
  <div class="body">{content}</div>
  <div class="footer">
    © Pixel Bakery | <a href="https://trongbudop113.github.io/pixel_baker/" style="color:#1E88E5">pixelbakery.vn</a><br>
    Mọi thắc mắc: {settings.smtp_user}
  </div>
</div>
</body>
</html>"""


async def send_order_placed(
    to_email: str,
    customer_name: str,
    order_id: str,
    items: list,
    subtotal: int,
    delivery_fee: int,
    discount: int,
    total: int,
    payment_method: str,
    delivery_date: str | None = None,
    order_note: str | None = None,
) -> None:
    payment_label = "Thanh toán khi nhận hàng" if payment_method == "cod" else "Chuyển khoản ngân hàng"
    rows = "".join(
        f"<tr><td>{i.get('title','')}</td><td style='text-align:center'>{i.get('quantity',1)}</td>"
        f"<td style='text-align:right'>{_fmt(i.get('lineTotal',0))}</td></tr>"
        for i in items
    )
    extra = ""
    if delivery_date:
        extra += f"<p><strong>📅 Ngày giao:</strong> {delivery_date}</p>"
    if order_note:
        extra += f"<p><strong>📝 Ghi chú:</strong> {order_note}</p>"

    content = f"""
<h2>Xác nhận đặt hàng thành công! 🎉</h2>
<p>Xin chào <strong>{customer_name}</strong>,</p>
<p>Cảm ơn bạn đã đặt hàng tại Pixel Bakery. Chúng mình đã nhận được đơn của bạn và đang chuẩn bị ngay.</p>
<p><strong>Mã đơn hàng:</strong> <span style="color:#1E88E5;font-weight:700">#{order_id}</span></p>
<p><strong>Phương thức thanh toán:</strong> {payment_label}</p>
{extra}
<table>
  <thead><tr><th>Sản phẩm</th><th style="text-align:center">SL</th><th style="text-align:right">Thành tiền</th></tr></thead>
  <tbody>{rows}</tbody>
</table>
<table>
  <tr><td>Tạm tính</td><td style="text-align:right">{_fmt(subtotal)}</td></tr>
  {'<tr><td>Giảm giá</td><td style="text-align:right">-' + _fmt(discount) + '</td></tr>' if discount else ''}
  <tr><td>Phí giao hàng</td><td style="text-align:right">{_fmt(delivery_fee)}</td></tr>
  <tr class="total-row"><td><strong>Tổng cộng</strong></td><td style="text-align:right"><strong>{_fmt(total)}</strong></td></tr>
</table>
<p>Bạn có thể theo dõi đơn hàng tại:</p>
<a href="https://trongbudop113.github.io/pixel_baker/#/orders-detail" class="btn">Theo dõi đơn hàng →</a>
<p style="color:#888;font-size:12px">Nếu có thắc mắc, reply email này hoặc liên hệ fanpage Pixel Bakery.</p>"""

    await _send(to_email, f"✅ Đặt hàng thành công #{order_id} — Pixel Bakery", _base(content))


async def send_order_status_changed(
    to_email: str,
    customer_name: str,
    order_id: str,
    new_status: str,
    points_earned: int = 0,
) -> None:
    status_map = {
        "processing": ("🔄 Đang xử lý", "#1E88E5", "Đơn hàng của bạn đang được chuẩn bị. Chúng mình sẽ liên hệ trước khi giao nhé!"),
        "shipping":   ("🚗 Đang giao hàng", "#D97706", "Bánh đang trên đường đến bạn rồi! Vui lòng để ý điện thoại."),
        "delivered":  ("📦 Đã giao hàng", "#00A86B", "Bánh đã được giao. Chúc bạn ngon miệng! 🎂"),
        "completed":  ("✅ Hoàn tất", "#00A86B", "Cảm ơn bạn đã tin tưởng Pixel Bakery. Hẹn gặp lại!"),
        "cancelled":  ("❌ Đã hủy", "#E53935", "Đơn hàng của bạn đã được hủy. Nếu có vấn đề, hãy liên hệ chúng mình nhé."),
    }
    label, color, message = status_map.get(new_status, ("📋 Cập nhật", "#888", "Đơn hàng của bạn đã được cập nhật."))
    points_html = f'<p style="color:#D97706"><strong>⭐ +{points_earned} điểm tích lũy</strong> đã được cộng vào tài khoản!</p>' if points_earned > 0 else ""

    content = f"""
<h2>Cập nhật đơn hàng #{order_id}</h2>
<p>Xin chào <strong>{customer_name}</strong>,</p>
<p>Trạng thái đơn hàng của bạn vừa được cập nhật:</p>
<p><span class="badge" style="background:{color}20;color:{color}">{label}</span></p>
<p>{message}</p>
{points_html}
<a href="https://trongbudop113.github.io/pixel_baker/#/orders-detail" class="btn">Xem chi tiết đơn →</a>"""

    subject_map = {
        "processing": f"🔄 Đơn #{order_id} đang được xử lý",
        "shipping":   f"🚗 Đơn #{order_id} đang giao hàng",
        "delivered":  f"📦 Đơn #{order_id} đã giao thành công",
        "completed":  f"✅ Đơn #{order_id} hoàn tất",
        "cancelled":  f"❌ Đơn #{order_id} đã hủy",
    }
    subject = subject_map.get(new_status, f"Cập nhật đơn hàng #{order_id}") + " — Pixel Bakery"
    await _send(to_email, subject, _base(content))
