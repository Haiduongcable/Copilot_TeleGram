# TeleGramApp Backend

FastAPI service implementing the internal social network + messaging platform defined in `backend_brief.md`. The backend exposes REST + WebSocket APIs for authentication, social feed, messaging, notifications, file uploads, and basic admin controls.

## Features
- JWT-based auth with refresh tokens, password hashing, and session revocation.
- Team directory with profile management, search, and status updates.
- Posts feed supporting comments, reactions, tags, and attachments metadata.
- Direct & group messaging with read receipts, typing indicators, and WebSocket push events.
- Notification center for messages, mentions, and activity updates.
- Local file storage with per-user quotas and size validation.
- Metrics and health endpoints for monitoring plus a minimal admin API.

## Project Structure
```
backend/
  app/
    config.py               # Pydantic settings
    main.py                 # FastAPI application entrypoint
    core/                   # Shared utilities (security, deps, logging)
    db/                     # MongoDB connection helpers
    schemas/                # Pydantic models shared across layers
    repositories/           # MongoDB data access helpers
    services/               # Business logic for each domain
    routes/                 # API routers (REST + WebSocket)
  tests/                    # Async pytest suites using mongomock
  requirements.txt
  requirements-dev.txt
  .env.example
```

## Getting Started
1. Create a virtualenv and install dependencies:
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. (Optional) Start a local MongoDB instance with Docker:
   ```bash
   cd ..
   ./run.sh up
   ```
   This boots MongoDB 7.0 with data persisted to `PVC/mongo_data`.
3. Configure environment variables by copying `.env.example` to `.env` and updating secrets (`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, etc.).
4. Ensure MongoDB is running and accessible via `MONGODB_URI`.
5. Launch the API:
   ```bash
   uvicorn app.main:app --reload
   ```
6. Interactive docs available at `http://localhost:8000/api/docs`.

## Testing & Tooling
- Install dev dependencies: `pip install -r requirements-dev.txt`
- Run tests: `pytest`
- Lint & type-check (requires `task` wrapper or run tools directly):
  - `ruff check app`
  - `mypy app`

## WebSocket Usage
Connect to `ws://<host>/api/ws/chats/{chat_id}?token=<access_token>` to receive real-time chat events:
- `message:new`, `message:updated`, `message:deleted`
- `typing`, `message:seen`, `message:seen_all`

Send events as JSON payloads, e.g.:
```json
{"event": "typing", "data": {"is_typing": true}}
```

## Notes & Next Steps
- Image thumbnail generation is stubbed; integrate Pillow/Thumbor for production usage.
- Optional email password reset and rate limiting middleware can be added in later iterations.
- For production, place MongoDB + Redis behind authentication and configure HTTPS termination.
