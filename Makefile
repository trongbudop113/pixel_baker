SHELL := /bin/zsh

ROOT_DIR := $(CURDIR)/
BACKEND_DIR := $(ROOT_DIR)backend
BACKEND_HOST := 0.0.0.0
BACKEND_PORT := 8000
FRONTEND_DEVICE := chrome
API_BASE_URL := http://localhost:$(BACKEND_PORT)/api/v1
BACKEND_PID_FILE := $(ROOT_DIR).backend.pid
BACKEND_LOG_FILE := $(ROOT_DIR)backend.log
BACKEND_VENV_DIR := $(BACKEND_DIR)/.venv
BACKEND_PYTHON := $(BACKEND_VENV_DIR)/bin/python
BACKEND_PIP := $(BACKEND_VENV_DIR)/bin/pip

.PHONY: help install bootstrap-env mongo-up mongo-down obs-up obs-down backend-install backend-run backend-start backend-stop frontend-run flutter-web frontend-build import-home import-menu import-auth-pages import-contact import-story run run-app stop

help:
	@echo "Targets:"
	@echo "  make install        - install backend dependencies"
	@echo "  make bootstrap-env  - create backend/.env from backend/.env.example if missing"
	@echo "  make mongo-up       - start MongoDB with Docker Compose"
	@echo "  make mongo-down     - stop MongoDB container"
	@echo "  make obs-up         - start observability stack for Docker metrics"
	@echo "  make obs-down       - stop observability stack"
	@echo "  make backend-run    - run FastAPI backend in foreground"
	@echo "  make backend-start  - run FastAPI backend in background"
	@echo "  make backend-stop   - stop background FastAPI backend"
	@echo "  make frontend-run   - run Flutter web app with API_BASE_URL"
	@echo "  make flutter-web    - alias for frontend-run"
	@echo "  make frontend-build - build Flutter web release output"
	@echo "  make import-home    - import backend/data/home_page.json into MongoDB"
	@echo "  make import-menu    - import backend/data/menu_page.json into MongoDB"
	@echo "  make import-auth-pages - import backend/data/login_page.json and register_page.json into MongoDB"
	@echo "  make import-contact - import backend/data/contact_page.json into MongoDB"
	@echo "  make import-story   - import backend/data/story_page.json into MongoDB"
	@echo "  make run            - start MongoDB, backend, then frontend"
	@echo "  make run-app        - start backend, then frontend (skip Docker/Mongo)"
	@echo "  make stop           - stop backend and MongoDB"

install: backend-install

bootstrap-env:
	@if [ -f "$(BACKEND_DIR)/.env" ]; then \
		echo "backend/.env already exists"; \
	else \
		cp "$(BACKEND_DIR)/.env.example" "$(BACKEND_DIR)/.env"; \
		echo "Created backend/.env from backend/.env.example"; \
	fi

backend-install:
	cd "$(BACKEND_DIR)" && python3 -m venv .venv
	cd "$(BACKEND_DIR)" && "$(BACKEND_PIP)" install --upgrade pip
	cd "$(BACKEND_DIR)" && "$(BACKEND_PIP)" install -r requirements.txt

mongo-up:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "docker not found. Use an external MongoDB URI and run 'make run-app' instead."; \
		exit 1; \
	fi
	cd "$(BACKEND_DIR)" && docker compose up -d

mongo-down:
	cd "$(BACKEND_DIR)" && docker compose down

obs-up:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "docker not found. Install Docker before running observability stack."; \
		exit 1; \
	fi
	cd "$(BACKEND_DIR)/observability" && docker compose up -d

obs-down:
	cd "$(BACKEND_DIR)/observability" && docker compose down

backend-run:
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" -m uvicorn app.main:app --reload --host $(BACKEND_HOST) --port $(BACKEND_PORT)

backend-start:
	@if [ -f "$(BACKEND_PID_FILE)" ] && kill -0 "$$(cat "$(BACKEND_PID_FILE)")" 2>/dev/null; then \
		echo "Backend is already running with PID $$(cat "$(BACKEND_PID_FILE)")"; \
	else \
		cd "$(BACKEND_DIR)" && nohup "$(BACKEND_PYTHON)" -m uvicorn app.main:app --reload --host $(BACKEND_HOST) --port $(BACKEND_PORT) > "$(BACKEND_LOG_FILE)" 2>&1 & echo $$! > "$(BACKEND_PID_FILE)"; \
		echo "Backend started with PID $$(cat "$(BACKEND_PID_FILE)")"; \
	fi

backend-stop:
	@if [ -f "$(BACKEND_PID_FILE)" ]; then \
		kill "$$(cat "$(BACKEND_PID_FILE)")" 2>/dev/null || true; \
		rm -f "$(BACKEND_PID_FILE)"; \
		echo "Backend stopped"; \
	else \
		echo "Backend PID file not found"; \
	fi

frontend-run:
	cd "$(ROOT_DIR)" && flutter run -d $(FRONTEND_DEVICE) --dart-define=API_BASE_URL=$(API_BASE_URL)

flutter-web: frontend-run

frontend-build:
	cd "$(ROOT_DIR)" && flutter build web --release --dart-define=API_BASE_URL=$(API_BASE_URL)

import-home: bootstrap-env
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" scripts/import_home_page.py

import-menu: bootstrap-env
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" scripts/import_menu_page.py

import-auth-pages: bootstrap-env
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" scripts/import_auth_pages.py

import-contact: bootstrap-env
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" scripts/import_contact_page.py

import-story: bootstrap-env
	cd "$(BACKEND_DIR)" && "$(BACKEND_PYTHON)" scripts/import_story_page.py

run: mongo-up backend-start
	@sleep 3
	@echo "MongoDB is running"
	@echo "Backend base URL: $(API_BASE_URL)"
	$(MAKE) frontend-run

run-app: backend-start
	@sleep 3
	@echo "Backend base URL: $(API_BASE_URL)"
	$(MAKE) frontend-run

stop: backend-stop mongo-down
