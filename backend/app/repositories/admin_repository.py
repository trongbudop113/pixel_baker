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
    AdminCategoryResponse,
    AdminCategoryUpsertRequest,
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
    AdminProductReviewResponse,
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
        self._categories = database["menu_categories"]
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
                    f"• Giá trị kho: {self._format_currency(sum(int(item.get('availableQuantity') or 0) * self._ingredient_unit_price(item) for item in ingredient_docs))}",
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

        # Award loyalty points when order is completed
        if normalized == "completed":
            prev_status = str(document.get("status") or "").lower() if document else ""
            already_earned = int(document.get("pointsEarned") or 0) if document else 0
            if already_earned == 0:
                order_total = int(document.get("total") or 0) if document else 0
                points_to_earn = order_total // 10_000
                if points_to_earn > 0:
                    user_id = str(document.get("userId") or "") if document else ""
                    if user_id:
                        await self._users.update_one(
                            {"id": user_id},
                            {"$inc": {"points": points_to_earn}},
                        )
                        await self._orders.update_one(
                            {"orderId": order_id},
                            {"$set": {"pointsEarned": points_to_earn}},
                        )
                        document = await self._orders.find_one({"orderId": order_id})

        # Send status update email
        customer_email = str(document.get("customerEmail") or "") if document else ""
        customer_name = str(document.get("customerName") or "") if document else ""
        points_earned = int(document.get("pointsEarned") or 0) if document else 0
        if customer_email and normalized in {"processing", "shipping", "delivered", "completed", "cancelled"}:
            from app.services.email_service import send_order_status_changed
            await send_order_status_changed(
                to_email=customer_email,
                customer_name=customer_name,
                order_id=order_id,
                new_status=normalized,
                points_earned=points_earned if normalized == "completed" else 0,
            )

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

    async def list_categories(self) -> list[AdminCategoryResponse]:
        documents = await self._categories.find({}).sort("sortOrder", 1).to_list(length=200)
        return [self._map_category_response(document) for document in documents]

    async def create_category(
        self,
        payload: AdminCategoryUpsertRequest,
    ) -> AdminCategoryResponse:
        document = self._build_category_document(payload)
        existing = await self._categories.find_one(
            {"$or": [{"id": document["id"]}, {"category": document["category"]}]},
        )
        if existing is not None:
            raise ValueError("Danh mục đã tồn tại.")
        await self._categories.insert_one(document)
        created = await self._categories.find_one({"id": document["id"]})
        if created is None:
            raise RuntimeError("Failed to create category.")
        return self._map_category_response(created)

    async def replace_category(
        self,
        category_id: str,
        payload: AdminCategoryUpsertRequest,
    ) -> Optional[AdminCategoryResponse]:
        existing = await self._categories.find_one({"id": category_id})
        if existing is None:
            return None
        document = self._build_category_document(payload, category_id=category_id)
        duplicate = await self._categories.find_one(
            {"category": document["category"], "id": {"$ne": category_id}},
        )
        if duplicate is not None:
            raise ValueError("Danh mục đã tồn tại.")
        await self._categories.update_one({"id": category_id}, {"$set": document})
        updated = await self._categories.find_one({"id": document["id"]})
        if updated is None:
            return None
        return self._map_category_response(updated)

    async def delete_category(self, category_id: str) -> bool:
        result = await self._categories.delete_one({"id": category_id})
        return result.deleted_count > 0

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
                ingredientsText=str(document.get("ingredientsText") or ""),
                optionGroupsJson=json.dumps(
                    document.get("optionGroups", []),
                    ensure_ascii=False,
                ),
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
        document = await self._products.find_one({"id": product_id})
        if document is None:
            return None
        stock_status = await self._product_stock_status_for_category(
            str(document.get("category") or ""),
            payload.stockStatus,
        )
        await self._products.update_one(
            {"id": product_id},
            {"$set": {"stockStatus": stock_status}},
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
        semi_finished_categories = {
            str(item.get("category") or "")
            for item in await self._categories.find({"isSemiFinished": True}).to_list(length=500)
        }
        query: dict = {"id": {"$in": product_ids}}
        if semi_finished_categories:
            query["category"] = {"$nin": list(semi_finished_categories)}
        result = await self._products.update_many(
            query,
            {"$set": {"stockStatus": stock_status}},
        )
        return int(result.modified_count or 0)

    async def create_product(
        self,
        payload: AdminProductUpsertRequest,
    ) -> dict:
        latest = await self._products.find_one(sort=[("id", -1)])
        next_id = int(latest.get("id") or 0) + 1 if latest else 1
        document = await self._build_product_document(payload, product_id=next_id)
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
                document = await self._build_product_document(
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
            document = await self._build_product_document(payload, product_id=target_id)
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
        document = await self._build_product_document(
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

    async def list_all_reviews(self) -> list[AdminProductReviewResponse]:
        documents = await self._products.find({}, {"id": 1, "title": 1, "reviews": 1}).to_list(length=500)
        result: list[AdminProductReviewResponse] = []
        for doc in documents:
            product_id = int(doc.get("id") or 0)
            product_title = str(doc.get("title") or "")
            for review in doc.get("reviews", []):
                result.append(AdminProductReviewResponse(
                    productId=product_id,
                    productTitle=product_title,
                    author=str(review.get("author") or ""),
                    content=str(review.get("content") or ""),
                    rating=int(review.get("rating") or 5),
                    createdAt=str(review.get("createdAt") or ""),
                ))
        result.sort(key=lambda r: r.createdAt, reverse=True)
        return result

    async def delete_review(self, product_id: int, created_at: str) -> bool:
        document = await self._products.find_one({"id": product_id})
        if document is None:
            return False
        reviews = [r for r in document.get("reviews", []) if str(r.get("createdAt") or "") != created_at]
        await self._products.update_one({"id": product_id}, {"$set": {"reviews": reviews}})
        return True

    async def check_products_stock(self, product_ids: list[int]) -> list[dict]:
        """Return list of out-of-stock products from given product IDs."""
        if not product_ids:
            return []
        documents = await self._products.find(
            {"id": {"$in": product_ids}}
        ).to_list(length=len(product_ids) + 10)
        out_of_stock = []
        for doc in documents:
            stock = str(doc.get("stockStatus") or "").strip().lower()
            if stock != "còn hàng":
                out_of_stock.append({
                    "productId": int(doc.get("id") or 0),
                    "title": str(doc.get("title") or ""),
                    "stockStatus": str(doc.get("stockStatus") or "Hết hàng"),
                })
        return out_of_stock

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

    async def get_best_sellers(self, limit: int = 10) -> list:
        """Count product occurrences across all completed/delivered orders."""
        orders = await self._orders.find(
            {"status": {"$in": ["completed", "delivered", "processing", "paid"]}}
        ).to_list(length=5000)
        counts: dict[int, dict] = {}
        for order in orders:
            for item in order.get("items", []):
                pid = int(item.get("productId") or 0)
                if pid <= 0:
                    continue
                if pid not in counts:
                    counts[pid] = {"productId": pid, "title": item.get("title", ""), "totalSold": 0, "revenue": 0}
                counts[pid]["totalSold"] += int(item.get("quantity") or 1)
                counts[pid]["revenue"] += int(item.get("lineTotal") or 0)
        result = sorted(counts.values(), key=lambda x: x["totalSold"], reverse=True)
        return result[:limit]

    async def get_customer_segments(self) -> list:
        """Classify users as VIP/Regular/New/Potential based on order history."""
        users = await self._users.find({"isAdmin": {"$ne": True}}).to_list(length=2000)
        orders = await self._orders.find(
            {"status": {"$nin": ["cancelled"]}}
        ).to_list(length=10000)

        orders_by_user: dict[str, list] = {}
        for order in orders:
            uid = str(order.get("userId") or "")
            if uid:
                orders_by_user.setdefault(uid, []).append(order)

        segments = []
        for user in users:
            uid = str(user.get("id") or "")
            user_orders = orders_by_user.get(uid, [])
            order_count = len(user_orders)
            total_spend = sum(int(o.get("total") or 0) for o in user_orders)

            if order_count >= 5 or total_spend >= 2_000_000:
                segment = "VIP"
            elif order_count >= 2:
                segment = "Thường xuyên"
            elif order_count == 1:
                segment = "Mới"
            else:
                segment = "Tiềm năng"

            segments.append({
                "userId": uid,
                "name": str(user.get("fullName") or ""),
                "email": str(user.get("email") or ""),
                "segment": segment,
                "orderCount": order_count,
                "totalSpend": total_spend,
            })

        # Sort: VIP first, then by spend
        order_map = {"VIP": 0, "Thường xuyên": 1, "Mới": 2, "Tiềm năng": 3}
        segments.sort(key=lambda x: (order_map.get(x["segment"], 99), -x["totalSpend"]))
        return segments

    async def get_revenue_forecast(self) -> dict:
        """Simple linear regression on last 30 days to forecast next 7 days."""
        from datetime import datetime, timedelta, timezone
        now = datetime.now(timezone.utc)
        start = now - timedelta(days=30)

        orders = await self._orders.find(
            {"status": {"$in": ["completed", "delivered", "paid", "processing"]}}
        ).to_list(length=5000)

        daily: dict[str, int] = {}
        for order in orders:
            created = self._parse_datetime(order.get("createdAt"))
            if created and created >= start:
                key = created.strftime("%Y-%m-%d")
                daily[key] = daily.get(key, 0) + int(order.get("total") or 0)

        # Build 30-day series
        series = []
        for i in range(30):
            day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
            series.append({"date": day, "revenue": daily.get(day, 0)})

        # Linear regression: y = a + b*x
        n = len(series)
        x_vals = list(range(n))
        y_vals = [s["revenue"] for s in series]
        x_mean = sum(x_vals) / n
        y_mean = sum(y_vals) / n
        numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_vals, y_vals))
        denominator = sum((x - x_mean) ** 2 for x in x_vals)
        b = numerator / denominator if denominator != 0 else 0
        a = y_mean - b * x_mean

        # Forecast next 7 days
        forecast = []
        for i in range(7):
            future_x = n + i
            future_date = (now + timedelta(days=i)).strftime("%Y-%m-%d")
            predicted = max(0, int(a + b * future_x))
            forecast.append({"date": future_date, "predicted": predicted})

        return {
            "historical": series,
            "forecast": forecast,
            "trend": "up" if b > 0 else ("down" if b < 0 else "flat"),
            "dailyGrowth": round(b / y_mean * 100, 1) if y_mean > 0 else 0,
        }

    async def list_ingredient_excel_rows(self) -> list[AdminIngredientExcelRow]:
        documents = await self._ingredients.find({}).sort("name", 1).to_list(length=1000)
        return [
            AdminIngredientExcelRow(
                id=str(document.get("id") or ""),
                name=str(document.get("name") or ""),
                category=str(document.get("category") or ""),
                unit=str(document.get("unit") or ""),
                price=self._ingredient_price(document),
                priceUnitQuantity=self._ingredient_price_unit_quantity(document),
                unitPrice=self._ingredient_unit_price(document),
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
        price = self._payload_ingredient_price(payload)
        price_unit_quantity = self._payload_ingredient_price_unit_quantity(payload)
        if price < 0:
            raise ValueError("Giá không hợp lệ.")
        if price_unit_quantity <= 0:
            raise ValueError("Đơn vị phải lớn hơn 0.")
        unit_price = self._calculate_ingredient_unit_price(
            price,
            price_unit_quantity,
            conversion_factor,
        )
        document = {
            "id": self._slugify(payload.name),
            "name": payload.name.strip(),
            "category": payload.category.strip(),
            "unit": payload.unit.strip().lower(),
            "standardUnit": standard_unit,
            "conversionFactor": conversion_factor,
            "price": price,
            "priceUnitQuantity": price_unit_quantity,
            "unitPrice": unit_price,
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
            row_price = self._row_ingredient_price(row)
            row_price_unit_quantity = self._row_ingredient_price_unit_quantity(row)
            if row_price < 0:
                errors.append(self._import_error(index, "price", "Giá không hợp lệ.", str(row_price)))
                continue
            if row_price_unit_quantity <= 0:
                errors.append(self._import_error(index, "priceUnitQuantity", "Đơn vị phải lớn hơn 0.", str(row_price_unit_quantity)))
                continue
            payload = AdminIngredientUpsertRequest(
                name=row.name.strip(),
                category=row.category.strip(),
                unit=row.unit.strip().lower(),
                price=row_price,
                priceUnitQuantity=row_price_unit_quantity,
                availableQuantity=int(row.availableQuantity or 0),
                lowStockThreshold=int(row.lowStockThreshold or 0),
            )
            lookup_id = (row.id or "").strip() or self._slugify(payload.name)
            existing = await self._ingredients.find_one({"id": lookup_id})

            if existing is None:
                standard_unit, conversion_factor = self._normalize_unit(payload.unit)
                price = self._payload_ingredient_price(payload)
                price_unit_quantity = self._payload_ingredient_price_unit_quantity(payload)
                unit_price = self._calculate_ingredient_unit_price(
                    price,
                    price_unit_quantity,
                    conversion_factor,
                )
                document = {
                    "id": lookup_id,
                    "name": payload.name,
                    "category": payload.category,
                    "unit": payload.unit,
                    "standardUnit": standard_unit,
                    "conversionFactor": conversion_factor,
                    "price": price,
                    "priceUnitQuantity": price_unit_quantity,
                    "unitPrice": unit_price,
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
            price = self._payload_ingredient_price(payload)
            price_unit_quantity = self._payload_ingredient_price_unit_quantity(payload)
            unit_price = self._calculate_ingredient_unit_price(
                price,
                price_unit_quantity,
                conversion_factor,
            )
            await self._ingredients.update_one(
                {"id": lookup_id},
                {
                    "$set": {
                        "name": payload.name,
                        "category": payload.category,
                        "unit": payload.unit,
                        "standardUnit": standard_unit,
                        "conversionFactor": conversion_factor,
                        "price": price,
                        "priceUnitQuantity": price_unit_quantity,
                        "unitPrice": unit_price,
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
        price = self._payload_ingredient_price(payload)
        price_unit_quantity = self._payload_ingredient_price_unit_quantity(payload)
        if price < 0:
            raise ValueError("Giá không hợp lệ.")
        if price_unit_quantity <= 0:
            raise ValueError("Đơn vị phải lớn hơn 0.")
        unit_price = self._calculate_ingredient_unit_price(
            price,
            price_unit_quantity,
            conversion_factor,
        )
        await self._ingredients.update_one(
            {"id": ingredient_id},
            {
                "$set": {
                    "name": payload.name.strip(),
                    "category": payload.category.strip(),
                    "unit": payload.unit.strip().lower(),
                    "standardUnit": standard_unit,
                    "conversionFactor": conversion_factor,
                    "price": price,
                    "priceUnitQuantity": price_unit_quantity,
                    "unitPrice": unit_price,
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
        product_ids = [int(document.get("productId") or 0) for document in documents]
        products = await self._products.find(
            {"id": {"$in": product_ids}},
            {"id": 1, "optionGroups": 1},
        ).to_list(length=500)
        option_groups_by_product_id = {
            int(product.get("id") or 0): list(product.get("optionGroups") or [])
            for product in products
        }
        return [
            self._map_recipe(
                document,
                option_groups=option_groups_by_product_id.get(
                    int(document.get("productId") or 0),
                ),
            )
            for document in documents
        ]

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
        category_documents = await self._categories.find({}).to_list(length=500)
        semi_finished_categories = {
            str(document.get("category") or "")
            for document in category_documents
            if bool(document.get("isSemiFinished"))
        }
        return AdminRecipeOptionsResponse(
            products=[
                AdminProductResponse(
                    id=int(document.get("id") or 0),
                    title=str(document.get("title") or ""),
                    category=str(document.get("category") or ""),
                    priceValue=int(document.get("priceValue") or 0),
                    stockStatus=str(document.get("stockStatus") or ""),
                    imageUrl=((document.get("images") or [None])[0]),
                    isSemiFinishedCategory=str(document.get("category") or "")
                    in semi_finished_categories,
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
        product = await self._products.find_one(
            {"id": int(document.get("productId") or 0)},
            {"optionGroups": 1},
        )
        return self._map_recipe(
            document,
            option_groups=list(product.get("optionGroups") or []) if product else None,
        )

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

    async def sync_recipes(self) -> list[AdminRecipeResponse]:
        documents = await self._recipes.find({}, {"id": 1}).to_list(length=500)
        synced: set[str] = set()
        for document in documents:
            recipe_id = str(document.get("id") or "")
            if recipe_id:
                await self._sync_recipe_by_id(recipe_id, synced, set())
        return await self.list_recipes()

    async def sync_recipe(self, recipe_id: str) -> Optional[AdminRecipeResponse]:
        await self._sync_recipe_by_id(recipe_id, set(), set())
        return await self.get_recipe(recipe_id)

    async def _sync_recipe_by_id(
        self,
        recipe_id: str,
        synced: set[str],
        syncing: set[str],
    ) -> Optional[dict]:
        if recipe_id in synced:
            return await self._recipes.find_one({"id": recipe_id})
        if recipe_id in syncing:
            raise ValueError("Công thức có vòng lặp bán thành phẩm.")

        document = await self._recipes.find_one({"id": recipe_id})
        if document is None:
            return None

        syncing.add(recipe_id)
        for ingredient in document.get("ingredients", []):
            if str(ingredient.get("sourceType") or "ingredient") == "recipe":
                child_recipe_id = str(ingredient.get("ingredientId") or "")
                if child_recipe_id:
                    await self._sync_recipe_by_id(child_recipe_id, synced, syncing)

        await self._restore_missing_recipe_ingredients(document)
        payload = AdminRecipeCreateRequest(
            productId=int(document.get("productId") or 0),
            recipeType=str(document.get("recipeType") or "finished"),
            yieldQuantity=int(document.get("yieldQuantity") or 0),
            yieldUnit=str(document.get("yieldUnit") or ""),
            ingredients=[
                AdminRecipeIngredientInput(
                    ingredientId=str(item.get("ingredientId") or ""),
                    sourceType=str(item.get("sourceType") or "ingredient"),
                    quantity=int(item.get("quantity") or 0),
                    wastePercent=int(item.get("wastePercent") or 0),
                )
                for item in document.get("ingredients", [])
            ],
        )
        updated_document = await self._build_recipe_document(
            payload=payload,
            recipe_id=recipe_id,
            created_at=str(document.get("createdAt") or datetime.now(timezone.utc).isoformat()),
        )
        await self._recipes.update_one({"id": recipe_id}, {"$set": updated_document})
        syncing.remove(recipe_id)
        synced.add(recipe_id)
        return updated_document

    async def _restore_missing_recipe_ingredients(self, recipe_document: dict) -> None:
        for item in recipe_document.get("ingredients", []):
            if str(item.get("sourceType") or "ingredient") != "ingredient":
                continue
            ingredient_id = str(item.get("ingredientId") or "").strip()
            if not ingredient_id:
                continue
            if await self._ingredients.find_one({"id": ingredient_id}) is not None:
                continue

            ingredient_name = str(item.get("ingredientName") or ingredient_id).strip()
            unit = str(item.get("unit") or "g").strip().lower()
            standard_unit, conversion_factor = self._normalize_unit(unit)
            unit_price = max(1, int(item.get("unitPrice") or 1))
            now = datetime.now(timezone.utc).isoformat()
            await self._ingredients.insert_one(
                {
                    "id": ingredient_id,
                    "name": ingredient_name,
                    "category": "restored",
                    "unit": unit,
                    "standardUnit": standard_unit,
                    "conversionFactor": conversion_factor,
                    "price": unit_price,
                    "priceUnitQuantity": 1,
                    "unitPrice": unit_price,
                    "availableQuantity": 0,
                    "availableNormalizedQuantity": 0,
                    "lowStockThreshold": 0,
                    "lowStockThresholdNormalized": 0,
                    "status": self._ingredient_status(0, 0),
                    "lastUpdatedAt": now,
                    "restoredFromRecipeId": str(recipe_document.get("id") or ""),
                    "restoredFromRecipeTitle": str(recipe_document.get("productTitle") or ""),
                }
            )

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
        parsed_rows: list[dict] = []
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
            parsed_rows.append(
                {
                    "rowNumber": index,
                    "row": row,
                    "payload": payload,
                    "recipeId": row.id.strip() if row.id else "",
                    "recipeReferences": {
                        item.ingredientId
                        for item in ingredients
                        if str(item.sourceType or "ingredient").strip().lower() == "recipe"
                    },
                }
            )

        for entry in self._sort_recipe_import_rows(parsed_rows):
            row = entry["row"]
            payload = entry["payload"]
            recipe_id = entry["recipeId"]
            try:
                if recipe_id:
                    updated = await self.update_recipe(recipe_id, payload)
                    if updated is None:
                        await self._create_recipe_with_import_id(recipe_id, payload)
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
                errors.append(
                    self._import_error(
                        entry["rowNumber"],
                        "recipe",
                        str(error),
                        recipe_id or str(row.productId),
                    )
                )
        return await self._build_import_result(
            entity_type="recipe",
            created_count=created_count,
            updated_count=updated_count,
            errors=errors,
            success_message="Đã import công thức thành công.",
        )

    def _sort_recipe_import_rows(self, rows: list[dict]) -> list[dict]:
        sorted_rows: list[dict] = []
        remaining = list(rows)
        while remaining:
            remaining_ids = {
                str(item.get("recipeId") or "")
                for item in remaining
                if str(item.get("recipeId") or "")
            }
            ready = [
                item
                for item in remaining
                if not (set(item.get("recipeReferences") or set()) & remaining_ids)
            ]
            if not ready:
                ready = [remaining[0]]
            for item in ready:
                sorted_rows.append(item)
                remaining.remove(item)
        return sorted_rows

    async def _create_recipe_with_import_id(
        self,
        recipe_id: str,
        payload: AdminRecipeCreateRequest,
    ) -> AdminRecipeResponse:
        duplicate = await self._recipes.find_one(
            {"productId": payload.productId, "id": {"$ne": recipe_id}}
        )
        if duplicate is not None:
            await self._recipes.delete_one({"id": str(duplicate.get("id") or "")})
        document = await self._build_recipe_document(
            payload=payload,
            recipe_id=recipe_id,
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        await self._recipes.update_one(
            {"id": recipe_id},
            {"$set": document},
            upsert=True,
        )
        return self._map_recipe(document)

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

    def _calculate_ingredient_unit_price(
        self,
        price: int,
        price_unit_quantity: int,
        conversion_factor: int = 1,
    ) -> int:
        basis = max(1, int(price_unit_quantity or 1))
        basis *= max(1, int(conversion_factor or 1))
        return max(0, round(int(price or 0) / basis))

    def _payload_ingredient_price(self, payload: AdminIngredientUpsertRequest) -> int:
        return int(payload.price if payload.price is not None else payload.unitPrice or 0)

    def _payload_ingredient_price_unit_quantity(self, payload: AdminIngredientUpsertRequest) -> int:
        return int(payload.priceUnitQuantity if payload.priceUnitQuantity is not None else 1)

    def _row_ingredient_price(self, row: AdminIngredientExcelRow) -> int:
        return int(row.price if row.price is not None else row.unitPrice or 0)

    def _row_ingredient_price_unit_quantity(self, row: AdminIngredientExcelRow) -> int:
        return int(row.priceUnitQuantity if row.priceUnitQuantity is not None else 1)

    def _ingredient_price(self, document) -> int:
        return int(document.get("price") if document.get("price") is not None else document.get("unitPrice") or 0)

    def _ingredient_price_unit_quantity(self, document) -> int:
        return max(1, int(document.get("priceUnitQuantity") or 1))

    def _ingredient_unit_price(self, document) -> int:
        if document.get("price") is not None:
            _, conversion_factor = self._normalize_unit(str(document.get("unit") or ""))
            return self._calculate_ingredient_unit_price(
                self._ingredient_price(document),
                self._ingredient_price_unit_quantity(document),
                int(document.get("conversionFactor") or conversion_factor),
            )
        if document.get("unitPrice") is not None:
            return int(document.get("unitPrice") or 0)
        return self._calculate_ingredient_unit_price(
            self._ingredient_price(document),
            self._ingredient_price_unit_quantity(document),
            int(document.get("conversionFactor") or 1),
        )

    def _map_ingredient(self, document) -> AdminIngredientResponse:
        quantity = int(document.get("availableQuantity") or 0)
        threshold = int(document.get("lowStockThreshold") or 0)
        standard_unit, conversion_factor = self._normalize_unit(str(document.get("unit") or ""))
        normalized_quantity = int(document.get("availableNormalizedQuantity") or quantity * conversion_factor)
        normalized_threshold = int(document.get("lowStockThresholdNormalized") or threshold * conversion_factor)
        price = self._ingredient_price(document)
        price_unit_quantity = self._ingredient_price_unit_quantity(document)
        return AdminIngredientResponse(
            id=str(document.get("id") or ""),
            name=str(document.get("name") or ""),
            category=str(document.get("category") or ""),
            unit=str(document.get("unit") or ""),
            standardUnit=str(document.get("standardUnit") or standard_unit),
            conversionFactor=int(document.get("conversionFactor") or conversion_factor),
            price=price,
            priceUnitQuantity=price_unit_quantity,
            unitPrice=self._ingredient_unit_price(document),
            availableQuantity=quantity,
            availableNormalizedQuantity=normalized_quantity,
            lowStockThreshold=threshold,
            lowStockThresholdNormalized=normalized_threshold,
            status=str(document.get("status") or self._ingredient_status(quantity, threshold)),
            lastUpdatedAt=str(document.get("lastUpdatedAt") or ""),
        )

    def _map_recipe(
        self,
        document,
        *,
        option_groups: Optional[list[dict]] = None,
    ) -> AdminRecipeResponse:
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
            sellingPrice=product_price,
            grossProfitEstimate=gross_profit,
            grossMarginPercent=gross_margin,
            optionGroups=list(option_groups if option_groups is not None else document.get("optionGroups") or []),
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
        product_category = str(product.get("category") or "")
        product_category_document = await self._categories.find_one({"category": product_category})
        recipe_type = (
            "semi_finished"
            if product_category_document is not None
            and bool(product_category_document.get("isSemiFinished"))
            else payload.recipeType.strip() or "finished"
        )

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
                standard_unit, _ = self._normalize_unit(str(ingredient.get("unit") or ""))
                unit_price = self._ingredient_unit_price(ingredient)
                normalized_quantity = int(item.quantity or 0)
                ingredient_name = str(ingredient.get("name") or "")
                unit = str(ingredient.get("standardUnit") or standard_unit)
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
            "recipeType": recipe_type,
            "yieldQuantity": yield_quantity,
            "yieldUnit": payload.yieldUnit.strip(),
            "ingredients": recipe_ingredients,
            "totalCost": total_cost,
            "costPerUnit": cost_per_unit,
            "sellingPrice": int(product.get("priceValue") or 0),
            "optionGroups": list(product.get("optionGroups") or []),
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
            ingredientsText=row.ingredientsText.strip(),
            optionGroups=json.loads(row.optionGroupsJson or "[]")
            if (row.optionGroupsJson or "").strip()
            else [],
        )

    def _map_category_response(self, document: dict) -> AdminCategoryResponse:
        return AdminCategoryResponse(
            id=str(document.get("id") or ""),
            label=str(document.get("label") or ""),
            category=str(document.get("category") or ""),
            imageUrl=document.get("imageUrl"),
            isSemiFinished=bool(document.get("isSemiFinished", False)),
            isVisibleOnWeb=bool(document.get("isVisibleOnWeb", True)),
            sortOrder=int(document.get("sortOrder") or 0),
        )

    def _build_category_document(
        self,
        payload: AdminCategoryUpsertRequest,
        *,
        category_id: Optional[str] = None,
    ) -> dict:
        label = payload.label.strip()
        category = payload.category.strip()
        document_id = category_id or self._slugify(category or label)
        return {
            "id": document_id,
            "label": label,
            "category": category,
            "imageUrl": payload.imageUrl.strip() if payload.imageUrl else None,
            "isSemiFinished": bool(payload.isSemiFinished),
            "isVisibleOnWeb": bool(payload.isVisibleOnWeb),
            "sortOrder": int(payload.sortOrder or 0),
        }

    async def _product_stock_status_for_category(
        self,
        category: str,
        requested_status: str,
    ) -> str:
        category_document = await self._categories.find_one({"category": category.strip()})
        if category_document and bool(category_document.get("isSemiFinished", False)):
            return "Tạm ẩn"
        return requested_status.strip()

    async def _build_product_document(
        self,
        payload: AdminProductUpsertRequest,
        *,
        product_id: int,
        existing: Optional[dict] = None,
    ) -> dict:
        price_value = int(payload.priceValue or 0)
        images = [item.strip() for item in payload.images if item.strip()]
        detail_bullets = [item.strip() for item in payload.detailBullets if item.strip()]
        option_groups = self._normalize_product_option_groups(payload.optionGroups)
        existing_reviews = list(existing.get("reviews", [])) if existing else []
        existing_related = list(existing.get("relatedProductIds", [])) if existing else []
        stock_status = await self._product_stock_status_for_category(
            payload.category,
            payload.stockStatus,
        )
        return {
            "id": product_id,
            "title": payload.title.strip(),
            "price": self._format_currency(price_value),
            "priceValue": price_value,
            "category": payload.category.strip(),
            "description": payload.description.strip(),
            "images": images,
            "sku": payload.sku.strip(),
            "stockStatus": stock_status,
            "weight": payload.weight.strip(),
            "storageNote": payload.storageNote.strip(),
            "deliveryNote": payload.deliveryNote.strip(),
            "detailBullets": detail_bullets,
            "ingredientsText": payload.ingredientsText.strip(),
            "optionGroups": option_groups,
            "reviews": existing_reviews,
            "relatedProductIds": existing_related,
        }

    def _normalize_product_option_groups(self, raw_groups: list[dict]) -> list[dict]:
        groups: list[dict] = []
        for group_index, raw_group in enumerate(raw_groups or []):
            if not isinstance(raw_group, dict):
                continue
            raw_options = raw_group.get("options")
            if not isinstance(raw_options, list):
                continue
            label = str(raw_group.get("label") or "").strip()
            group_id = str(raw_group.get("id") or "").strip()
            if not label:
                continue
            if not group_id:
                group_id = self._slugify(label) or f"group-{group_index + 1}"

            options: list[dict] = []
            default_index = -1
            for option_index, raw_option in enumerate(raw_options):
                if not isinstance(raw_option, dict):
                    continue
                option_label = str(raw_option.get("label") or "").strip()
                option_id = str(raw_option.get("id") or "").strip()
                if not option_label:
                    continue
                if not option_id:
                    option_id = self._slugify(option_label) or f"option-{option_index + 1}"
                try:
                    price_delta = int(raw_option.get("priceDelta") or 0)
                except (TypeError, ValueError):
                    price_delta = 0
                is_default = bool(raw_option.get("isDefault", False))
                if is_default and default_index == -1:
                    default_index = len(options)
                options.append(
                    {
                        "id": option_id,
                        "label": option_label,
                        "priceDelta": price_delta,
                        "isDefault": is_default,
                    }
                )
            if not options:
                continue
            if default_index == -1:
                default_index = 0
            for index, option in enumerate(options):
                option["isDefault"] = index == default_index
            groups.append(
                {
                    "id": group_id,
                    "label": label,
                    "options": options,
                }
            )
        return groups


def get_admin_repository() -> AdminRepository:
    return AdminRepository(get_database())
