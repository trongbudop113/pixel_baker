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

    async def get_menu_page(self) -> MenuPageResponse:
        document = await self._page_collection.find_one({"slug": "main"})
        if document is None:
            raise RuntimeError("Menu page seed data is missing.")

        cloned = _strip_mongo_fields(document)
        cloned.pop("slug", None)
        product_documents = await self._collection.find({}).sort("id", 1).to_list(length=None)
        cloned["products"] = [
            self._map_product_response(_strip_mongo_fields(item)).model_dump()
            for item in product_documents
        ]
        return MenuPageResponse.model_validate(cloned)

    async def list_products(
        self,
        category: Optional[str] = None,
    ) -> List[MenuProductResponse]:
        query: Dict[str, str] = {}
        if category:
            query["category"] = category

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
        cloned = _strip_mongo_fields(document)
        related_ids = cloned.pop("relatedProductIds", [])
        cloned["relatedProducts"] = await self._load_related_products(related_ids)
        cloned["averageRating"] = self._average_rating(cloned.get("reviews", []))
        cloned["reviewCount"] = len(cloned.get("reviews", []))
        return MenuProductDetailResponse.model_validate(cloned)

    async def add_review(
        self,
        product_id: int,
        *,
        author: str,
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
            ).model_dump(),
        )
        await self._collection.update_one({"id": product_id}, {"$set": {"reviews": reviews}})
        return await self.get_product_by_id(product_id)

    async def _load_related_products(
        self,
        related_ids: List[int],
    ) -> List[Dict]:
        if not related_ids:
            return []

        documents = await self._collection.find({"id": {"$in": related_ids}}).to_list(length=None)
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

    def _average_rating(self, reviews: List[Dict]) -> float:
        if not reviews:
            return 0
        total = sum(max(1, min(5, int(item.get("rating") or 0))) for item in reviews)
        return round(total / len(reviews), 1)


def get_menu_repository() -> MenuRepository:
    return MenuRepository(get_database())


def _strip_mongo_fields(document: Dict) -> Dict:
    cloned = dict(document)
    cloned.pop("_id", None)
    return cloned
