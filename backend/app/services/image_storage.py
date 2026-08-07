import base64
import io
import json
import os
import uuid
from dataclasses import dataclass

from app.core.config import settings


@dataclass(frozen=True)
class StoredImage:
    url: str


@dataclass(frozen=True)
class DriveImage:
    id: str
    name: str
    url: str
    thumbnailUrl: str
    createdAt: str


class LocalImageStorage:
    def __init__(self, upload_dir: str):
        self._upload_dir = upload_dir

    async def save(
        self,
        *,
        contents: bytes,
        original_filename: str,
        content_type: str,
    ) -> StoredImage:
        del content_type
        filename = _safe_image_filename(original_filename)
        os.makedirs(self._upload_dir, exist_ok=True)
        filepath = os.path.join(self._upload_dir, filename)
        with open(filepath, "wb") as file:
            file.write(contents)
        return StoredImage(url=f"/uploads/{filename}")


class GoogleDriveImageStorage:
    def __init__(self, folder_id: str):
        self._folder_id = folder_id.strip()

    async def save(
        self,
        *,
        contents: bytes,
        original_filename: str,
        content_type: str,
    ) -> StoredImage:
        if not self._folder_id:
            raise RuntimeError("GOOGLE_DRIVE_FOLDER_ID is missing.")

        from googleapiclient.errors import HttpError
        from googleapiclient.http import MediaIoBaseUpload

        service = _google_drive_service()
        filename = _safe_image_filename(original_filename)
        media = MediaIoBaseUpload(
            io.BytesIO(contents),
            mimetype=content_type,
            resumable=False,
        )
        try:
            created = (
                service.files()
                .create(
                    body={"name": filename, "parents": [self._folder_id]},
                    media_body=media,
                    fields="id",
                    supportsAllDrives=True,
                )
                .execute()
            )
        except HttpError as error:
            raise RuntimeError(
                "Google Drive từ chối upload. Nếu dùng service account, hãy lưu ảnh trong Shared Drive "
                "hoặc dùng OAuth của tài khoản Google thật."
            ) from error
        except Exception as error:
            if "invalid_grant" in str(error):
                raise RuntimeError(
                    "Google Drive OAuth token không hợp lệ. Hãy kiểm tra "
                    "GOOGLE_DRIVE_OAUTH_CLIENT_ID, GOOGLE_DRIVE_OAUTH_CLIENT_SECRET và "
                    "GOOGLE_DRIVE_OAUTH_REFRESH_TOKEN có cùng một OAuth client không."
                ) from error
            raise
        file_id = created["id"]
        try:
            service.permissions().create(
                fileId=file_id,
                body={"role": "reader", "type": "anyone"},
                fields="id",
                supportsAllDrives=True,
            ).execute()
        except HttpError as error:
            raise RuntimeError(
                "Không thể public ảnh trên Google Drive. Kiểm tra quyền share công khai của folder."
            ) from error
        return StoredImage(url=f"https://lh3.googleusercontent.com/d/{file_id}")


def image_storage(upload_dir: str):
    provider = settings.image_storage_provider.strip().lower()
    if provider in {"google_drive", "drive"}:
        return GoogleDriveImageStorage(settings.google_drive_folder_id)
    return LocalImageStorage(upload_dir)


async def list_drive_images(limit: int = 60) -> list[DriveImage]:
    if not settings.google_drive_folder_id.strip():
        raise RuntimeError("GOOGLE_DRIVE_FOLDER_ID is missing.")

    service = _google_drive_service()
    query = (
        f"'{settings.google_drive_folder_id.strip()}' in parents "
        "and trashed = false and mimeType contains 'image/'"
    )
    response = (
        service.files()
        .list(
            q=query,
            pageSize=max(1, min(limit, 100)),
            orderBy="createdTime desc",
            fields="files(id,name,mimeType,thumbnailLink,createdTime)",
            supportsAllDrives=True,
            includeItemsFromAllDrives=True,
        )
        .execute()
    )
    images: list[DriveImage] = []
    for file in response.get("files", []):
        file_id = str(file.get("id", "")).strip()
        if not file_id:
            continue
        images.append(
            DriveImage(
                id=file_id,
                name=str(file.get("name") or "Ảnh Google Drive"),
                url=f"https://lh3.googleusercontent.com/d/{file_id}",
                thumbnailUrl=str(file.get("thumbnailLink") or f"https://lh3.googleusercontent.com/d/{file_id}"),
                createdAt=str(file.get("createdTime") or ""),
            )
        )
    return images


def _safe_image_filename(original_filename: str) -> str:
    ext = (original_filename or "image.jpg").rsplit(".", 1)[-1].lower()
    if ext not in {"jpg", "jpeg", "png", "webp", "gif"}:
        ext = "jpg"
    return f"{uuid.uuid4().hex}.{ext}"


def _google_drive_service():
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    scopes = ["https://www.googleapis.com/auth/drive"]
    credentials = _google_oauth_credentials(scopes)
    if credentials is None:
        credentials = service_account.Credentials.from_service_account_info(
            _google_service_account_info(),
            scopes=scopes,
        )
    return build("drive", "v3", credentials=credentials, cache_discovery=False)


def _google_service_account_info() -> dict:
    if settings.google_drive_service_account_base64.strip():
        decoded = base64.b64decode(settings.google_drive_service_account_base64)
        return json.loads(decoded.decode("utf-8"))
    if settings.google_drive_service_account_json.strip():
        return json.loads(settings.google_drive_service_account_json)
    raise RuntimeError("Google Drive service account credentials are missing.")


def _google_oauth_credentials(scopes: list[str]):
    if not settings.google_drive_oauth_refresh_token.strip():
        return None
    if (
        not settings.google_drive_oauth_client_id.strip()
        or not settings.google_drive_oauth_client_secret.strip()
    ):
        raise RuntimeError("Google Drive OAuth client id/secret are missing.")

    from google.oauth2.credentials import Credentials

    return Credentials(
        token=None,
        refresh_token=settings.google_drive_oauth_refresh_token.strip(),
        token_uri="https://oauth2.googleapis.com/token",
        client_id=settings.google_drive_oauth_client_id.strip(),
        client_secret=settings.google_drive_oauth_client_secret.strip(),
        scopes=scopes,
    )
