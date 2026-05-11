import asyncio
import json
from pathlib import Path
import sys

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.core.database import close_mongo_connection, connect_to_mongo, get_database

HOME_PAGE_PATH = BACKEND_DIR / "data" / "home_page.json"


async def import_home_page() -> None:
    try:
        await connect_to_mongo()
        database = get_database()
        collection = database["home_pages"]
        testimonial_collection = database["home_testimonials"]

        with HOME_PAGE_PATH.open("r", encoding="utf-8") as file:
            document = json.load(file)

        await collection.update_one(
            {"slug": "main"},
            {"$set": {"slug": "main", **document}},
            upsert=True,
        )
        await testimonial_collection.delete_many({})
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
        print("Imported home page data into MongoDB collection: home_pages")
    except Exception as error:
        raise RuntimeError(
            "Failed to import home page data. Check MONGODB_URI and ensure MongoDB is running."
        ) from error
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(import_home_page())
