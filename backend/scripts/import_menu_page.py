import asyncio
import json
from pathlib import Path
import sys

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.core.database import close_mongo_connection, connect_to_mongo, get_database

MENU_PAGE_PATH = BACKEND_DIR / "data" / "menu_page.json"


async def import_menu_page() -> None:
    try:
        await connect_to_mongo()
        database = get_database()
        page_collection = database["menu_pages"]
        product_collection = database["menu_products"]

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

        print("Imported menu page data into MongoDB collections: menu_pages, menu_products")
    except Exception as error:
        raise RuntimeError(
            "Failed to import menu page data. Check MONGODB_URI and ensure MongoDB is running."
        ) from error
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(import_menu_page())
