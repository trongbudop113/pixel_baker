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
