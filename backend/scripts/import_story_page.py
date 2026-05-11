import asyncio
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.core.database import close_database_connection, get_database, ping_database

STORY_PAGE_PATH = ROOT_DIR / "data" / "story_page.json"


async def main() -> None:
    database = get_database()
    await ping_database()

    with STORY_PAGE_PATH.open("r", encoding="utf-8") as file:
      document = json.load(file)

    await database["story_pages"].update_one(
        {"slug": "main"},
        {"$set": {"slug": "main", **document}},
        upsert=True,
    )

    print("Imported story page data into story_pages.")
    await close_database_connection()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as error:
        print(
            "Failed to import story page data. "
            "Check MONGODB_URI and ensure MongoDB is running.",
            file=sys.stderr,
        )
        print(str(error), file=sys.stderr)
        raise
