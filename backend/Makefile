SHELL := /bin/zsh

BACKEND_DIR := backend
BACKEND_HOST := 0.0.0.0
BACKEND_PORT := 8000
FRONTEND_DEVICE := chrome
API_BASE_URL := http://localhost:$(BACKEND_PORT)/api/v1
BACKEND_PID_FILE := .backend.pid

.PHONY: help install mongo-up mongo-down obs-up obs-down backend-install backend-run backend-start backend-stop frontend-run run stop

help:
	@echo "Targets:"
	@echo "  make install        - install backend dependencies"
	@echo "  make mongo-up       - start MongoDB with Docker Compose"
	@echo "  make mongo-down     - stop MongoDB container"
	@echo "  make obs-up         - start observability stack for Docker metrics"
	@echo "  make obs-down       - stop observability stack"
	@echo "  make backend-run    - run FastAPI backend in foreground"
	@echo "  make backend-start  - run FastAPI backend in background"
	@echo "  make backend-stop   - stop background FastAPI backend"
	@echo "  make frontend-run   - run Flutter web app with API_BASE_URL"
	@echo "  make run            - start MongoDB, backend, then frontend"
	@echo "  make stop           - stop frontend dependencies started by make run"

install: backend-install

backend-install:
	cd $(BACKEND_DIR) && uv sync

mongo-up:
	cd $(BACKEND_DIR) && docker compose up -d

mongo-down:
	cd $(BACKEND_DIR) && docker compose down

obs-up:
	cd $(BACKEND_DIR)/observability && docker compose up -d

obs-down:
	cd $(BACKEND_DIR)/observability && docker compose down

backend-run:
	cd $(BACKEND_DIR) && uv run uvicorn app.main:app --reload --host $(BACKEND_HOST) --port $(BACKEND_PORT)

backend-start:
	@if [ -f $(BACKEND_PID_FILE) ] && kill -0 "$$(cat $(BACKEND_PID_FILE))" 2>/dev/null; then \
		echo "Backend is already running with PID $$(cat $(BACKEND_PID_FILE))"; \
	else \
		cd $(BACKEND_DIR) && nohup uv run uvicorn app.main:app --reload --host $(BACKEND_HOST) --port $(BACKEND_PORT) > ../backend.log 2>&1 & echo $$! > ../$(BACKEND_PID_FILE); \
		echo "Backend started with PID $$(cat $(BACKEND_PID_FILE))"; \
	fi

backend-stop:
	@if [ -f $(BACKEND_PID_FILE) ]; then \
		kill "$$(cat $(BACKEND_PID_FILE))" 2>/dev/null || true; \
		rm -f $(BACKEND_PID_FILE); \
		echo "Backend stopped"; \
	else \
		echo "Backend PID file not found"; \
	fi

frontend-run:
	flutter run -d $(FRONTEND_DEVICE) --dart-define=API_BASE_URL=$(API_BASE_URL)

run: mongo-up backend-start
	@sleep 3
	@echo "MongoDB is running"
	@echo "Backend base URL: $(API_BASE_URL)"
	$(MAKE) frontend-run

stop: backend-stop mongo-down
