# Repository Guidelines

## Project Structure & Module Organization
TeleGramApp splits into `backend/` for the FastAPI + MongoDB service and `frontend/` for the Flutter client targeting iOS and Android. Keep API packages in `backend/app/`, configs in `backend/app/config.py`, and shared schemas under `backend/app/schemas/`; tests and fixtures belong in `backend/tests/`. Flutter features live in `frontend/lib/<feature>/` with shared UI in `frontend/lib/widgets/`, data services in `frontend/lib/services/`, and platform assets in `frontend/assets/`. Native wrappers stay in `frontend/android/` and `frontend/ios/`.

## Build, Test, and Development Commands
- `cd backend && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt` sets up backend deps.
- `cd backend && uvicorn app.main:app --reload` runs the API locally.
- `cd backend && pytest` executes backend unit and integration tests.
- `cd backend && task lint` runs `ruff` plus `mypy`.
- `cd frontend && flutter pub get` installs Dart packages.
- `cd frontend && flutter run` boots the app on the default simulator/device.
- `cd frontend && flutter test` runs widget and unit tests.
- `cd frontend && flutter build apk` / `flutter build ios` creates release builds.

## Coding Style & Naming Conventions
Follow PEP 8 with 4-space indents, type annotations, and formatting via `black` + `isort` on the backend. Keep MongoDB access helpers isolated in repository modules. For Flutter, rely on `dart format .` and `flutter analyze`; use PascalCase for widgets, camelCase for fields and methods, and snake_case filenames matching the main class. Centralize theme constants in `frontend/lib/theme/`.

## Testing Guidelines
Backend tests sit in `backend/tests/test_<feature>.py`; share fixtures through `conftest.py` and mark long-running suites with `@pytest.mark.slow`. Frontend unit and widget specs belong in `frontend/test/`, with integration flows under `frontend/test_driver/` run via `flutter drive`. Maintain ≥80% coverage for both stacks and note any gaps in the PR description.

## Commit & Pull Request Guidelines
Write conventional commit subjects such as `backend: add message webhook` or `frontend: refine chat drawer`. Pull requests need a brief summary, linked issue IDs, screenshots or screen recordings for UI work, and a checklist covering lint, tests, and build steps. Request at least one reviewer per affected module and flag breaking API changes in the title.

## Security & Configuration Tips
Mirror `.env.example` for local secrets, keeping values like `MONGODB_URI` and bot tokens out of version control. Rotate Telegram credentials regularly and document the change in the PR. When enabling new providers, update CORS and rate limits in `backend/app/config.py`.
