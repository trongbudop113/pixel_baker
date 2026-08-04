from datetime import datetime, timezone
from typing import Dict, List, Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.menu import (
    MenuPageResponse,
    MenuReviewCreateRequest,
    MenuReviewItem,
    MenuProductDetailResponse,
    MenuProductResponse,
)


class MenuRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._page_collection = database["menu_pages"]
        self._collection = database["menu_products"]
        self._category_collection = database["menu_categories"]
        self._recipe_collection = database["admin_recipes"]

    async def get_menu_page(self) -> MenuPageResponse:
        document = await self._page_collection.find_one({"slug": "main"})
        if document is None:
            raise RuntimeError("Menu page seed data is missing.")

        cloned = _strip_mongo_fields(document)
        cloned.pop("slug", None)
        category_documents = await self._category_collection.find({}).sort("sortOrder", 1).to_list(length=None)
        visible_category_documents = [
            item for item in category_documents if self._is_public_category(item)
        ]
        hidden_categories = self._hidden_category_values(category_documents)
        product_query: Dict[str, Dict[str, List[str]]] = {}
        if hidden_categories:
            product_query["category"] = {"$nin": list(hidden_categories)}
        product_documents = await self._collection.find(product_query).sort("id", 1).to_list(length=None)
        if category_documents:
            cloned["filters"] = [
                {
                    "label": str(item.get("label") or ""),
                    "category": str(item.get("category") or ""),
                    "imageUrl": item.get("imageUrl"),
                }
                for item in visible_category_documents
            ]
        cloned["products"] = [
            self._map_product_response(_strip_mongo_fields(item)).model_dump()
            for item in product_documents
        ]
        return MenuPageResponse.model_validate(cloned)

    async def list_products(
        self,
        category: Optional[str] = None,
    ) -> List[MenuProductResponse]:
        hidden_categories = await self._hidden_web_categories()
        if category and category in hidden_categories:
            return []

        query: Dict[str, object] = {}
        if category:
            query["category"] = category
        elif hidden_categories:
            query["category"] = {"$nin": list(hidden_categories)}

        cursor = self._collection.find(query).sort("id", 1)
        results = await cursor.to_list(length=None)
        return [
            self._map_product_response(_strip_mongo_fields(item))
            for item in results
        ]

    async def get_product_by_id(
        self,
        product_id: int,
    ) -> Optional[MenuProductDetailResponse]:
        document = await self._collection.find_one({"id": product_id})
        if document is None:
            return None
        hidden_categories = await self._hidden_web_categories()
        if str(document.get("category") or "") in hidden_categories:
            return None
        cloned = _strip_mongo_fields(document)
        related_ids = cloned.pop("relatedProductIds", [])
        cloned["relatedProducts"] = await self._load_related_products(related_ids)
        cloned["averageRating"] = self._average_rating(cloned.get("reviews", []))
        cloned["reviewCount"] = len(cloned.get("reviews", []))
        if not cloned.get("optionGroups"):
            cloned["optionGroups"] = await self._auto_option_groups_from_recipe(product_id)
        return MenuProductDetailResponse.model_validate(cloned)

    async def _auto_option_groups_from_recipe(self, product_id: int) -> list[dict]:
        recipe = await self._recipe_collection.find_one({"productId": product_id})
        if recipe is None:
            return []

        yield_quantity = max(1, int(recipe.get("yieldQuantity") or 1))
        semi_finished_items = [
            item
            for item in recipe.get("ingredients", [])
            if str(item.get("sourceType") or "ingredient") == "recipe"
        ]
        if len(semi_finished_items) < 2:
            return []

        options = [
            {
                "id": "all",
                "label": "Tất cả: "
                + ", ".join(str(item.get("ingredientName") or "") for item in semi_finished_items),
                "priceDelta": 0,
                "isDefault": True,
            }
        ]
        total_unit_cost = sum(
            round(int(item.get("lineCost") or 0) / yield_quantity)
            for item in semi_finished_items
        )
        optional_items = [
            item for item in semi_finished_items if self._is_optional_combine_item(item)
        ]
        option_source_items = optional_items or semi_finished_items
        single_choice_multiplier = len(option_source_items) if not optional_items else 1
        for item in option_source_items:
            name = str(item.get("ingredientName") or "").strip()
            if not name:
                continue
            item_unit_cost = round(int(item.get("lineCost") or 0) / yield_quantity)
            if optional_items:
                price_delta = -item_unit_cost
                label = f"Không {name}"
            else:
                replacement_cost = item_unit_cost * single_choice_multiplier
                price_delta = replacement_cost - total_unit_cost
                label = (
                    f"Chỉ {name} (x{single_choice_multiplier})"
                    if single_choice_multiplier > 1
                    else f"Chỉ {name}"
                )
            options.append(
                {
                    "id": str(item.get("ingredientId") or "").strip() or self._slugify(name),
                    "label": label,
                    "priceDelta": price_delta,
                    "isDefault": False,
                }
            )

        return [
            {
                "id": "semi-finished-combine",
                "label": "Chọn bán thành phẩm",
                "options": options,
            }
        ]

    async def add_review(
        self,
        product_id: int,
        *,
        author: str,
        user_id: Optional[str] = None,
        payload: MenuReviewCreateRequest,
    ) -> Optional[MenuProductDetailResponse]:
        document = await self._collection.find_one({"id": product_id})
        if document is None:
            return None
        reviews = list(document.get("reviews", []))
        reviews.insert(
            0,
            MenuReviewItem(
                author=author,
                content=payload.content.strip(),
                rating=max(1, min(5, int(payload.rating))),
                mediaUrls=[item.strip() for item in payload.mediaUrls if item.strip()],
                createdAt=datetime.now(timezone.utc).isoformat(),
                userId=user_id,
            ).model_dump(),
        )
        await self._collection.update_one({"id": product_id}, {"$set": {"reviews": reviews}})
        return await self.get_product_by_id(product_id)

    async def delete_own_review(self, product_id: int, created_at: str, user_id: str) -> Optional[MenuProductDetailResponse]:
        document = await self._collection.find_one({"id": product_id})
        if document is None:
            return None
        reviews = [r for r in document.get("reviews", [])
                   if not (str(r.get("createdAt") or "") == created_at and str(r.get("userId") or "") == user_id)]
        await self._collection.update_one({"id": product_id}, {"$set": {"reviews": reviews}})
        return await self.get_product_by_id(product_id)

    async def update_own_review(self, product_id: int, created_at: str, user_id: str, payload: MenuReviewCreateRequest) -> Optional[MenuProductDetailResponse]:
        document = await self._collection.find_one({"id": product_id})
        if document is None:
            return None
        reviews = list(document.get("reviews", []))
        updated = False
        for review in reviews:
            if str(review.get("createdAt") or "") == created_at and str(review.get("userId") or "") == user_id:
                review["content"] = payload.content.strip()
                review["rating"] = max(1, min(5, int(payload.rating)))
                updated = True
                break
        if not updated:
            return None
        await self._collection.update_one({"id": product_id}, {"$set": {"reviews": reviews}})
        return await self.get_product_by_id(product_id)

    async def _load_related_products(
        self,
        related_ids: List[int],
    ) -> List[Dict]:
        if not related_ids:
            return []

        hidden_categories = await self._hidden_web_categories()
        query: Dict[str, object] = {"id": {"$in": related_ids}}
        if hidden_categories:
            query["category"] = {"$nin": list(hidden_categories)}
        documents = await self._collection.find(query).to_list(length=None)
        mapped = {
            item["id"]: self._map_product_response(_strip_mongo_fields(item)).model_dump()
            for item in documents
        }
        return [mapped[item_id] for item_id in related_ids if item_id in mapped]

    def _map_product_response(self, document: Dict) -> MenuProductResponse:
        cloned = dict(document)
        reviews = cloned.get("reviews", [])
        cloned["averageRating"] = self._average_rating(reviews)
        cloned["reviewCount"] = len(reviews)
        return MenuProductResponse.model_validate(cloned)

    async def _hidden_web_categories(self) -> set[str]:
        documents = await self._category_collection.find(
            {"$or": [{"isVisibleOnWeb": False}, {"isSemiFinished": True}]}
        ).to_list(length=None)
        return self._hidden_category_values(documents)

    def _hidden_category_values(self, documents: List[Dict]) -> set[str]:
        return {
            str(item.get("category") or "")
            for item in documents
            if not self._is_public_category(item)
        }

    def _is_public_category(self, document: Dict) -> bool:
        return bool(document.get("isVisibleOnWeb", True)) and not bool(
            document.get("isSemiFinished", False)
        )

    def _average_rating(self, reviews: List[Dict]) -> float:
        if not reviews:
            return 0
        total = sum(max(1, min(5, int(item.get("rating") or 5))) for item in reviews)
        return round(total / len(reviews), 1)

    def _is_optional_combine_item(self, item: Dict) -> bool:
        name = str(item.get("ingredientName") or "").lower()
        return any(keyword in name for keyword in ["phủ", "topping", "trang trí"])

    def _slugify(self, value: str) -> str:
        normalized = value.strip().lower()
        normalized = "".join(
            char if char.isalnum() else "-"
            for char in normalized
        )
        while "--" in normalized:
            normalized = normalized.replace("--", "-")
        return normalized.strip("-")


def get_menu_repository() -> MenuRepository:
    return MenuRepository(get_database())


def _strip_mongo_fields(document: Dict) -> Dict:
    cloned = dict(document)
    cloned.pop("_id", None)
    return cloned
