# Copilot instructions for this repo (wishlist_app)

Quick purpose
- This repo implements the Wishlist application (API + frontend). Read README.md first for any high-level notes.

Immediate discovery checklist (order matters)
1. package.json — find scripts (dev/start/build/test) and dependencies. Use these scripts to run or test the app.
2. README.md and .env.example — confirms required environment variables and local setup.
3. Entrypoints:
   - Check `src/index.ts`, `src/server.ts`, or `server/index.js` for backend startup.
   - Check `src/main.tsx`, `src/pages/` or `client/` for frontend entry.
4. Routing and controllers:
   - Inspect `src/routes/`, `src/api/`, or `src/pages/api/` for API surface.
5. Business logic / services:
   - Inspect `src/services/`, `src/lib/` or `src/domain/` for core application behavior and DB access.
6. Data layer:
   - Look for `prisma/`, `migrations/`, `db/` or `models/` to understand DB schema and migrations.
7. CI / workflows:
   - Read `.github/workflows/*` to see test and release steps used by CI.

Architecture & patterns (how to think about changes)
- Separation of concerns:
  - Routes/controllers are thin and delegate to services (e.g., route handlers call functions in `src/services/*`).
  - Services encapsulate domain logic and interact with the data layer (ORM or raw SQL).
- Single source of truth for env/config:
  - Configuration usually comes from `.env` or a central `config/*` module. Use that rather than scattered process.env reads.
- Error handling:
  - Follow existing error shape (e.g., Error -> http code and { error, message }) when adding endpoints.
- Tests:
  - Unit tests live near code (same folder or `__tests__`). Integration tests may rely on a test DB container.

Common commands and flows
- Discover scripts: open package.json and run the scripts listed there. Typical commands to try:
  - Install: npm ci | pnpm i
  - Dev (frontend/backend): npm run dev
  - Build: npm run build
  - Start: npm start
  - Tests: npm test | npm run test:unit | npm run test:integration
- Local DB / migrations:
  - If Prisma or migrations exist, run migrations before starting: refer to `prisma migrate` or `npm run migrate`.
- Docker:
  - If Dockerfile/docker-compose present, prefer `docker compose up --build` for an environment matching CI.

Project-specific conventions to search for
- Folder layout: look for `src/{routes,controllers,services,models}` — follow whatever pattern is already used.
- File naming: prefer camelCase exports for functions, PascalCase for React components, and *.service.ts or *.controller.ts suffixes if present.
- DTOs / validation: check for a `validators/` or `schemas/` folder — new inputs should reuse those schemas.

Examples (how to apply patterns)
- If adding an API route, mirror existing pattern:
  - File: src/routes/wishlist.ts — export route that imports `wishlistService.create()` rather than embedding DB calls.
- If using Prisma:
  - Use the existing `prismaClient` import from `src/lib/prisma` (search for existing use) instead of creating a new client instance.

Edge cases and gotchas
- Environment-sensitive behavior: CI and local setups may use different DB URLs or feature flags — check workflow files and .env.example.
- Avoid adding global side-effects during import. Services that open DB connections should be initialized by the server bootstrap code.

How to validate changes
- Run unit tests and any available integration tests.
- Start the app with the dev script and exercise key endpoints (routes listed under src/routes or src/pages/api).
- If migrations are modified, run them locally and verify DB state.

When in doubt
- Prefer following an existing file close to your change as canonical. Example: if a feature sits under `src/wishlist`, implement new routes/services/tests in that same folder structure.
- If you can’t find the entrypoint or scripts, open package.json and README; if still unclear, ask for the maintainer.

If any of the above sections are unclear or incomplete, tell me which ones and I will iterate.
