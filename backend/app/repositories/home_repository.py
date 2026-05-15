from datetime import datetime, timezone
from typing import Dict, List
from uuid import uuid4

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.auth import UserResponse
from app.models.common import UiAccent
from app.models.home import CreateHomeTestimonialRequest, HomePageResponse, HomeTestimonial


class HomeRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["home_pages"]
        self._testimonial_collection = database["home_testimonials"]
        self._menu_collection = database["menu_products"]

    async def get_home_page(self) -> HomePageResponse:
        document = await self._collection.find_one({"slug": "main"})
        if document is None:
            raise RuntimeError("Home page seed data is missing.")

        document.pop("_id", None)
        document.pop("slug", None)
        document["featuredProducts"] = await self._map_featured_products(
            document.get("featuredProducts", [])
        )
        return HomePageResponse.model_validate(document)

    async def list_testimonials(self) -> list[HomeTestimonial]:
        cursor = self._testimonial_collection.find(
            {"$or": [{"isVisible": True}, {"isVisible": {"$exists": False}}]}
        ).sort("createdAt", -1)
        documents = await cursor.to_list(length=100)
        return [self._to_testimonial(document) for document in documents]

    async def create_testimonial(
        self,
        user: UserResponse,
        payload: CreateHomeTestimonialRequest,
    ) -> HomeTestimonial:
        content = payload.content.strip()
        document = {
            "id": uuid4().hex,
            "content": content,
            "author": user.fullName,
            "accent": self._accent_for_author(user.fullName).value,
            "createdAt": datetime.now(timezone.utc),
            "isVisible": True,
        }
        await self._testimonial_collection.insert_one(document)
        return self._to_testimonial(document)

    def _to_testimonial(self, document) -> HomeTestimonial:
        return HomeTestimonial(
            id=document.get("id"),
            content=document.get("content", ""),
            author=document.get("author", ""),
            accent=UiAccent(document.get("accent", "gray")),
            createdAt=document.get("createdAt"),
        )

    def _accent_for_author(self, author: str) -> UiAccent:
        palette = [UiAccent.red, UiAccent.blue, UiAccent.green]
        if not author:
            return UiAccent.gray
        return palette[sum(author.encode("utf-8")) % len(palette)]

    async def _map_featured_products(self, items: List[Dict]) -> List[Dict]:
        if not items:
            return []
        # Batch fetch all products in 1 query (fix N+1)
        product_ids = [item.get("productId") for item in items if item.get("productId") is not None]
        docs = await self._menu_collection.find(
            {"id": {"$in": product_ids}},
            {"id": 1, "reviews": 1, "images": 1}
        ).to_list(length=len(product_ids) + 5)
        doc_map = {int(d.get("id") or 0): d for d in docs}

        mapped: List[Dict] = []
        for item in items:
            item = dict(item)
            pid = item.get("productId")
            doc = doc_map.get(int(pid)) if pid is not None else None
            if doc is None:
                item.setdefault("averageRating", 0)
                item.setdefault("reviewCount", 0)
            else:
                reviews = doc.get("reviews", [])
                images = doc.get("images", [])
                if images and not item.get("imageUrl"):
                    item["imageUrl"] = str(images[0])
                item["averageRating"] = self._average_rating(reviews)
                item["reviewCount"] = len(reviews)
            mapped.append(item)
        return mapped

    def _average_rating(self, reviews: List[Dict]) -> float:
        if not reviews:
            return 0
        total = sum(max(1, min(5, int(review.get("rating") or 5))) for review in reviews)
        return round(total / len(reviews), 1)


def get_home_repository() -> HomeRepository:
    return HomeRepository(get_database())
