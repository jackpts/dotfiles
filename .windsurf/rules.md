# LinksThatRank Project Rules & Guidelines

This document outlines the technical standards and rules for the LinksThatRank project. Windsurf should follow these rules when generating or modifying code.

## 🛠 Tech Stack Overview

### Frontend (`sl_frontend`)

- **Framework**: React 19 (Vite 6)
- **Language**: TypeScript 5.8+
- **Routing**: TanStack Router
- **State Management**: Zustand (Client state), TanStack Query (Server state)
- **Styling**: Tailwind CSS v4 + Sass modules
- **Forms**: TanStack Form + Zod validation
- **Tables**: TanStack Table
- **UI Components**: Radix UI, Headless UI, Lucide React icons
- **Formatting**: Prettier with Tailwind plugin, ESLint

### Backend (`sl_back`)

- **Framework**: NestJS 11
- **Language**: TypeScript 5.7+
- **ORM**: TypeORM (PostgreSQL)
- **Validation**: class-validator, class-transformer
- **API Documentation**: Swagger (@nestjs/swagger)
- **Cloud**: AWS SDK v3 (S3, Lambda, SQS, Cognito, etc.)
- **Testing**: Jest

---

## 🏗 Project Architecture & Patterns

## 🗂 Workspace Layout & Command Rules

- `sl_back/` — backend (NestJS + TypeORM) services and migrations.
- `sl_frontend/` — React/Vite frontend application. (No unit-test harness today; only Cypress e2e exists.)
- `sl_aqa/` — Cypress end-to-end suite (browser automation only).
- `sl_infra/` — infrastructure-as-code (Terraform + Terragrunt) plus CI/CD assets like `bitbucket-pipelines.yml`.

Each directory is its own Git repository. Always run Git and npm commands from the directory that owns the change (e.g., `sl_back` for backend, `sl_frontend` for frontend). When switching between BE/FE tasks, ensure the terminal `cwd` is the corresponding folder before running any Git/npm command.

Task specs, notes, and screenshots live in `.tasks/` at the repo root. When you see a four-digit task ID, look for the matching files inside `.tasks/`.

---

## 🏗 Project Architecture & Patterns

### Frontend Structure (FSD-lite)

Follow the structure in `sl_frontend/src/`:

- `entities/`: Domain primitives and shared logic
- `features/`: Feature-specific logic (forms, tables, workflows)
- `widgets/`: Composite UI blocks
- `pages/`: Route-level components
- `shared/`: UI kit, API clients, hooks, utils, constants
- `routes/`: TanStack router definitions

### Backend Patterns

- Use **NestJS CQRS** pattern for complex business logic.
- Follow **Dependency Injection** principles.
- Use **TypeORM migrations** for database changes.
- Ensure **Swagger** decorators are present on all DTOs and Controller endpoints.

---

## 📜 Coding Rules

### General

1. **TypeScript**: Strict mode is enabled. Always use explicit types and **NEVER use `any`**. Use `unknown` if the type is truly unknown. For frontend code, if a return type truly cannot avoid `any`, use the project custom type `ShamefulAny` instead (and leave a TODO explaining the gap). Avoid redundant primitive annotations on local `const`/`let` declarations—prefer `const filePath = ...` instead of `const filePath: string = ...` when the type is inferred.
2. **Enums**: Convert string values to enums where possible for better type safety and maintainability.
3. **Imports**: Use absolute imports where possible (e.g., `@linksthatrank/...` or `src/...`).
4. **Naming**:
   - Components: PascalCase
   - Functions/Variables: camelCase
   - Constants: SCREAMING_SNAKE_CASE
   - Files: kebab-case (except for components which can be PascalCase)
5. **Safety**: Double check everything to ensure implementation is correct and doesn't negatively affect existing logic, especially in shared components, modals, and tables.
6. **Clarity**: Never use nested ternary expressions. Prefer straightforward conditionals (if/else blocks or extracted helper functions) to keep logic readable.
7. **Shared constants & types**: When the same literal or union type (e.g., a displayed status that embeds a virtual value) is needed in multiple files, define it once in a shared constants/types module (e.g., `src/modules/.../constants/`) and import it everywhere instead of re-declaring it.
8. **Casting discipline**: Avoid chained or unclear casts (e.g., `as unknown as string`). If type coercion is required, prefer helper functions or `String(value)`/type guards so the intent and resulting type are obvious.
9. **Respect existing comments**: Do not delete comments written by other developers unless the entire referenced block of code is being removed or rewritten. If a comment needs clarification, add context rather than removing it.
10. **Array length checks**: Prefer concise truthy checks (`if (!items.length)`) over explicit comparisons (`items.length === 0`) unless a specific numeric comparison is required for correctness/clarity.
11. **Annotate new logic**: Whenever you add a new, non-trivial logic block (conditionals, hooks, helper functions, etc.), include a concise comment directly above it explaining the intent. Skip this only for self-evident one-liners.

### Frontend Specific

1. **React 19 Hooks**:
   - **Optimization**: Do NOT use `useMemo` for simple logic; rely on React 19's improved compiler/optimization.
   - **Imports**: Use named imports for hooks (e.g., `import { useEffect, useState } from 'react';`). Avoid using `React.useEffect` or `React.useState`.
   - **Review step**: After any frontend change, explicitly check each modified or newly added block to confirm whether `useMemo`/`useCallback` is actually required. Default to plain functions/expressions unless memoization prevents a real, measured regression.
   - **TanStack Query first**: When asynchronous data fetching/mutations start accumulating long dependency arrays or manual state flags, refactor into TanStack Query hooks/mutations instead of ad-hoc `useEffect`/`useCallback` logic. Prefer sharing common `useQuery`/`useMutation` helpers over per-component request wiring.
2. **Styling**: Use `className` props instead of inline `style` objects in JSX templates whenever possible, especially for common or shared components. Use Tailwind v4 classes.
3. **State**: Use `Zustand` for global UI state and `TanStack Query` for data fetching.
4. **Forms**: Always use `TanStack Form` with `Zod` schemas for validation.
5. **Icons**: Use `Lucide React` by default.
6. **i18n**: When adding/updating UI text, use translations (no hardcoded copy). Translation keys must be CamelCase (e.g., `PublisherCreation.validation.fieldName`), matching the structure in the JSON locale files. Update the locale file alongside the code change.
7. **Tailwind layout utilities (minimalism)**:
   - Do **not** add "base" utility classes by default (e.g., `min-w-0`, `max-w-full`, `flex-1`, `overflow-hidden`, `truncate`).
   - First verify whether the necessary width/overflow constraints are already provided by parent nodes (common in our `SLChip`/table cell layouts).
   - Add **only the minimal set** of classes required to achieve the behavior (ellipsis/overflow/scroll/etc.).
   - If a non-obvious utility is required for correctness (e.g., `min-w-0` to make `truncate` work inside a flex row), keep it and ensure it is applied at the correct node (usually the flex item that must shrink), avoiding duplicates.
8. **User-facing error messages (toast/snackbar)**:
   - Do **not** display raw `error.message` from Axios/JS errors directly to users (especially from global TanStack Query handlers). Prefer a localized/user-friendly message.
   - For API errors, use the shared mapping utilities (e.g., `buildApiErrorMessage` + `apiErrorCodeToString` + `t(...)`) or an existing centralized message-mapping helper, and show the resulting localized message.
   - Do **not** parse Axios errors in components to extract backend error codes manually. Extend the centralized mapping (`shared/utils/apiErrorToString.ts` + `locales/*/validationApi.json`) when a new backend error code is introduced.
   - For endpoints using `responseType: 'blob'`, ensure mutation hooks normalize Axios errors to `IApiError` (including parsing error blobs when necessary) before they reach UI code.
   - Always respect request-level suppression flags (e.g., `error.details?.config?.silentMode`) so background/expected failures do not trigger global toasts.
   - Do not show toasts for canceled/aborted requests (e.g., `ERR_CANCELED`).
   - If a safe localized message cannot be built, show a generic translated fallback instead of leaking technical details.
   - When logging errors to the console (for debugging/Sentry breadcrumbs), serialize them with `getStringifiedError(error)` instead of passing raw objects so structured logs remain consistent across the app.
9. **React copy rendering**: Do not use `dangerouslySetInnerHTML` to inject translated strings. When a message needs inline markup (e.g., `<strong>`), wrap it in `Trans` from `react-i18next`, pass the supported elements via the `components` prop, and supply `values` for interpolation. Example:

  ```tsx
  <Trans
    components={{ strong: <strong /> }}
    i18nKey={`${I18_MODULES.ACCOUNT.SUBSCRIPTION_MANAGEMENT}.banner.actionRequiredMessage`}
    ns={I18_NAMESPACE.ACCOUNT}
    values={{ days }}
  />
  ```
10. **Category chips/labels**: When rendering category chips/labels (e.g., project/site topics), always derive display data via `groupCategoriesByLabel` from `src/entities/categories/model/utils/groupCategoriesByLabel.ts`. The helper groups by `category.label` and falls back to `category.name`, so use its output instead of rolling custom reducers.
11. **Conditional classNames**: Prefer `clsx` for composing conditional class names (e.g., `clsx(baseClasses, isActive && 'text-red-600')`) instead of manual string concatenation or nested ternaries. This keeps class logic declarative and prevents stray spaces.
12. **File download handling**: When implementing file downloads from Blob responses, use the `downloadFileFromResponse` utility from `@/shared/utils`. Do **not** inline-import Axios types in mutation callbacks (e.g., `import('axios').AxiosResponse<Blob>`). Instead, rely on the mutation hook's type inference—the response parameter is already correctly typed by the hook's generic signature. Example: `onSuccess: (response) => { downloadFileFromResponse({ response, filenamePrefix: 'export' }); }`.

### Backend Specific

1. **NestJS**: Follow the standard module-service-controller pattern.
2. **DTOs & Controllers**:
   - Define request/response contracts as DTO classes and decorate fields with `class-validator` decorators (`@IsString`, `@IsInt`, `@IsOptional`, etc.). Reuse these DTOs in controller method signatures instead of validating inside the controller body.
   - For primitive route/query params use Nest pipes (e.g., `@Param('id', ParseIntPipe)`) rather than manual `parseInt`/`Number` calls. Any authorization/business validation beyond type/shape must live in handlers/services, not controllers.
   - Before creating new transformers/pipes/helpers for basic coercions (numbers, booleans, dates), search the shared `@linkthatrank/common/transformers` and Nest built-in pipes. Prefer reusing existing utilities like `toInt`, `ParseIntPipe`, etc., to avoid duplicate logic and inconsistent behavior.
   - When throwing exceptions, reuse centralized error enums/constants (e.g., `OriginalityAiErrorMessage`, `UsersErrorMessages`) instead of hardcoding strings in handlers or services. If no constant exists, add it once to the relevant enum-like structure.
3. **CQRS Commands**: Classes that extend the shared `Command` base already generate a `correlationId`. Do **not** pass `correlationId` manually when instantiating commands unless you have a very specific need (e.g., bulk executor orchestrating many sub-commands). When writing new commands, type the constructor with `CommandProps<YourCommand>` and call `super(props)` to inherit the automatic ID generation.
4. **Command Handlers**: `CommandHandlerBase` already wraps every `handle()` call in `UnitOfWork.execute`. Never call `_unitOfWork.execute(...)` inside a handler manually—just use the repositories resolved from `_unitOfWork` with the correlationId provided on the command.
5. **Migrations**: Never modify existing migrations. Always run the package.json scripts (`npm run migration:generate`, `npm run migration:run`, etc.) so TypeORM produces the diff itself—do **not** hand-write migration bodies. After generation, trim the file down to the smallest possible delta: keep only the concrete `up`/`down` statements that add/drop the specific columns, indexes, or enum values you changed (see `1767800101724-add-phone-number-verified-to-user` for reference). Remove helper constants, redundant enum recreations, or other noise so the migration clearly reflects just the schema change. This keeps the DB state aligned and prevents noisy follow-up diffs.
4. **Lambdas**: Backend includes AWS Lambda functions in `lambdas/`. Follow existing patterns for event handling and logging.
5. **Cognito + DB sequencing**: When an operation touches both PostgreSQL (via TypeORM) and AWS Cognito (e.g., deleting a user), keep all database work inside a transaction/UnitOfWork and call Cognito only after the DB transaction succeeds. That way a Cognito failure doesn’t block the DB rollback, and a DB failure doesn’t leave Cognito in an inconsistent state. Wrap the Cognito call in its own `try/catch` and surface/log failures so manual cleanup can happen.
6. **TypeORM performance**: Always design repository/QueryBuilder logic to avoid N+1 queries—eager-load relations, batch fetch, or restructure queries so each request issues the minimal number of SQL statements. When batching is needed, use `In([...])` with Maps for in-memory lookups instead of per-item loops with `findOne`.
7. **Lambda footprint**: Do **not** bundle NestJS into AWS Lambda handlers. Implement lambdas as lightweight Node/TypeScript functions using the shared helpers/loggers instead of bootstrapping the Nest container, to keep bundle size small and cold starts fast.

---

## 🔧 Workflow Commands

- **Frontend Dev**: `npm run dev` in `sl_frontend`
- **Backend Dev**: `npm run start:dev` in `sl_back`
- **Formatting**: `npm run format` in respective directories
- **Linting**: `npm run lint` in respective directories

## 🗄 Database Shortcuts

When applying ad-hoc SQL to the shared `develop` database, use:

```bash
PGPASSFILE=$HOME/.pgpass psql -h localhost -p 5432 -U root -d develop -c "…SQL…"
```

The Fish abbreviations `_sql`/`sl_db_up` wrap this command; using them ensures credentials from `~/.pgpass` are respected and everyone targets the same DB.
