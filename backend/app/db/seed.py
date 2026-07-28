import json
from pathlib import Path
from datetime import datetime, timezone

from app.core.security import hash_password
from app.core.database import get_database

HOME_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "home_page.json"
MENU_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "menu_page.json"
LOGIN_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "login_page.json"
REGISTER_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "register_page.json"
CONTACT_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "contact_page.json"
STORY_PAGE_PATH = Path(__file__).resolve().parents[2] / "data" / "story_page.json"
VOUCHERS_PATH = Path(__file__).resolve().parents[2] / "data" / "vouchers.json"
ADMIN_INGREDIENTS_PATH = Path(__file__).resolve().parents[2] / "data" / "admin_ingredients.json"


async def seed_initial_data() -> None:
    database = get_database()
    await _seed_home_page(database)
    await _seed_menu_page(database)
    await _seed_auth_pages(database)
    await _seed_contact_page(database)
    await _seed_story_page(database)
    await _seed_vouchers(database)
    await _seed_admin_ingredients(database)
    await _seed_admin_user(database)


async def _seed_home_page(database) -> None:
    collection = database["home_pages"]
    testimonial_collection = database["home_testimonials"]
    with HOME_PAGE_PATH.open("r", encoding="utf-8") as file:
        document = json.load(file)

    await collection.update_one(
        {"slug": "main"},
        {"$set": {"slug": "main", **document}},
        upsert=True,
    )

    if await testimonial_collection.count_documents({}) == 0:
        for index, testimonial in enumerate(document.get("testimonials", [])):
            await testimonial_collection.insert_one(
                {
                    "id": f"seed-home-testimonial-{index + 1}",
                    "content": testimonial.get("content", ""),
                    "author": testimonial.get("author", ""),
                    "accent": testimonial.get("accent", "gray"),
                    "createdAt": None,
                }
            )


async def _seed_menu_page(database) -> None:
    page_collection = database["menu_pages"]
    product_collection = database["menu_products"]
    category_collection = database["menu_categories"]

    with MENU_PAGE_PATH.open("r", encoding="utf-8") as file:
        document = json.load(file)

    await page_collection.update_one(
        {"slug": "main"},
        {"$set": {"slug": "main", **document}},
        upsert=True,
    )

    for product in document.get("products", []):
        await product_collection.update_one(
            {"id": product["id"]},
            {"$set": product},
            upsert=True,
        )

    for index, category in enumerate(document.get("filters", [])):
        category_value = str(category.get("category") or "").strip()
        if not category_value:
            continue
        await category_collection.update_one(
            {"id": _slugify(category_value)},
            {
                "$set": {
                    "id": _slugify(category_value),
                    "label": str(category.get("label") or category_value).strip(),
                    "category": category_value,
                    "imageUrl": category.get("imageUrl"),
                    "sortOrder": index,
                }
            },
            upsert=True,
        )


async def _seed_auth_pages(database) -> None:
    collection = database["auth_pages"]
    for slug, path in (
        ("login", LOGIN_PAGE_PATH),
        ("register", REGISTER_PAGE_PATH),
    ):
        with path.open("r", encoding="utf-8") as file:
            document = json.load(file)

        await collection.update_one(
            {"slug": slug},
            {"$set": {"slug": slug, **document}},
            upsert=True,
        )


async def _seed_contact_page(database) -> None:
    collection = database["contact_pages"]
    with CONTACT_PAGE_PATH.open("r", encoding="utf-8") as file:
        document = json.load(file)

    await collection.update_one(
        {"slug": "main"},
        {"$set": {"slug": "main", **document}},
        upsert=True,
    )


async def _seed_story_page(database) -> None:
    collection = database["story_pages"]
    with STORY_PAGE_PATH.open("r", encoding="utf-8") as file:
        document = json.load(file)

    await collection.update_one(
        {"slug": "main"},
        {"$set": {"slug": "main", **document}},
        upsert=True,
    )


async def _seed_vouchers(database) -> None:
    collection = database["vouchers"]
    with VOUCHERS_PATH.open("r", encoding="utf-8") as file:
        documents = json.load(file)

    for document in documents:
        await collection.update_one(
            {"code": document["code"]},
            {"$set": document},
            upsert=True,
        )


async def _seed_admin_ingredients(database) -> None:
    collection = database["admin_ingredients"]
    with ADMIN_INGREDIENTS_PATH.open("r", encoding="utf-8") as file:
        documents = json.load(file)

    now = datetime.now(timezone.utc).isoformat()
    for document in documents:
        quantity = int(document.get("availableQuantity") or 0)
        threshold = int(document.get("lowStockThreshold") or 0)
        price = int(document.get("price") if document.get("price") is not None else document.get("unitPrice") or 0)
        price_unit_quantity = max(1, int(document.get("priceUnitQuantity") or 1))
        await collection.update_one(
            {"id": document["id"]},
            {
                "$set": {
                    **document,
                    "price": price,
                    "priceUnitQuantity": price_unit_quantity,
                    "unitPrice": round(price / price_unit_quantity),
                    "availableQuantity": quantity,
                    "lowStockThreshold": threshold,
                    "status": _resolve_ingredient_status(quantity, threshold),
                    "lastUpdatedAt": now,
                }
            },
            upsert=True,
        )


async def _seed_admin_user(database) -> None:
    collection = database["users"]
    await collection.update_one(
        {"email": "admin@gmail.com"},
        {
            "$set": {
                "fullName": "Admin Pixel Bakery",
                "email": "admin@gmail.com",
                "phone": None,
                "address": None,
                "role": "admin",
                "isAdmin": True,
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "hashedPassword": hash_password("123456"),
            },
            "$setOnInsert": {
                "id": "admin-pixel-bakery",
                "accessToken": None,
                "refreshToken": None,
                "accessTokenExpiresAt": None,
                "refreshTokenExpiresAt": None,
            },
        },
        upsert=True,
    )


def _resolve_ingredient_status(quantity: int, threshold: int) -> str:
    if quantity <= 0:
        return "Hết hàng"
    if quantity <= threshold:
        return "Sắp hết"
    return "Đủ hàng"


def _slugify(value: str) -> str:
    normalized = value.strip().lower()
    normalized = "".join(char if char.isalnum() else "-" for char in normalized)
    while "--" in normalized:
        normalized = normalized.replace("--", "-")
    return normalized.strip("-") or "category"
