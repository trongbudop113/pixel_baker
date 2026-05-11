# Deploy Pixel Bakery Backend on Render + MongoDB Atlas

This backend is a FastAPI app with MongoDB. The recommended free deployment path is:

- Render Free Web Service for the FastAPI API
- MongoDB Atlas M0 Free Cluster for the database

The repo includes a root `render.yaml` Blueprint for Render.

## 1. Create MongoDB Atlas M0

1. Create a MongoDB Atlas account.
2. Create a free `M0` cluster.
3. Create a database user.
4. In Network Access, allow Render to connect. For a free demo, use `0.0.0.0/0`.
5. Copy the connection string, for example:

```text
mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

Use a URL-encoded password if it contains special characters.

## 2. Push this repo to GitHub

```bash
git add render.yaml backend/requirements.txt backend/DEPLOY.md
git commit -m "Configure Render backend deploy"
git push
```

If this folder is not a Git repo yet, create a GitHub repository first, then push the project.

## 3. Deploy on Render

1. Open Render Dashboard.
2. Choose New > Blueprint.
3. Select this GitHub repo.
4. Render reads `render.yaml`.
5. When prompted for `MONGODB_URI`, paste the Atlas connection string.
6. Create the service.

Render will build from `backend/` with:

```bash
pip install -r requirements.txt
```

and start the API with:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## 4. Check the deployment

After Render shows the service as live, open:

```text
https://YOUR_RENDER_SERVICE.onrender.com/api/v1/health
```

Expected response:

```json
{"status":"ok"}
```

The API seeds initial bundled data at startup.

## 5. Frontend API URL

Build Flutter web with the Render API base URL:

```bash
flutter build web --dart-define=API_BASE_URL=https://YOUR_RENDER_SERVICE.onrender.com/api/v1
```

## Manual Render setup

If you do not use the Blueprint, create a Render Web Service manually:

- Root Directory: `backend`
- Runtime: `Python 3`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Health Check Path: `/api/v1/health`

Environment variables:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `API_V1_PREFIX=/api/v1`
- `MONGODB_URI=<Atlas connection string>`
- `MONGODB_DB=pixel_bakery`
- `JWT_SECRET_KEY=<long random secret>`
- `JWT_ALGORITHM=HS256`
- `JWT_EXPIRE_MINUTES=1440`
- `JWT_REFRESH_EXPIRE_DAYS=30`
- `PASSWORD_RESET_EXPIRE_MINUTES=30`
- `LOGIN_MAX_ATTEMPTS=5`
- `LOGIN_LOCK_MINUTES=15`
- `LOG_LEVEL=INFO`
