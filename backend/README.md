# Pixel Bakery Backend

FastAPI + MongoDB backend scaffolded for the Flutter frontend in this repo.

## Included APIs

- `GET /api/v1/health`
- `GET /api/v1/home`
- `GET /api/v1/menu`
- `GET /api/v1/menu/products`
- `GET /api/v1/menu/products/{product_id}`
- `GET /api/v1/auth/pages/login`
- `GET /api/v1/auth/pages/register`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

## Run locally

1. Copy env file:

```bash
cp .env.example .env
```

2. Start MongoDB:

```bash
docker compose up -d
```

3. Install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

4. Run the API:

```bash
python -m uvicorn app.main:app --reload --port 8000
```

## Frontend integration

Point Flutter to the backend:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

The menu repository in the Flutter app already matches:

- `GET /menu/products`
- `GET /menu/products/{id}`

## Observability stack

Docker container metrics are available through the observability stack:

```bash
make obs-up
```

- Grafana: http://localhost:3000, default login `admin` / `admin`
- Prometheus: http://localhost:9090
- cAdvisor: http://localhost:8080

Stop it with:

```bash
make obs-down
```

## Google Drive image storage

Uploads use local `/uploads` by default. To store new admin-uploaded images in Google Drive, set `IMAGE_STORAGE_PROVIDER=google_drive`.

For a Google Workspace Shared Drive, create a Google Cloud service account, enable the Google Drive API, share the target Shared Drive folder with the service account email, then set:

```bash
IMAGE_STORAGE_PROVIDER=google_drive
GOOGLE_DRIVE_FOLDER_ID=<drive-folder-id>
GOOGLE_DRIVE_SERVICE_ACCOUNT_BASE64=<base64-service-account-json>
```

On macOS, create the base64 value with:

```bash
base64 -i service-account.json | tr -d '\n'
```

For a normal Gmail/My Drive folder, use OAuth instead of a service account so uploads use the storage quota of your Google account:

```bash
IMAGE_STORAGE_PROVIDER=google_drive
GOOGLE_DRIVE_FOLDER_ID=<drive-folder-id>
GOOGLE_DRIVE_OAUTH_CLIENT_ID=<oauth-client-id>
GOOGLE_DRIVE_OAUTH_CLIENT_SECRET=<oauth-client-secret>
GOOGLE_DRIVE_OAUTH_REFRESH_TOKEN=<oauth-refresh-token>
```

If the OAuth variables are present, the backend uses OAuth automatically. Otherwise it falls back to the service account variables.

To generate the refresh token locally, create an OAuth client in Google Cloud, add `http://localhost:8765/oauth2callback` as a redirect URI if using a Web client, then run:

```bash
cd backend
python scripts/google_drive_oauth_token.py
```

Open the printed URL, approve Drive access, and copy the printed `GOOGLE_DRIVE_OAUTH_REFRESH_TOKEN` into Render.

Uploaded files are made public read-only and the API returns an image URL that can be saved directly into product/category image fields.

## Import home page data

Home page content is stored in:

- `backend/data/home_page.json`
- `backend/data/menu_page.json`
- `backend/data/login_page.json`
- `backend/data/register_page.json`

To import or re-import it into MongoDB:

```bash
cd backend
source .venv/bin/activate
python scripts/import_home_page.py
```

Or from the project root:

```bash
make bootstrap-env
make import-home
make import-menu
make import-auth-pages
```

If MongoDB is not running or `MONGODB_URI` is invalid, the import scripts fail fast with a clear error.
