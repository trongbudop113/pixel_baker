import json
from datetime import datetime, timedelta, timezone
import math
from uuid import uuid4
from typing import Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.auth import AuthPageResponse
from app.models.admin import (
    AdminOrderAdvanceCheckResponse,
    AdminOrderIngredientShortageResponse,
    AdminAlertResponse,
    AdminBulkImportResult,
    AdminContentDocumentResponse,
    AdminCustomerResponse,
    AdminCustomerExcelRow,
    AdminDashboardResponse,
    AdminIngredientExcelRow,
    AdminIngredientResponse,
    AdminInventoryTransactionResponse,
    AdminImportAuditLogResponse,
    AdminImportValidationError,
    AdminIngredientUpsertRequest,
    AdminIngredientUpdateRequest,
    AdminOrderExcelRow,
    AdminProductCostReportResponse,
    AdminRecipeCopyRequest,
    AdminRecipeCreateRequest,
    AdminRecipeExcelRow,
    AdminRecipeIngredientInput,
    AdminRecipeIngredientResponse,
    AdminRecipeOptionsResponse,
    AdminRecipeReferenceResponse,
    AdminOrderResponse,
    AdminProductExcelRow,
    AdminProductResponse,
    AdminRecipeResponse,
    AdminTestimonialResponse,
    AdminProductUpsertRequest,
    AdminRecentOrderResponse,
    AdminOrderStatusUpdateRequest,
    AdminProductUpdateRequest,
    AdminStatCardResponse,
    AdminTabSummaryResponse,
    AdminVoucherExcelRow,
    AdminVoucherResponse,
    AdminRevenueDayResponse,
    AdminRevenueSummaryResponse,
)
from app.core.security import hash_password
from app.models.contact import ContactPageResponse
from app.models.home import HomePageResponse
from app.models.story import StoryPageResponse


class AdminRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._orders = database["orders"]
        self._users = database["users"]
        self._products = database["menu_products"]
        self._ingredients = database["admin_ingredients"]
        self._recipes = database["admin_recipes"]
        self._inventory_transactions = database["inventory_transactions"]
        self._import_audit_logs = database["import_audit_logs"]
        self._vouchers = database["vouchers"]
        self._home_testimonials = database["home_testimonials"]
        self._home_pages = database["home_pages"]
        self._story_pages = database["story_pages"]
        self._contact_pages = database["contact_pages"]
        self._auth_pages = database["auth_pages"]

    async def get_dashboard(self) -> AdminDashboardResponse:
        now = datetime.now(timezone.utc)
        start_of_day = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
        previous_day = start_of_day - timedelta(days=1)

        recent_orders_docs = await self._orders.find({}).sort("createdAt", -1).to_list(length=20)
        user_docs = await self._users.find({}).to_list(length=500)
        product_docs = await self._products.find({}).to_list(length=500)
        ingredient_docs = await self._ingredients.find({}).to_list(length=500)

        revenue_today = 0
        new_orders_today = 0
        delayed_orders = 0
        cancelled_orders = 0
        sales_by_hour = [0, 0, 0, 0]

        for document in recent_orders_docs:
            created_at = self._parse_datetime(document.get("createdAt"))
            if created_at is not None and created_at >= start_of_day:
                revenue_today += int(document.get("total") or 0)
                new_orders_today += 1

                hours_since = (now - created_at).total_seconds() / 3600
                if hours_since <= 4:
                    bucket_index = min(3, max(0, int(hours_since)))
                    sales_by_hour[3 - bucket_index] += int(document.get("total") or 0)

            status = str(document.get("status") or "").lower()
            if status in {"cancelled", "failed"}:
                cancelled_orders += 1

            if created_at is not None:
                age_minutes = (now - created_at).total_seconds() / 60
                if age_minutes > 30 and status in {"paid", "pending", "processing"}:
                    delayed_orders += 1

        new_customers_today = 0
        admin_count = 0
        for user in user_docs:
            if user.get("isAdmin") is True:
                admin_count += 1
            created_at = self._parse_datetime(user.get("createdAt"))
            if created_at is not None and created_at >= start_of_day:
                new_customers_today += 1

        cancellation_rate = 0.0
        if recent_orders_docs:
            cancellation_rate = (cancelled_orders / len(recent_orders_docs)) * 100

        product_count = len(product_docs)
        out_of_stock_count = sum(
            1
            for product in product_docs
            if str(product.get("stockStatus") or "").strip().lower() != "còn hàng"
        )
        low_stock_ingredients = [
            ingredient
            for ingredient in ingredient_docs
            if self._ingredient_status(
                int(ingredient.get("availableQuantity") or 0),
                int(ingredient.get("lowStockThreshold") or 0),
            )
            != "Đủ hàng"
        ]

        recent_orders = [
            AdminRecentOrderResponse(
                orderId=str(document.get("orderId") or ""),
                total=int(document.get("total") or 0),
                status=self._status_label(str(document.get("status") or "")),
            )
            for document in recent_orders_docs[:5]
        ]

        alerts = []
        if out_of_stock_count > 0:
            alerts.append(
                AdminAlertResponse(
                    title="Cảnh báo tồn kho",
                    description=f"{out_of_stock_count} sản phẩm đang không ở trạng thái còn hàng.",
                    tone="danger",
                )
            )
        if low_stock_ingredients:
            alerts.append(
                AdminAlertResponse(
                    title="Nguyên liệu cần nhập thêm",
                    description=f"{len(low_stock_ingredients)} nguyên liệu đang ở mức sắp hết hoặc hết hàng.",
                    tone="warning",
                )
            )
        if delayed_orders > 0:
            alerts.append(
                AdminAlertResponse(
                    title="Đơn trễ xử lý",
                    description=f"{delayed_orders} đơn đã quá 30 phút chưa hoàn tất xử lý.",
                    tone="warning",
                )
            )
        if not alerts:
            alerts.append(
                AdminAlertResponse(
                    title="Hệ thống ổn định",
                    description="Hiện chưa có cảnh báo vận hành quan trọng.",
                    tone="info",
                )
            )

        stat_cards = [
            AdminStatCardResponse(
                label="Doanh thu hôm nay",
                value=self._format_currency(revenue_today),
                tone="default",
            ),
            AdminStatCardResponse(
                label="Đơn mới",
                value=str(new_orders_today),
                tone="default",
            ),
            AdminStatCardResponse(
                label="Khách mới",
                value=f"+{new_customers_today}",
                tone="success",
            ),
            AdminStatCardResponse(
                label="Tỷ lệ huỷ",
                value=f"{cancellation_rate:.1f}%",
                tone="danger",
            ),
        ]

        tab_summaries = [
            AdminTabSummaryResponse(
                title="Tab Đơn hàng",
                rows=[
                    f"• {new_orders_today} đơn mới trong hôm nay",
                    f"• {delayed_orders} đơn chậm xử lý cần theo dõi",
                    f"• {len(recent_orders_docs)} đơn đã ghi nhận trong hệ thống",
                ],
            ),
            AdminTabSummaryResponse(
                title="Tab Sản phẩm",
                rows=[
                    f"• {product_count} sản phẩm đang có trong menu",
                    f"• {out_of_stock_count} sản phẩm không ở trạng thái còn hàng",
                    "• Theo dõi tồn kho chi tiết sẽ được mở rộng ở phase sau",
                ],
            ),
            AdminTabSummaryResponse(
                title="Tab Khách hàng",
                rows=[
                    f"• {len(user_docs)} tài khoản đã đăng ký",
                    f"• {new_customers_today} khách mới trong hôm nay",
                    f"• {admin_count} tài khoản quản trị",
                ],
            ),
            AdminTabSummaryResponse(
                title="Tab Nguyên liệu",
                rows=[
                    f"• {len(ingredient_docs)} nguyên liệu đang được theo dõi",
                    f"• {len(low_stock_ingredients)} nguyên liệu cần nhập thêm",
                    f"• {sum(int(item.get('availableQuantity') or 0) for item in ingredient_docs)} đơn vị tồn kho khả dụng",
                    f"• Giá trị kho: {self._format_currency(sum(int(item.get('availableQuantity') or 0) * int(item.get('unitPrice') or 0) for item in ingredient_docs))}",
                ],
                buttonLabel="Xem kho",
                compact=True,
            ),
            AdminTabSummaryResponse(
                title="Tab Doanh số",
                rows=[
                    f"Doanh thu hôm nay: {self._format_currency(revenue_today)}",
                    f"So với hôm qua: {self._format_growth_label(revenue_today, previous_day, recent_orders_docs)}",
                ],
                buttonLabel="Xem báo cáo",
                compact=True,
            ),
        ]

        return AdminDashboardResponse(
            title="Dashboard Quản trị",
            notificationLabel=f"{len(alerts)} thông báo",
            statCards=stat_cards,
            recentOrders=recent_orders,
            alerts=alerts,
            salesByHour=sales_by_hour,
            topTrendLabel="Doanh số theo tab",
            topTrendValue="Đơn hàng dẫn đầu",
            tabSummaries=tab_summaries,
        )

    async def list_orders(self) -> list[AdminOrderResponse]:
        documents = await self._orders.find({}).sort("createdAt", -1).to_list(length=200)
        return [
            AdminOrderResponse(
                orderId=str(document.get("orderId") or ""),
                customerName=str(document.get("customerName") or ""),
                customerEmail=str(document.get("customerEmail") or ""),
                total=int(document.get("total") or 0),
                status=self._status_label(str(document.get("status") or "")),
                itemCount=int(document.get("itemCount") or 0),
                paymentMethod=str(document.get("paymentMethod") or ""),
                createdAt=str(document.get("createdAt") or ""),
            )
            for document in documents
        ]

    async def update_order_status(
        self,
        order_id: str,
        payload: AdminOrderStatusUpdateRequest,
    ) -> Optional[AdminOrderResponse]:
        normalized = self._normalize_status(payload.status)
        document = await self._orders.find_one({"orderId": order_id})
        if document is None:
            return None
        next_timeline = list(document.get("timeline", []))
        next_timeline.append(
            {
                "code": normalized,
                "title": self._timeline_title(normalized),
                "description": self._timeline_description(normalized),
                "createdAt": datetime.now(timezone.utc).isoformat(),
            }
        )
        await self._orders.update_one(
            {"orderId": order_id},
            {"$set": {"status": normalized, "timeline": next_timeline}},
        )
        document = await self._orders.find_one({"orderId": order_id})
        return AdminOrderResponse(
            orderId=str(document.get("orderId") or ""),
            customerName=str(document.get("customerName") or ""),
            customerEmail=str(document.get("customerEmail") or ""),
            total=int(document.get("total") or 0),
            status=self._status_label(str(document.get("status") or "")),
            itemCount=int(document.get("itemCount") or 0),
            paymentMethod=str(document.get("paymentMethod") or ""),
            createdAt=str(document.get("createdAt") or ""),
        )

    async def get_order_advance_check(self, order_id: str) -> Optional[AdminOrderAdvanceCheckResponse]:
        document = await self._orders.find_one({"orderId": order_id})
        if document is None:
            return None

        current_status = str(document.get("status") or "").strip().lower()
        next_status = self._next_order_status(current_status)
        if next_status is None:
            return AdminOrderAdvanceCheckResponse(
                orderId=order_id,
                currentStatus=self._status_label(current_status),
                nextStatus=self._status_label(current_status),
                requiresInventoryConfirmation=False,
                canAdvance=False,
                message="Đơn hàng này không còn bước xử lý tiếp theo.",
                shortages=[],
            )

        needs_inventory_check = next_status == "processing"
        shortages: list[dict] = []
        if needs_inventory_check:
            shortages = await self.validate_ingredients_for_order_items(
                list(document.get("items", []))
            )

        return AdminOrderAdvanceCheckResponse(
            orderId=order_id,
            currentStatus=self._status_label(current_status),
            nextStatus=self._status_label(next_status),
            requiresInventoryConfirmation=needs_inventory_check,
            canAdvance=True,
            message=(
                "Nguyên liệu hiện đang đủ để bắt đầu xử lý đơn."
                if not shortages
                else "Đơn hàng đang thiếu nguyên liệu. Admin cần xác nhận trước khi tiếp tục xử lý."
            ),
            shortages=[
                AdminOrderIngredientShortageResponse(
                    ingredientId=str(item.get("ingredientId") or ""),
                    ingredientName=str(item.get("ingredientName") or ""),
                    requiredQuantity=int(item.get("requiredQuantity") or 0),
                    availableQuantity=int(item.get("availableQuantity") or 0),
                    unit=str(item.get("unit") or ""),
                )
                for item in shortages
            ],
        )

    async def bulk_update_order_status(self, order_ids: list[str], status: str) -> int:
        normalized = self._normalize_status(status)
        now = datetime.now(timezone.utc).isoformat()
        result = await self._orders.update_many(
            {"orderId": {"$in": order_ids}},
            {
                "$set": {"status": normalized},
                "$push": {
                    "timeline": {
                        "code": normalized,
                        "title": self._timeline_title(normalized),
                        "description": self._timeline_description(normalized),
                        "createdAt": now,
                    }
                },
            },
        )
        return int(result.modified_count or 0)

    async def validate_ingredients_for_order_items(self, items: list[dict]) -> list[dict]:
        required_quantities = await self._resolve_required_quantities_for_order_items(items)

        if not required_quantities:
            return []

        ingredient_documents = await self._ingredients.find(
            {"id": {"$in": list(required_quantities.keys())}}
        ).to_list(length=500)
        ingredients_by_id = {
            str(document.get("id") or ""): document for document in ingredient_documents
        }

        shortages: list[dict] = []
        for ingredient_id, required in required_quantities.items():
            ingredient = ingredients_by_id.get(ingredient_id)
            if ingredient is None:
                shortages.append(
                    {
                        "ingredientId": ingredient_id,
                        "ingredientName": ingredient_id,
                        "requiredQuantity": required,
                        "availableQuantity": 0,
                        "unit": "",
                    }
                )
                continue
            factor = int(ingredient.get("conversionFactor") or self._normalize_unit(str(ingredient.get("unit") or ""))[1])
            available = int(ingredient.get("availableNormalizedQuantity") or int(ingredient.get("availableQuantity") or 0) * factor)
            if available < required:
                shortages.append(
                    {
                        "ingredientId": ingredient_id,
                        "ingredientName": str(ingredient.get("name") or ingredient_id),
                        "requiredQuantity": required,
                        "availableQuantity": available,
                        "unit": str(ingredient.get("standardUnit") or self._normalize_unit(str(ingredient.get("unit") or ""))[0]),
                    }
                )
        return shortages

    async def list_products(self) -> list[AdminProductResponse]:
        documents = await self._products.find({}).sort("id", 1).to_list(length=200)
        return [
            AdminProductResponse(
                id=int(document.get("id") or 0),
                title=str(document.get("title") or ""),
                category=str(document.get("category") or ""),
                priceValue=int(document.get("priceValue") or 0),
                stockStatus=str(document.get("stockStatus") or ""),
                imageUrl=((document.get("images") or [None])[0]),
            )
            for document in documents
        ]

    async def list_product_excel_rows(self) -> list[AdminProductExcelRow]:
        documents = await self._products.find({}).sort("id", 1).to_list(length=1000)
        return [
            AdminProductExcelRow(
                id=int(document.get("id") or 0),
                title=str(document.get("title") or ""),
                category=str(document.get("category") or ""),
                priceValue=int(document.get("priceValue") or 0),
                description=str(document.get("description") or ""),
                images=self._join_excel_list(document.get("images")),
                sku=str(document.get("sku") or ""),
                stockStatus=str(document.get("stockStatus") or ""),
                weight=str(document.get("weight") or ""),
                storageNote=str(document.get("storageNote") or ""),
                deliveryNote=str(document.get("deliveryNote") or ""),
                detailBullets=self._join_excel_list(document.get("detailBullets")),
            )
            for document in documents
        ]

    async def get_product(self, product_id: int) -> Optional[dict]:
        document = await self._products.find_one({"id": product_id})
        if document is None:
            return None
        cloned = dict(document)
        cloned.pop("_id", None)
        return cloned

    async def update_product(
        self,
        product_id: int,
        payload: AdminProductUpdateRequest,
    ) -> Optional[AdminProductResponse]:
        await self._products.update_one(
            {"id": product_id},
            {"$set": {"stockStatus": payload.stockStatus}},
        )
        document = await self._products.find_one({"id": product_id})
        if document is None:
            return None
        return AdminProductResponse(
            id=int(document.get("id") or 0),
            title=str(document.get("title") or ""),
            category=str(document.get("category") or ""),
            priceValue=int(document.get("priceValue") or 0),
            stockStatus=str(document.get("stockStatus") or ""),
        )

    async def bulk_update_product_stock(self, product_ids: list[int], stock_status: str) -> int:
        result = await self._products.update_many(
            {"id": {"$in": product_ids}},
            {"$set": {"stockStatus": stock_status}},
        )
        return int(result.modified_count or 0)

    async def create_product(
        self,
        payload: AdminProductUpsertRequest,
    ) -> dict:
        latest = await self._products.find_one(sort=[("id", -1)])
        next_id = int(latest.get("id") or 0) + 1 if latest else 1
        document = self._build_product_document(payload, product_id=next_id)
        await self._products.insert_one(document)
        created = await self._products.find_one({"id": next_id})
        if created is None:
            raise RuntimeError("Failed to create product.")
        created.pop("_id", None)
        return created

    async def import_products_from_excel(
        self,
        rows: list[AdminProductExcelRow],
    ) -> AdminBulkImportResult:
        latest = await self._products.find_one(sort=[("id", -1)])
        next_id = int(latest.get("id") or 0) + 1 if latest else 1
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []

        for index, row in enumerate(rows, start=2):
            if not row.title.strip():
                errors.append(self._import_error(index, "title", "Tên sản phẩm là bắt buộc.", row.title))
                continue
            if int(row.priceValue or 0) <= 0:
                errors.append(self._import_error(index, "priceValue", "Giá bán phải lớn hơn 0.", str(row.priceValue)))
                continue
            payload = self._product_payload_from_excel_row(row)
            existing = None
            target_id = int(row.id or 0) if row.id is not None else 0
            if target_id > 0:
                existing = await self._products.find_one({"id": target_id})
            if existing is None and row.sku.strip():
                existing = await self._products.find_one({"sku": row.sku.strip()})

            if existing is not None:
                target_id = int(existing.get("id") or 0)
                document = self._build_product_document(
                    payload,
                    product_id=target_id,
                    existing=existing,
                )
                await self._products.update_one({"id": target_id}, {"$set": document})
                updated_count += 1
                continue

            if target_id <= 0 or await self._products.find_one({"id": target_id}) is not None:
                target_id = next_id
            next_id = max(next_id, target_id + 1)
            document = self._build_product_document(payload, product_id=target_id)
            await self._products.insert_one(document)
            created_count += 1

        return await self._build_import_result(
            entity_type="product",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message=(
                f"Đã import sản phẩm thành công. "
                f"Tạo mới {created_count}, cập nhật {updated_count}."
            ),
        )

    async def replace_product(
        self,
        product_id: int,
        payload: AdminProductUpsertRequest,
    ) -> Optional[dict]:
        existing = await self._products.find_one({"id": product_id})
        if existing is None:
            return None
        document = self._build_product_document(
            payload,
            product_id=product_id,
            existing=existing,
        )
        await self._products.update_one(
            {"id": product_id},
            {"$set": document},
        )
        updated = await self._products.find_one({"id": product_id})
        if updated is None:
            return None
        updated.pop("_id", None)
        return updated

    async def delete_product(self, product_id: int) -> bool:
        result = await self._products.delete_one({"id": product_id})
        return result.deleted_count > 0

    async def list_customers(self) -> list[AdminCustomerResponse]:
        users = await self._users.find({}).sort("fullName", 1).to_list(length=500)
        orders = await self._orders.find({}, {"userId": 1}).to_list(length=1000)
        counts: dict[str, int] = {}
        for order in orders:
            user_id = str(order.get("userId") or "")
            if user_id:
                counts[user_id] = counts.get(user_id, 0) + 1
        return [
            AdminCustomerResponse(
                id=str(user.get("id") or ""),
                fullName=str(user.get("fullName") or ""),
                email=str(user.get("email") or ""),
                phone=user.get("phone"),
                address=user.get("address"),
                orderCount=counts.get(str(user.get("id") or ""), 0),
                isAdmin=bool(user.get("isAdmin", False)),
            )
            for user in users
        ]

    async def list_vouchers(self) -> list[AdminVoucherResponse]:
        documents = await self._vouchers.find({}).sort("code", 1).to_list(length=200)
        return [
            AdminVoucherResponse(
                code=str(document.get("code") or ""),
                title=str(document.get("title") or ""),
                note=str(document.get("note") or ""),
                accent=str(document.get("accent") or "red"),
                discountType=str(document.get("discountType") or ""),
                discountValue=int(document.get("discountValue") or 0),
                minOrderValue=int(document.get("minOrderValue") or 0),
            )
            for document in documents
        ]

    async def get_voucher(self, code: str) -> Optional[AdminVoucherResponse]:
        document = await self._vouchers.find_one({"code": code.upper().strip()})
        if document is None:
            return None
        return AdminVoucherResponse(
            code=str(document.get("code") or ""),
            title=str(document.get("title") or ""),
            note=str(document.get("note") or ""),
            accent=str(document.get("accent") or "red"),
            discountType=str(document.get("discountType") or ""),
            discountValue=int(document.get("discountValue") or 0),
            minOrderValue=int(document.get("minOrderValue") or 0),
        )

    async def create_voucher(self, payload: dict) -> AdminVoucherResponse:
        normalized_code = str(payload.get("code") or "").upper().strip()
        payload["code"] = normalized_code
        existing = await self._vouchers.find_one({"code": normalized_code})
        if existing is not None:
            raise ValueError("Voucher đã tồn tại.")
        await self._vouchers.insert_one(payload)
        created = await self._vouchers.find_one({"code": normalized_code})
        return await self.get_voucher(normalized_code)  # type: ignore[return-value]

    async def update_voucher(self, code: str, payload: dict) -> Optional[AdminVoucherResponse]:
        normalized_code = code.upper().strip()
        payload["code"] = normalized_code
        await self._vouchers.update_one({"code": normalized_code}, {"$set": payload})
        return await self.get_voucher(normalized_code)

    async def delete_voucher(self, code: str) -> bool:
        result = await self._vouchers.delete_one({"code": code.upper().strip()})
        return result.deleted_count > 0

    async def list_testimonials(self) -> list[AdminTestimonialResponse]:
        documents = await self._home_testimonials.find({}).sort("createdAt", -1).to_list(length=200)
        return [
            AdminTestimonialResponse(
                id=str(document.get("id") or ""),
                content=str(document.get("content") or ""),
                author=str(document.get("author") or ""),
                accent=str(document.get("accent") or "gray"),
                createdAt=str(document.get("createdAt") or ""),
                isVisible=bool(document.get("isVisible", True)),
            )
            for document in documents
        ]

    async def update_testimonial_visibility(
        self,
        testimonial_id: str,
        is_visible: bool,
    ) -> Optional[AdminTestimonialResponse]:
        await self._home_testimonials.update_one(
            {"id": testimonial_id},
            {"$set": {"isVisible": is_visible}},
        )
        document = await self._home_testimonials.find_one({"id": testimonial_id})
        if document is None:
            return None
        return AdminTestimonialResponse(
            id=str(document.get("id") or ""),
            content=str(document.get("content") or ""),
            author=str(document.get("author") or ""),
            accent=str(document.get("accent") or "gray"),
            createdAt=str(document.get("createdAt") or ""),
            isVisible=bool(document.get("isVisible", True)),
        )

    async def delete_testimonial(self, testimonial_id: str) -> bool:
        result = await self._home_testimonials.delete_one({"id": testimonial_id})
        return result.deleted_count > 0

    async def list_content_documents(self) -> list[AdminContentDocumentResponse]:
        documents: list[AdminContentDocumentResponse] = []
        for key in ["home", "story", "contact", "login", "register"]:
            try:
                documents.append(await self.get_content_document(key))
            except ValueError:
                continue
        return documents

    async def get_content_document(self, key: str) -> AdminContentDocumentResponse:
        document, title = await self._resolve_content_document(key)
        normalized = dict(document)
        normalized.pop("_id", None)
        normalized.pop("slug", None)
        return AdminContentDocumentResponse(
            key=key,
            title=title,
            jsonContent=json.dumps(normalized, ensure_ascii=False, indent=2),
        )

    async def update_content_document(self, key: str, json_content: str) -> AdminContentDocumentResponse:
        parsed = json.loads(json_content)
        if not isinstance(parsed, dict):
            raise ValueError("Nội dung phải là JSON object.")
        collection, slug, title, validator = self._resolve_content_target(key)
        validated = validator(parsed)
        document = validated.model_dump(mode="json")
        document["slug"] = slug
        await collection.update_one({"slug": slug}, {"$set": document}, upsert=True)
        return AdminContentDocumentResponse(
            key=key,
            title=title,
            jsonContent=json.dumps(validated.model_dump(mode="json"), ensure_ascii=False, indent=2),
        )

    async def list_ingredients(self) -> list[AdminIngredientResponse]:
        documents = await self._ingredients.find({}).sort("category", 1).to_list(length=500)
        return [self._map_ingredient(document) for document in documents]

    async def list_inventory_transactions(self) -> list[AdminInventoryTransactionResponse]:
        documents = await self._inventory_transactions.find({}).sort("createdAt", -1).to_list(length=200)
        return [
            AdminInventoryTransactionResponse(
                id=str(document.get("id") or ""),
                ingredientId=str(document.get("ingredientId") or ""),
                ingredientName=str(document.get("ingredientName") or ""),
                transactionType=str(document.get("transactionType") or ""),
                quantityDelta=int(document.get("quantityDelta") or 0),
                unit=str(document.get("unit") or ""),
                normalizedQuantityDelta=int(document.get("normalizedQuantityDelta") or 0),
                normalizedUnit=str(document.get("normalizedUnit") or ""),
                balanceQuantity=int(document.get("balanceQuantity") or 0),
                balanceNormalizedQuantity=int(document.get("balanceNormalizedQuantity") or 0),
                referenceType=document.get("referenceType"),
                referenceId=document.get("referenceId"),
                note=document.get("note"),
                createdAt=str(document.get("createdAt") or ""),
            )
            for document in documents
        ]

    async def list_product_cost_reports(self) -> list[AdminProductCostReportResponse]:
        product_documents = await self._products.find({}).sort("title", 1).to_list(length=500)
        recipe_documents = await self._recipes.find({}).to_list(length=500)
        recipe_by_product = {
            int(document.get("productId") or 0): document for document in recipe_documents
        }
        reports: list[AdminProductCostReportResponse] = []
        for product in product_documents:
            product_id = int(product.get("id") or 0)
            selling_price = int(product.get("priceValue") or 0)
            recipe = recipe_by_product.get(product_id, {})
            estimated_cost = int(recipe.get("costPerUnit") or 0)
            gross_profit = selling_price - estimated_cost
            gross_margin = (
                round((gross_profit / selling_price) * 100, 2)
                if selling_price > 0
                else 0
            )
            reports.append(
                AdminProductCostReportResponse(
                    productId=product_id,
                    productTitle=str(product.get("title") or ""),
                    recipeType=str(recipe.get("recipeType") or "unmapped"),
                    sellingPrice=selling_price,
                    estimatedCost=estimated_cost,
                    grossProfit=gross_profit,
                    grossMarginPercent=gross_margin,
                )
            )
        return reports

    async def get_revenue_summary(self, range_type: str) -> AdminRevenueSummaryResponse:
        from collections import defaultdict
        now = datetime.now(timezone.utc)

        if range_type == "today":
            start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
            end = now
        elif range_type == "yesterday":
            yesterday = now - timedelta(days=1)
            start = datetime(yesterday.year, yesterday.month, yesterday.day, tzinfo=timezone.utc)
            end = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
        elif range_type == "7d":
            start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc) - timedelta(days=6)
            end = now
        elif range_type == "30d":
            start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc) - timedelta(days=29)
            end = now
        elif range_type == "this_month":
            start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
            end = now
        elif range_type == "last_month":
            first_of_this_month = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
            last_month_end = first_of_this_month
            last_month_start = datetime(
                first_of_this_month.year if first_of_this_month.month > 1 else first_of_this_month.year - 1,
                first_of_this_month.month - 1 if first_of_this_month.month > 1 else 12,
                1, tzinfo=timezone.utc,
            )
            start = last_month_start
            end = last_month_end
        else:
            start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc) - timedelta(days=6)
            end = now

        valid_statuses = {"paid", "processing", "delivered", "completed"}
        documents = await self._orders.find({}).to_list(length=5000)

        daily_revenue: dict[str, int] = defaultdict(int)
        daily_orders: dict[str, int] = defaultdict(int)
        total_revenue = 0
        total_orders = 0

        for doc in documents:
            status = str(doc.get("status") or "").strip().lower()
            if status not in valid_statuses:
                continue
            created_at = self._parse_datetime(doc.get("createdAt"))
            if created_at is None:
                continue
            if not (start <= created_at < end):
                continue
            date_key = created_at.strftime("%Y-%m-%d")
            amount = int(doc.get("total") or 0)
            daily_revenue[date_key] += amount
            daily_orders[date_key] += 1
            total_revenue += amount
            total_orders += 1

        # Build day list covering the full range
        days: list[AdminRevenueDayResponse] = []
        if range_type in ("today", "yesterday"):
            date_key = start.strftime("%Y-%m-%d")
            days.append(AdminRevenueDayResponse(
                date=date_key,
                revenue=daily_revenue.get(date_key, 0),
                orderCount=daily_orders.get(date_key, 0),
            ))
        else:
            current = start
            while current < end:
                date_key = current.strftime("%Y-%m-%d")
                days.append(AdminRevenueDayResponse(
                    date=date_key,
                    revenue=daily_revenue.get(date_key, 0),
                    orderCount=daily_orders.get(date_key, 0),
                ))
                current += timedelta(days=1)

        avg_order_value = (total_revenue // total_orders) if total_orders > 0 else 0
        return AdminRevenueSummaryResponse(
            range=range_type,
            totalRevenue=total_revenue,
            totalOrders=total_orders,
            avgOrderValue=avg_order_value,
            days=days,
        )

    async def list_ingredient_excel_rows(self) -> list[AdminIngredientExcelRow]:
        documents = await self._ingredients.find({}).sort("name", 1).to_list(length=1000)
        return [
            AdminIngredientExcelRow(
                id=str(document.get("id") or ""),
                name=str(document.get("name") or ""),
                category=str(document.get("category") or ""),
                unit=str(document.get("unit") or ""),
                unitPrice=int(document.get("unitPrice") or 0),
                availableQuantity=int(document.get("availableQuantity") or 0),
                lowStockThreshold=int(document.get("lowStockThreshold") or 0),
            )
            for document in documents
        ]

    async def get_ingredient(self, ingredient_id: str) -> Optional[AdminIngredientResponse]:
        document = await self._ingredients.find_one({"id": ingredient_id})
        if document is None:
            return None
        return self._map_ingredient(document)

    async def create_ingredient(
        self,
        payload: AdminIngredientUpsertRequest,
    ) -> AdminIngredientResponse:
        standard_unit, conversion_factor = self._normalize_unit(payload.unit)
        document = {
            "id": self._slugify(payload.name),
            "name": payload.name.strip(),
            "category": payload.category.strip(),
            "unit": payload.unit.strip().lower(),
            "standardUnit": standard_unit,
            "conversionFactor": conversion_factor,
            "unitPrice": int(payload.unitPrice or 0),
            "availableQuantity": int(payload.availableQuantity or 0),
            "availableNormalizedQuantity": int(payload.availableQuantity or 0) * conversion_factor,
            "lowStockThreshold": int(payload.lowStockThreshold or 0),
            "lowStockThresholdNormalized": int(payload.lowStockThreshold or 0) * conversion_factor,
            "status": self._ingredient_status(
                int(payload.availableQuantity or 0),
                int(payload.lowStockThreshold or 0),
            ),
            "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
        }
        existing = await self._ingredients.find_one({"id": document["id"]})
        if existing is not None:
            raise ValueError("Nguyên liệu đã tồn tại.")
        await self._ingredients.insert_one(document)
        await self._log_inventory_transaction(
            ingredient_document=document,
            transaction_type="initial",
            quantity_delta=int(payload.availableQuantity or 0),
            normalized_delta=int(payload.availableQuantity or 0) * conversion_factor,
            reference_type="ingredient",
            reference_id=document["id"],
            note="Khởi tạo nguyên liệu",
        )
        return self._map_ingredient(document)

    async def import_ingredients_from_excel(
        self,
        rows: list[AdminIngredientExcelRow],
    ) -> AdminBulkImportResult:
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []

        for index, row in enumerate(rows, start=2):
            if not row.name.strip():
                errors.append(self._import_error(index, "name", "Tên nguyên liệu là bắt buộc.", row.name))
                continue
            if int(row.unitPrice or 0) < 0:
                errors.append(self._import_error(index, "unitPrice", "Đơn giá không hợp lệ.", str(row.unitPrice)))
                continue
            payload = AdminIngredientUpsertRequest(
                name=row.name.strip(),
                category=row.category.strip(),
                unit=row.unit.strip().lower(),
                unitPrice=int(row.unitPrice or 0),
                availableQuantity=int(row.availableQuantity or 0),
                lowStockThreshold=int(row.lowStockThreshold or 0),
            )
            lookup_id = (row.id or "").strip() or self._slugify(payload.name)
            existing = await self._ingredients.find_one({"id": lookup_id})

            if existing is None:
                standard_unit, conversion_factor = self._normalize_unit(payload.unit)
                document = {
                    "id": lookup_id,
                    "name": payload.name,
                    "category": payload.category,
                    "unit": payload.unit,
                    "standardUnit": standard_unit,
                    "conversionFactor": conversion_factor,
                    "unitPrice": payload.unitPrice,
                    "availableQuantity": payload.availableQuantity,
                    "availableNormalizedQuantity": payload.availableQuantity * conversion_factor,
                    "lowStockThreshold": payload.lowStockThreshold,
                    "lowStockThresholdNormalized": payload.lowStockThreshold * conversion_factor,
                    "status": self._ingredient_status(
                        payload.availableQuantity,
                        payload.lowStockThreshold,
                    ),
                    "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                }
                await self._ingredients.insert_one(document)
                created_count += 1
                continue

            standard_unit, conversion_factor = self._normalize_unit(payload.unit)
            await self._ingredients.update_one(
                {"id": lookup_id},
                {
                    "$set": {
                        "name": payload.name,
                        "category": payload.category,
                        "unit": payload.unit,
                        "standardUnit": standard_unit,
                        "conversionFactor": conversion_factor,
                        "unitPrice": payload.unitPrice,
                        "availableQuantity": payload.availableQuantity,
                        "availableNormalizedQuantity": payload.availableQuantity * conversion_factor,
                        "lowStockThreshold": payload.lowStockThreshold,
                        "lowStockThresholdNormalized": payload.lowStockThreshold * conversion_factor,
                        "status": self._ingredient_status(
                            payload.availableQuantity,
                            payload.lowStockThreshold,
                        ),
                        "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                    }
                },
            )
            updated_count += 1

        return await self._build_import_result(
            entity_type="ingredient",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message=(
                f"Đã import nguyên liệu thành công. "
                f"Tạo mới {created_count}, cập nhật {updated_count}."
            ),
        )

    async def replace_ingredient(
        self,
        ingredient_id: str,
        payload: AdminIngredientUpsertRequest,
    ) -> Optional[AdminIngredientResponse]:
        existing = await self._ingredients.find_one({"id": ingredient_id})
        if existing is None:
            return None
        quantity = int(payload.availableQuantity or 0)
        threshold = int(payload.lowStockThreshold or 0)
        standard_unit, conversion_factor = self._normalize_unit(payload.unit)
        await self._ingredients.update_one(
            {"id": ingredient_id},
            {
                "$set": {
                    "name": payload.name.strip(),
                    "category": payload.category.strip(),
                    "unit": payload.unit.strip().lower(),
                    "standardUnit": standard_unit,
                    "conversionFactor": conversion_factor,
                    "unitPrice": int(payload.unitPrice or 0),
                    "availableQuantity": quantity,
                    "availableNormalizedQuantity": quantity * conversion_factor,
                    "lowStockThreshold": threshold,
                    "lowStockThresholdNormalized": threshold * conversion_factor,
                    "status": self._ingredient_status(quantity, threshold),
                    "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                }
            },
        )
        updated = await self._ingredients.find_one({"id": ingredient_id})
        if updated is None:
            return None
        return self._map_ingredient(updated)

    async def delete_ingredient(self, ingredient_id: str) -> bool:
        result = await self._ingredients.delete_one({"id": ingredient_id})
        return result.deleted_count > 0

    async def list_recipes(self) -> list[AdminRecipeResponse]:
        documents = await self._recipes.find({}).sort("createdAt", -1).to_list(length=500)
        return [self._map_recipe(document) for document in documents]

    async def get_recipe_options(self) -> AdminRecipeOptionsResponse:
        return await self.get_recipe_options_for_edit()

    async def get_recipe_options_for_edit(
        self,
        recipe_id: Optional[str] = None,
    ) -> AdminRecipeOptionsResponse:
        recipes = await self._recipes.find({}, {"productId": 1}).to_list(length=500)
        product_ids_with_recipe = {
            int(item.get("productId") or 0)
            for item in recipes
            if int(item.get("productId") or 0) > 0
        }
        if recipe_id:
            current_recipe = await self._recipes.find_one({"id": recipe_id})
            if current_recipe is not None:
                product_ids_with_recipe.discard(int(current_recipe.get("productId") or 0))
        product_documents = await self._products.find({}).sort("title", 1).to_list(length=500)
        ingredient_documents = await self._ingredients.find({}).sort("name", 1).to_list(length=500)
        recipe_documents = await self._recipes.find({}).sort("createdAt", -1).to_list(length=500)
        return AdminRecipeOptionsResponse(
            products=[
                AdminProductResponse(
                    id=int(document.get("id") or 0),
                    title=str(document.get("title") or ""),
                    category=str(document.get("category") or ""),
                    priceValue=int(document.get("priceValue") or 0),
                    stockStatus=str(document.get("stockStatus") or ""),
                )
                for document in product_documents
                if int(document.get("id") or 0) not in product_ids_with_recipe
            ],
            ingredients=[self._map_ingredient(document) for document in ingredient_documents],
            recipeReferences=[
                AdminRecipeReferenceResponse(
                    id=str(document.get("id") or ""),
                    productId=int(document.get("productId") or 0),
                    productTitle=str(document.get("productTitle") or ""),
                    recipeType=str(document.get("recipeType") or "finished"),
                    yieldQuantity=int(document.get("yieldQuantity") or 0),
                    yieldUnit=str(document.get("yieldUnit") or ""),
                    costPerUnit=int(document.get("costPerUnit") or 0),
                )
                for document in recipe_documents
                if str(document.get("id") or "") != (recipe_id or "")
            ],
        )

    async def get_recipe(self, recipe_id: str) -> Optional[AdminRecipeResponse]:
        document = await self._recipes.find_one({"id": recipe_id})
        if document is None:
            return None
        return self._map_recipe(document)

    async def create_recipe(
        self,
        payload: AdminRecipeCreateRequest,
    ) -> AdminRecipeResponse:
        existing = await self._recipes.find_one({"productId": payload.productId})
        if existing is not None:
            raise ValueError("Recipe already exists for this product.")
        document = await self._build_recipe_document(
            payload=payload,
            recipe_id=f"recipe-{uuid4().hex[:10]}",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        await self._recipes.insert_one(document)
        return self._map_recipe(document)

    async def update_recipe(
        self,
        recipe_id: str,
        payload: AdminRecipeCreateRequest,
    ) -> Optional[AdminRecipeResponse]:
        existing = await self._recipes.find_one({"id": recipe_id})
        if existing is None:
            return None

        duplicate = await self._recipes.find_one(
            {"productId": payload.productId, "id": {"$ne": recipe_id}}
        )
        if duplicate is not None:
            raise ValueError("Recipe already exists for this product.")

        document = await self._build_recipe_document(
            payload=payload,
            recipe_id=recipe_id,
            created_at=str(existing.get("createdAt") or datetime.now(timezone.utc).isoformat()),
        )
        await self._recipes.update_one({"id": recipe_id}, {"$set": document})
        updated = await self._recipes.find_one({"id": recipe_id})
        if updated is None:
            return None
        return self._map_recipe(updated)

    async def delete_recipe(self, recipe_id: str) -> bool:
        result = await self._recipes.delete_one({"id": recipe_id})
        return result.deleted_count > 0

    async def copy_recipe(self, recipe_id: str, payload: AdminRecipeCopyRequest) -> AdminRecipeResponse:
        source = await self._recipes.find_one({"id": recipe_id})
        if source is None:
            raise ValueError("Không tìm thấy công thức nguồn.")
        duplicate = await self._recipes.find_one({"productId": payload.productId})
        if duplicate is not None:
            raise ValueError("Sản phẩm đích đã có công thức.")
        product = await self._products.find_one({"id": payload.productId})
        if product is None:
            raise ValueError("Không tìm thấy sản phẩm đích.")
        document = dict(source)
        document.pop("_id", None)
        document["id"] = f"recipe-{uuid4().hex[:10]}"
        document["productId"] = payload.productId
        document["productTitle"] = str(product.get("title") or "")
        document["createdAt"] = datetime.now(timezone.utc).isoformat()
        await self._recipes.insert_one(document)
        return self._map_recipe(document)

    async def deduct_ingredients_for_order_items(
        self,
        items: list[dict],
        *,
        reference_type: str = "order",
        reference_id: Optional[str] = None,
    ) -> None:
        shortages = await self.validate_ingredients_for_order_items(items)
        if shortages:
            shortage = shortages[0]
            raise ValueError(
                f"Không đủ nguyên liệu {shortage.get('ingredientName') or shortage.get('ingredientId')} để hoàn tất đơn hàng."
            )

        required_quantities = await self._resolve_required_quantities_for_order_items(items)

        ingredient_documents = await self._ingredients.find(
            {"id": {"$in": list(required_quantities.keys())}}
        ).to_list(length=500)
        ingredients_by_id = {
            str(document.get("id") or ""): document for document in ingredient_documents
        }

        for ingredient_id, required in required_quantities.items():
            ingredient = ingredients_by_id[ingredient_id]
            factor = int(ingredient.get("conversionFactor") or self._normalize_unit(str(ingredient.get("unit") or ""))[1])
            available = int(ingredient.get("availableQuantity") or 0)
            available_normalized = int(ingredient.get("availableNormalizedQuantity") or available * factor)
            threshold = int(ingredient.get("lowStockThreshold") or 0)
            standard_unit = str(ingredient.get("standardUnit") or self._normalize_unit(str(ingredient.get("unit") or ""))[0])
            next_normalized_quantity = max(0, available_normalized - required)
            next_quantity = max(0, math.floor(next_normalized_quantity / factor))
            await self._ingredients.update_one(
                {"id": ingredient_id},
                {
                    "$set": {
                        "availableQuantity": next_quantity,
                        "availableNormalizedQuantity": next_normalized_quantity,
                        "status": self._ingredient_status(next_quantity, threshold),
                        "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                    }
                },
            )
            updated_document = dict(ingredient)
            updated_document["availableQuantity"] = next_quantity
            updated_document["availableNormalizedQuantity"] = next_normalized_quantity
            await self._log_inventory_transaction(
                ingredient_document=updated_document,
                transaction_type="deduct",
                quantity_delta=-math.ceil(required / factor),
                normalized_delta=-required,
                reference_type=reference_type,
                reference_id=reference_id,
                note="Trừ kho theo đơn hàng/công thức",
                normalized_unit=standard_unit,
            )

    async def restore_ingredients_for_reference(
        self,
        *,
        reference_type: str,
        reference_id: str,
        restore_reference_type: str,
        restore_reference_id: str,
        note: str,
    ) -> None:
        transactions = await self._inventory_transactions.find(
            {
                "referenceType": reference_type,
                "referenceId": reference_id,
                "transactionType": "deduct",
            }
        ).to_list(length=1000)
        if not transactions:
            return

        for transaction in transactions:
            ingredient_id = str(transaction.get("ingredientId") or "")
            if not ingredient_id:
                continue
            ingredient = await self._ingredients.find_one({"id": ingredient_id})
            if ingredient is None:
                continue

            factor = int(
                ingredient.get("conversionFactor")
                or self._normalize_unit(str(ingredient.get("unit") or ""))[1]
            )
            current_quantity = int(ingredient.get("availableQuantity") or 0)
            current_normalized_quantity = int(
                ingredient.get("availableNormalizedQuantity") or current_quantity * factor
            )
            restored_normalized = abs(int(transaction.get("normalizedQuantityDelta") or 0))
            if restored_normalized <= 0:
                continue
            next_normalized_quantity = current_normalized_quantity + restored_normalized
            next_quantity = math.floor(next_normalized_quantity / factor)
            threshold = int(ingredient.get("lowStockThreshold") or 0)

            await self._ingredients.update_one(
                {"id": ingredient_id},
                {
                    "$set": {
                        "availableQuantity": next_quantity,
                        "availableNormalizedQuantity": next_normalized_quantity,
                        "status": self._ingredient_status(next_quantity, threshold),
                        "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                    }
                },
            )

            updated_document = dict(ingredient)
            updated_document["availableQuantity"] = next_quantity
            updated_document["availableNormalizedQuantity"] = next_normalized_quantity
            await self._log_inventory_transaction(
                ingredient_document=updated_document,
                transaction_type="restore",
                quantity_delta=math.ceil(restored_normalized / factor),
                normalized_delta=restored_normalized,
                reference_type=restore_reference_type,
                reference_id=restore_reference_id,
                note=note,
                normalized_unit=str(
                    ingredient.get("standardUnit")
                    or self._normalize_unit(str(ingredient.get("unit") or ""))[0]
                ),
            )

    async def update_ingredient(
        self,
        ingredient_id: str,
        payload: AdminIngredientUpdateRequest,
    ) -> Optional[AdminIngredientResponse]:
        document = await self._ingredients.find_one({"id": ingredient_id})
        if document is None:
            return None

        factor = int(document.get("conversionFactor") or self._normalize_unit(str(document.get("unit") or ""))[1])
        current_quantity = int(document.get("availableQuantity") or 0)
        current_normalized_quantity = int(document.get("availableNormalizedQuantity") or current_quantity * factor)
        next_quantity = max(0, current_quantity + int(payload.quantityDelta or 0))
        next_normalized_quantity = max(0, current_normalized_quantity + int(payload.quantityDelta or 0) * factor)
        next_threshold = (
            int(payload.lowStockThreshold)
            if payload.lowStockThreshold is not None
            else int(document.get("lowStockThreshold") or 0)
        )
        next_status = payload.status or self._ingredient_status(next_quantity, next_threshold)

        await self._ingredients.update_one(
            {"id": ingredient_id},
            {
                "$set": {
                    "availableQuantity": next_quantity,
                    "availableNormalizedQuantity": next_normalized_quantity,
                    "lowStockThreshold": next_threshold,
                    "lowStockThresholdNormalized": next_threshold * factor,
                    "status": next_status,
                    "lastUpdatedAt": datetime.now(timezone.utc).isoformat(),
                }
            },
        )
        updated = await self._ingredients.find_one({"id": ingredient_id})
        if updated is None:
            return None
        await self._log_inventory_transaction(
            ingredient_document=updated,
            transaction_type="manual_adjustment",
            quantity_delta=int(payload.quantityDelta or 0),
            normalized_delta=int(payload.quantityDelta or 0) * factor,
            reference_type="admin",
            reference_id=ingredient_id,
            note="Điều chỉnh thủ công tồn kho",
        )
        return self._map_ingredient(updated)

    async def list_voucher_excel_rows(self) -> list[AdminVoucherExcelRow]:
        documents = await self._vouchers.find({}).sort("code", 1).to_list(length=1000)
        return [
            AdminVoucherExcelRow(
                code=str(document.get("code") or ""),
                title=str(document.get("title") or ""),
                note=str(document.get("note") or ""),
                accent=str(document.get("accent") or "red"),
                discountType=str(document.get("discountType") or "percent"),
                discountValue=int(document.get("discountValue") or 0),
                minOrderValue=int(document.get("minOrderValue") or 0),
            )
            for document in documents
        ]

    async def import_vouchers_from_excel(
        self,
        rows: list[AdminVoucherExcelRow],
    ) -> AdminBulkImportResult:
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []
        for index, row in enumerate(rows, start=2):
            code = row.code.upper().strip()
            if not code:
                errors.append(self._import_error(index, "code", "Mã voucher là bắt buộc.", row.code))
                continue
            if row.discountType not in {"percent", "shipping"}:
                errors.append(self._import_error(index, "discountType", "Loại giảm giá không hợp lệ.", row.discountType))
                continue
            if int(row.discountValue or 0) <= 0:
                errors.append(self._import_error(index, "discountValue", "Giá trị giảm phải lớn hơn 0.", str(row.discountValue)))
                continue
            payload = {
                "code": code,
                "title": row.title.strip(),
                "note": row.note.strip(),
                "accent": row.accent.strip() or "red",
                "discountType": row.discountType.strip(),
                "discountValue": int(row.discountValue or 0),
                "minOrderValue": int(row.minOrderValue or 0),
            }
            existing = await self._vouchers.find_one({"code": code})
            if existing is None:
                await self._vouchers.insert_one(payload)
                created_count += 1
            else:
                await self._vouchers.update_one({"code": code}, {"$set": payload})
                updated_count += 1
        return await self._build_import_result(
            entity_type="voucher",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message="Đã import voucher thành công.",
        )

    async def list_customer_excel_rows(self) -> list[AdminCustomerExcelRow]:
        documents = await self._users.find({}).sort("fullName", 1).to_list(length=1000)
        return [
            AdminCustomerExcelRow(
                id=str(document.get("id") or ""),
                fullName=str(document.get("fullName") or ""),
                email=str(document.get("email") or ""),
                phone=document.get("phone"),
                address=document.get("address"),
                isAdmin=bool(document.get("isAdmin", False)),
            )
            for document in documents
            if document.get("isAdmin") is not True
        ]

    async def import_customers_from_excel(
        self,
        rows: list[AdminCustomerExcelRow],
    ) -> AdminBulkImportResult:
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []
        for index, row in enumerate(rows, start=2):
            email = row.email.lower().strip()
            if not row.fullName.strip():
                errors.append(self._import_error(index, "fullName", "Tên khách hàng là bắt buộc.", row.fullName))
                continue
            if "@" not in email:
                errors.append(self._import_error(index, "email", "Email không hợp lệ.", row.email))
                continue
            existing = None
            if row.id:
                existing = await self._users.find_one({"id": row.id.strip()})
            if existing is None:
                existing = await self._users.find_one({"email": email})
            if existing is not None and existing.get("isAdmin") is True:
                errors.append(self._import_error(index, "email", "Không thể import đè lên tài khoản admin.", row.email))
                continue
            payload = {
                "fullName": row.fullName.strip(),
                "email": email,
                "phone": row.phone.strip() if row.phone else None,
                "address": row.address.strip() if row.address else None,
                "isAdmin": False,
            }
            if existing is None:
                user_id = row.id.strip() if row.id else f"user-{uuid4().hex[:10]}"
                payload.update(
                    {
                        "id": user_id,
                        "hashedPassword": hash_password("123456"),
                        "createdAt": datetime.now(timezone.utc).isoformat(),
                        "collectedVoucherCodes": [],
                        "usedVoucherCodes": [],
                    }
                )
                await self._users.insert_one(payload)
                created_count += 1
            else:
                await self._users.update_one(
                    {"id": str(existing.get("id") or "")},
                    {"$set": payload},
                )
                updated_count += 1
        return await self._build_import_result(
            entity_type="customer",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message="Đã import khách hàng thành công.",
        )

    async def list_order_excel_rows(self) -> list[AdminOrderExcelRow]:
        documents = await self._orders.find({}).sort("createdAt", -1).to_list(length=1000)
        return [
            AdminOrderExcelRow(
                orderId=str(document.get("orderId") or ""),
                userId=document.get("userId"),
                customerName=str(document.get("customerName") or ""),
                customerEmail=str(document.get("customerEmail") or ""),
                customerPhone=document.get("customerPhone"),
                customerAddress=document.get("customerAddress"),
                paymentMethod=str(document.get("paymentMethod") or ""),
                status=str(document.get("status") or ""),
                itemCount=int(document.get("itemCount") or 0),
                subtotal=int(document.get("subtotal") or 0),
                discountAmount=int(document.get("discountAmount") or 0),
                deliveryFee=int(document.get("deliveryFee") or 0),
                total=int(document.get("total") or 0),
                voucherCode=document.get("voucherCode"),
                itemsJson=json.dumps(document.get("items", []), ensure_ascii=False),
                createdAt=str(document.get("createdAt") or ""),
            )
            for document in documents
        ]

    async def import_orders_from_excel(
        self,
        rows: list[AdminOrderExcelRow],
    ) -> AdminBulkImportResult:
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []
        for index, row in enumerate(rows, start=2):
            if not row.orderId.strip():
                errors.append(self._import_error(index, "orderId", "Mã đơn là bắt buộc.", row.orderId))
                continue
            if "@" not in row.customerEmail.lower().strip():
                errors.append(self._import_error(index, "customerEmail", "Email khách hàng không hợp lệ.", row.customerEmail))
                continue
            try:
                items = json.loads(row.itemsJson or "[]")
                if not isinstance(items, list):
                    raise ValueError
            except ValueError:
                errors.append(self._import_error(index, "itemsJson", "itemsJson phải là mảng JSON hợp lệ.", row.itemsJson))
                continue
            user_id = await self._resolve_or_create_customer_for_import(row)
            created_at = row.createdAt or datetime.now(timezone.utc).isoformat()
            document = {
                "orderId": row.orderId.strip(),
                "userId": user_id,
                "customerName": row.customerName.strip(),
                "customerEmail": row.customerEmail.lower().strip(),
                "customerPhone": row.customerPhone.strip() if row.customerPhone else None,
                "customerAddress": row.customerAddress.strip() if row.customerAddress else None,
                "paymentMethod": row.paymentMethod.strip(),
                "status": row.status.strip(),
                "itemCount": int(row.itemCount or 0),
                "subtotal": int(row.subtotal or 0),
                "discountAmount": int(row.discountAmount or 0),
                "deliveryFee": int(row.deliveryFee or 0),
                "total": int(row.total or 0),
                "voucherCode": row.voucherCode.strip() if row.voucherCode else None,
                "items": items,
                "createdAt": created_at,
                "timeline": [],
            }
            existing = await self._orders.find_one({"orderId": row.orderId.strip()})
            if existing is None:
                await self._orders.insert_one(document)
                created_count += 1
            else:
                await self._orders.update_one({"orderId": row.orderId.strip()}, {"$set": document})
                updated_count += 1
        return await self._build_import_result(
            entity_type="order",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message="Đã import đơn hàng thành công.",
        )

    async def list_recipe_excel_rows(self) -> list[AdminRecipeExcelRow]:
        documents = await self._recipes.find({}).sort("createdAt", -1).to_list(length=1000)
        return [
            AdminRecipeExcelRow(
                id=str(document.get("id") or ""),
                productId=int(document.get("productId") or 0),
                recipeType=str(document.get("recipeType") or "finished"),
                yieldQuantity=int(document.get("yieldQuantity") or 0),
                yieldUnit=str(document.get("yieldUnit") or ""),
                ingredientsJson=json.dumps(document.get("ingredients", []), ensure_ascii=False),
            )
            for document in documents
        ]

    async def import_recipes_from_excel(
        self,
        rows: list[AdminRecipeExcelRow],
    ) -> AdminBulkImportResult:
        created_count = 0
        updated_count = 0
        errors: list[AdminImportValidationError] = []
        for index, row in enumerate(rows, start=2):
            try:
                raw_ingredients = json.loads(row.ingredientsJson or "[]")
                if not isinstance(raw_ingredients, list):
                    raise ValueError
            except ValueError:
                errors.append(self._import_error(index, "ingredientsJson", "ingredientsJson phải là mảng JSON hợp lệ.", row.ingredientsJson))
                continue
            try:
                ingredients = [
                    AdminRecipeIngredientInput(
                        ingredientId=str(item.get("ingredientId") or ""),
                        sourceType=str(item.get("sourceType") or "ingredient"),
                        quantity=int(item.get("quantity") or 0),
                        wastePercent=int(item.get("wastePercent") or 0),
                    )
                    for item in raw_ingredients
                ]
            except (TypeError, ValueError):
                errors.append(self._import_error(index, "ingredientsJson", "Dữ liệu nguyên liệu trong công thức không hợp lệ.", row.ingredientsJson))
                continue
            payload = AdminRecipeCreateRequest(
                productId=int(row.productId or 0),
                recipeType=row.recipeType.strip() or "finished",
                yieldQuantity=int(row.yieldQuantity or 0),
                yieldUnit=row.yieldUnit.strip(),
                ingredients=ingredients,
            )
            try:
                if row.id:
                    updated = await self.update_recipe(row.id.strip(), payload)
                    if updated is None:
                        await self.create_recipe(payload)
                        created_count += 1
                    else:
                        updated_count += 1
                else:
                    existing = await self._recipes.find_one({"productId": payload.productId})
                    if existing is None:
                        await self.create_recipe(payload)
                        created_count += 1
                    else:
                        await self.update_recipe(str(existing.get("id") or ""), payload)
                        updated_count += 1
            except ValueError as error:
                errors.append(self._import_error(index, "recipe", str(error), row.id or str(row.productId)))
        return await self._build_import_result(
            entity_type="recipe",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message="Đã import công thức thành công.",
        )

    async def list_import_audit_logs(self) -> list[AdminImportAuditLogResponse]:
        documents = await self._import_audit_logs.find({}).sort("createdAt", -1).to_list(length=100)
        return [
            AdminImportAuditLogResponse(
                id=str(document.get("id") or ""),
                entityType=str(document.get("entityType") or ""),
                status=str(document.get("status") or ""),
                createdCount=int(document.get("createdCount") or 0),
                updatedCount=int(document.get("updatedCount") or 0),
                errorCount=int(document.get("errorCount") or 0),
                createdAt=str(document.get("createdAt") or ""),
            )
            for document in documents
        ]

    async def _resolve_or_create_customer_for_import(self, row: AdminOrderExcelRow) -> str:
        if row.userId:
            document = await self._users.find_one({"id": row.userId.strip()})
            if document is not None:
                return str(document.get("id") or "")
        email = row.customerEmail.lower().strip()
        existing = await self._users.find_one({"email": email})
        if existing is not None:
            return str(existing.get("id") or "")
        user_id = f"user-{uuid4().hex[:10]}"
        await self._users.insert_one(
            {
                "id": user_id,
                "fullName": row.customerName.strip() or "Imported Customer",
                "email": email,
                "phone": row.customerPhone.strip() if row.customerPhone else None,
                "address": row.customerAddress.strip() if row.customerAddress else None,
                "hashedPassword": hash_password("123456"),
                "isAdmin": False,
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "collectedVoucherCodes": [],
                "usedVoucherCodes": [],
            }
        )
        return user_id

    async def _build_import_result(
        self,
        *,
        entity_type: str,
        created_count: int,
        updated_count: int,
        errors: list[AdminImportValidationError],
        success_message: str,
    ) -> AdminBulkImportResult:
        audit_id = f"import-{uuid4().hex[:12]}"
        await self._import_audit_logs.insert_one(
            {
                "id": audit_id,
                "entityType": entity_type,
                "status": "success" if not errors else ("partial" if created_count or updated_count else "failed"),
                "createdCount": created_count,
                "updatedCount": updated_count,
                "errorCount": len(errors),
                "errors": [error.model_dump() for error in errors],
                "createdAt": datetime.now(timezone.utc).isoformat(),
            }
        )
        return AdminBulkImportResult(
            message=success_message,
            createdCount=created_count,
            updatedCount=updated_count,
            errorCount=len(errors),
            errors=errors,
            auditLogId=audit_id,
        )

    def _import_error(
        self,
        row_number: int,
        field: str,
        message: str,
        value: Optional[str] = None,
    ) -> AdminImportValidationError:
        return AdminImportValidationError(
            rowNumber=row_number,
            field=field,
            message=message,
            value=value,
        )

    def _parse_datetime(self, raw_value):
        if raw_value is None:
            return None
        if isinstance(raw_value, datetime):
            return raw_value if raw_value.tzinfo else raw_value.replace(tzinfo=timezone.utc)
        try:
            parsed = datetime.fromisoformat(str(raw_value).replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            return None

    def _format_currency(self, amount: int) -> str:
        return f"{amount:,}đ".replace(",", ".")

    async def _resolve_content_document(self, key: str) -> tuple[dict, str]:
        collection, slug, title, _ = self._resolve_content_target(key)
        document = await collection.find_one({"slug": slug})
        if document is None:
            raise ValueError("Không tìm thấy nội dung trang.")
        return document, title

    def _resolve_content_target(self, key: str):
        normalized = key.strip().lower()
        if normalized == "home":
            return self._home_pages, "main", "Trang chủ", HomePageResponse.model_validate
        if normalized == "story":
            return self._story_pages, "story", "Câu chuyện", StoryPageResponse.model_validate
        if normalized == "contact":
            return self._contact_pages, "contact", "Liên hệ", ContactPageResponse.model_validate
        if normalized == "login":
            return self._auth_pages, "login", "Đăng nhập", AuthPageResponse.model_validate
        if normalized == "register":
            return self._auth_pages, "register", "Đăng ký", AuthPageResponse.model_validate
        raise ValueError("Loại nội dung không hợp lệ.")

    def _timeline_title(self, status_code: str) -> str:
        mapping = {
            "paid": "Đã xác nhận thanh toán",
            "awaiting_transfer": "Chờ chuyển khoản",
            "processing": "Đang chuẩn bị đơn",
            "delivered": "Đã giao hàng",
            "completed": "Hoàn tất đơn hàng",
            "cancelled": "Đã hủy đơn",
        }
        return mapping.get(status_code, "Cập nhật trạng thái")

    def _timeline_description(self, status_code: str) -> str:
        mapping = {
            "paid": "Đơn hàng đã được xác nhận và chờ xử lý.",
            "awaiting_transfer": "Hệ thống đang chờ đối soát chuyển khoản.",
            "processing": "Bếp đang chuẩn bị đơn hàng.",
            "delivered": "Đơn hàng đã được giao tới khách.",
            "completed": "Đơn hàng đã hoàn tất.",
            "cancelled": "Đơn hàng đã bị hủy.",
        }
        return mapping.get(status_code, "Đơn hàng vừa được cập nhật trạng thái.")

    def _status_label(self, status: str) -> str:
        normalized = status.strip().lower()
        if normalized == "paid":
            return "Mới"
        if normalized in {"pending", "awaiting_transfer"}:
            return "Mới"
        if normalized == "processing":
            return "Xử lý"
        if normalized == "shipping":
            return "Đang giao"
        if normalized in {"completed", "delivered"}:
            return "Hoàn tất"
        if normalized == "cancelled":
            return "Huỷ"
        if normalized == "failed":
            return "Lỗi"
        return status or "Không rõ"

    def _next_order_status(self, current_status: str) -> Optional[str]:
        normalized = current_status.strip().lower()
        if normalized in {"paid", "pending", "awaiting_transfer"}:
            return "processing"
        if normalized == "processing":
            return "shipping"
        if normalized == "shipping":
            return "completed"
        return None

    def _format_growth_label(self, revenue_today, previous_day_start, recent_orders_docs) -> str:
        previous_day_end = previous_day_start + timedelta(days=1)
        previous_revenue = 0
        for document in recent_orders_docs:
            created_at = self._parse_datetime(document.get("createdAt"))
            if created_at is None:
                continue
            if previous_day_start <= created_at < previous_day_end:
                previous_revenue += int(document.get("total") or 0)
        if previous_revenue <= 0:
            return "chưa đủ dữ liệu"
        growth = ((revenue_today - previous_revenue) / previous_revenue) * 100
        sign = "+" if growth >= 0 else ""
        return f"{sign}{growth:.0f}%"

    def _normalize_status(self, status: str) -> str:
        normalized = status.strip().lower()
        mapping = {
            "mới": "paid",
            "paid": "paid",
            "xử lý": "processing",
            "processing": "processing",
            "đang giao": "shipping",
            "shipping": "shipping",
            "hoàn tất": "completed",
            "completed": "completed",
            "huỷ": "cancelled",
            "cancelled": "cancelled",
        }
        return mapping.get(normalized, "processing")

    def _ingredient_status(self, quantity: int, threshold: int) -> str:
        if quantity <= 0:
            return "Hết hàng"
        if quantity <= threshold:
            return "Sắp hết"
        return "Đủ hàng"

    def _map_ingredient(self, document) -> AdminIngredientResponse:
        quantity = int(document.get("availableQuantity") or 0)
        threshold = int(document.get("lowStockThreshold") or 0)
        standard_unit, conversion_factor = self._normalize_unit(str(document.get("unit") or ""))
        normalized_quantity = int(document.get("availableNormalizedQuantity") or quantity * conversion_factor)
        normalized_threshold = int(document.get("lowStockThresholdNormalized") or threshold * conversion_factor)
        return AdminIngredientResponse(
            id=str(document.get("id") or ""),
            name=str(document.get("name") or ""),
            category=str(document.get("category") or ""),
            unit=str(document.get("unit") or ""),
            standardUnit=str(document.get("standardUnit") or standard_unit),
            conversionFactor=int(document.get("conversionFactor") or conversion_factor),
            unitPrice=int(document.get("unitPrice") or 0),
            availableQuantity=quantity,
            availableNormalizedQuantity=normalized_quantity,
            lowStockThreshold=threshold,
            lowStockThresholdNormalized=normalized_threshold,
            status=str(document.get("status") or self._ingredient_status(quantity, threshold)),
            lastUpdatedAt=str(document.get("lastUpdatedAt") or ""),
        )

    def _map_recipe(self, document) -> AdminRecipeResponse:
        ingredients = [
            AdminRecipeIngredientResponse(
                ingredientId=str(item.get("ingredientId") or ""),
                ingredientName=str(item.get("ingredientName") or ""),
                sourceType=str(item.get("sourceType") or "ingredient"),
                unit=str(item.get("unit") or ""),
                quantity=int(item.get("quantity") or 0),
                normalizedQuantity=int(item.get("normalizedQuantity") or 0),
                wastePercent=int(item.get("wastePercent") or 0),
                unitPrice=int(item.get("unitPrice") or 0),
                lineCost=int(item.get("lineCost") or 0),
            )
            for item in document.get("ingredients", [])
        ]
        product_price = int(document.get("sellingPrice") or 0)
        gross_profit = product_price - int(document.get("costPerUnit") or 0)
        gross_margin = round((gross_profit / product_price) * 100, 2) if product_price > 0 else 0
        return AdminRecipeResponse(
            id=str(document.get("id") or ""),
            productId=int(document.get("productId") or 0),
            productTitle=str(document.get("productTitle") or ""),
            recipeType=str(document.get("recipeType") or "finished"),
            yieldQuantity=int(document.get("yieldQuantity") or 0),
            yieldUnit=str(document.get("yieldUnit") or ""),
            ingredients=ingredients,
            totalCost=int(document.get("totalCost") or 0),
            costPerUnit=int(document.get("costPerUnit") or 0),
            grossProfitEstimate=gross_profit,
            grossMarginPercent=gross_margin,
            createdAt=str(document.get("createdAt") or ""),
        )

    async def _build_recipe_document(
        self,
        *,
        payload: AdminRecipeCreateRequest,
        recipe_id: str,
        created_at: str,
    ) -> dict:
        product = await self._products.find_one({"id": payload.productId})
        if product is None:
            raise ValueError("Product not found.")
        if int(payload.yieldQuantity or 0) <= 0:
            raise ValueError("Yield quantity must be greater than zero.")

        ingredient_ids = [item.ingredientId for item in payload.ingredients if item.sourceType == "ingredient"]
        ingredient_documents = await self._ingredients.find(
            {"id": {"$in": ingredient_ids}}
        ).to_list(length=500)
        mapped_ingredients = {str(item.get("id") or ""): item for item in ingredient_documents}
        recipe_ids = [item.ingredientId for item in payload.ingredients if item.sourceType == "recipe"]
        recipe_documents = await self._recipes.find(
            {"id": {"$in": recipe_ids}}
        ).to_list(length=500)
        mapped_recipes = {str(item.get("id") or ""): item for item in recipe_documents}

        recipe_ingredients = []
        total_cost = 0
        for item in payload.ingredients:
            source_type = str(item.sourceType or "ingredient").strip().lower()
            if source_type == "recipe":
                source_recipe = mapped_recipes.get(item.ingredientId)
                if source_recipe is None:
                    raise ValueError("Referenced recipe not found.")
                unit_price = int(source_recipe.get("costPerUnit") or 0)
                normalized_quantity = int(item.quantity or 0)
                ingredient_name = str(source_recipe.get("productTitle") or "")
                unit = str(source_recipe.get("yieldUnit") or "phần")
            else:
                ingredient = mapped_ingredients.get(item.ingredientId)
                if ingredient is None:
                    raise ValueError("Ingredient not found.")
                factor = int(ingredient.get("conversionFactor") or self._normalize_unit(str(ingredient.get("unit") or ""))[1])
                raw_unit_price = int(ingredient.get("unitPrice") or 0)
                unit_price = max(1, round(raw_unit_price / factor)) if factor > 1 else raw_unit_price
                normalized_quantity = int(item.quantity or 0) * factor
                ingredient_name = str(ingredient.get("name") or "")
                unit = str(ingredient.get("unit") or "")
            effective_normalized_quantity = math.ceil(
                normalized_quantity * (100 + int(item.wastePercent or 0)) / 100
            )
            line_cost = unit_price * effective_normalized_quantity
            total_cost += line_cost
            recipe_ingredients.append(
                {
                    "ingredientId": item.ingredientId,
                    "ingredientName": ingredient_name,
                    "sourceType": source_type,
                    "unit": unit,
                    "quantity": int(item.quantity or 0),
                    "normalizedQuantity": effective_normalized_quantity,
                    "wastePercent": int(item.wastePercent or 0),
                    "unitPrice": unit_price,
                    "lineCost": line_cost,
                }
            )

        yield_quantity = int(payload.yieldQuantity or 0)
        cost_per_unit = round(total_cost / yield_quantity) if yield_quantity > 0 else total_cost
        return {
            "id": recipe_id,
            "productId": payload.productId,
            "productTitle": str(product.get("title") or ""),
            "recipeType": payload.recipeType.strip() or "finished",
            "yieldQuantity": yield_quantity,
            "yieldUnit": payload.yieldUnit.strip(),
            "ingredients": recipe_ingredients,
            "totalCost": total_cost,
            "costPerUnit": cost_per_unit,
            "sellingPrice": int(product.get("priceValue") or 0),
            "createdAt": created_at,
        }

    async def _resolve_required_quantities_for_order_items(self, items: list[dict]) -> dict[str, int]:
        required_quantities: dict[str, int] = {}
        for item in items:
            product_id = int(item.get("productId") or 0)
            item_quantity = int(item.get("quantity") or 0)
            if product_id <= 0 or item_quantity <= 0:
                continue
            recipe = await self._recipes.find_one({"productId": product_id})
            if recipe is None:
                continue
            await self._collect_recipe_requirements(recipe, item_quantity, required_quantities, set())
        return required_quantities

    async def _collect_recipe_requirements(
        self,
        recipe: dict,
        output_quantity: int,
        accumulator: dict[str, int],
        visited_recipe_ids: set[str],
    ) -> None:
        recipe_id = str(recipe.get("id") or "")
        if recipe_id in visited_recipe_ids:
            raise ValueError("Phát hiện vòng lặp trong công thức nhiều tầng.")
        visited_recipe_ids.add(recipe_id)
        yield_quantity = max(1, int(recipe.get("yieldQuantity") or 1))
        for ingredient in recipe.get("ingredients", []):
            source_type = str(ingredient.get("sourceType") or "ingredient")
            normalized_per_batch = int(ingredient.get("normalizedQuantity") or 0)
            if normalized_per_batch <= 0:
                continue
            required = math.ceil((normalized_per_batch * output_quantity) / yield_quantity)
            source_id = str(ingredient.get("ingredientId") or "")
            if source_type == "recipe":
                child_recipe = await self._recipes.find_one({"id": source_id})
                if child_recipe is None:
                    raise ValueError(f"Không tìm thấy bán thành phẩm {source_id}.")
                await self._collect_recipe_requirements(
                    child_recipe,
                    required,
                    accumulator,
                    set(visited_recipe_ids),
                )
                continue
            accumulator[source_id] = accumulator.get(source_id, 0) + required

    async def _log_inventory_transaction(
        self,
        *,
        ingredient_document: dict,
        transaction_type: str,
        quantity_delta: int,
        normalized_delta: int,
        reference_type: Optional[str],
        reference_id: Optional[str],
        note: Optional[str],
        normalized_unit: Optional[str] = None,
    ) -> None:
        await self._inventory_transactions.insert_one(
            {
                "id": f"txn-{uuid4().hex[:12]}",
                "ingredientId": str(ingredient_document.get("id") or ""),
                "ingredientName": str(ingredient_document.get("name") or ""),
                "transactionType": transaction_type,
                "quantityDelta": quantity_delta,
                "unit": str(ingredient_document.get("unit") or ""),
                "normalizedQuantityDelta": normalized_delta,
                "normalizedUnit": normalized_unit or str(ingredient_document.get("standardUnit") or ""),
                "balanceQuantity": int(ingredient_document.get("availableQuantity") or 0),
                "balanceNormalizedQuantity": int(ingredient_document.get("availableNormalizedQuantity") or 0),
                "referenceType": reference_type,
                "referenceId": reference_id,
                "note": note,
                "createdAt": datetime.now(timezone.utc).isoformat(),
            }
        )

    def _normalize_unit(self, raw_unit: str) -> tuple[str, int]:
        unit = raw_unit.strip().lower()
        if unit == "kg":
            return "g", 1000
        if unit == "l":
            return "ml", 1000
        if unit in {"g", "ml"}:
            return unit, 1
        return unit or "unit", 1

    def _slugify(self, value: str) -> str:
        normalized = value.strip().lower()
        normalized = "".join(
            char if char.isalnum() else "-"
            for char in normalized
        )
        while "--" in normalized:
            normalized = normalized.replace("--", "-")
        return normalized.strip("-")

    def _join_excel_list(self, value) -> str:
        if not isinstance(value, list):
            return ""
        return " | ".join(str(item).strip() for item in value if str(item).strip())

    def _split_excel_list(self, raw_value: str) -> list[str]:
        return [
            item.strip()
            for item in str(raw_value).split("|")
            if item.strip()
        ]

    def _product_payload_from_excel_row(
        self,
        row: AdminProductExcelRow,
    ) -> AdminProductUpsertRequest:
        return AdminProductUpsertRequest(
            title=row.title.strip(),
            category=row.category.strip(),
            priceValue=int(row.priceValue or 0),
            description=row.description.strip(),
            images=self._split_excel_list(row.images),
            sku=row.sku.strip(),
            stockStatus=row.stockStatus.strip(),
            weight=row.weight.strip(),
            storageNote=row.storageNote.strip(),
            deliveryNote=row.deliveryNote.strip(),
            detailBullets=self._split_excel_list(row.detailBullets),
        )

    def _build_product_document(
        self,
        payload: AdminProductUpsertRequest,
        *,
        product_id: int,
        existing: Optional[dict] = None,
    ) -> dict:
        price_value = int(payload.priceValue or 0)
        images = [item.strip() for item in payload.images if item.strip()]
        detail_bullets = [item.strip() for item in payload.detailBullets if item.strip()]
        existing_reviews = list(existing.get("reviews", [])) if existing else []
        existing_related = list(existing.get("relatedProductIds", [])) if existing else []
        return {
            "id": product_id,
            "title": payload.title.strip(),
            "price": self._format_currency(price_value),
            "priceValue": price_value,
            "category": payload.category.strip(),
            "description": payload.description.strip(),
            "images": images,
            "sku": payload.sku.strip(),
            "stockStatus": payload.stockStatus.strip(),
            "weight": payload.weight.strip(),
            "storageNote": payload.storageNote.strip(),
            "deliveryNote": payload.deliveryNote.strip(),
            "detailBullets": detail_bullets,
            "reviews": existing_reviews,
            "relatedProductIds": existing_related,
        }


def get_admin_repository() -> AdminRepository:
    return AdminRepository(get_database())
