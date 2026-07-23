# Todo: Auth Module (SPEC.md §8 Step 2)

See `tasks/plan.md` for full context and API contract.

## Phase 1: Foundation
- [x] Task 1: `AuthSession` model + `SecureSessionStorage` (save/load/clear) + tests
- [x] Task 2: `LoginResponse`/`AuthUser` Freezed models (json_serializable) + parsing tests

## Checkpoint 1
- [x] All Phase 1 tests green, `flutter analyze` clean

## Phase 2: Network + repository
- [x] Task 3: Replace `_AuthHeaderInterceptor` with query-param (`access_token`) injector + test
- [x] Task 4: `AuthRepository.login()` (Result<AuthSession>) + `onUnauthorized` wiring + tests
      (success, 401, network error, parsing error)

## Checkpoint 2
- [x] Repository + interceptor tests green, `flutter analyze` clean

## Phase 3: State, router guard, UI
- [x] Task 5: `authStatusProvider` (AsyncNotifierProvider, restores session on build)
- [x] Task 6: Firebase Auth anonymous init, fire-and-forget, non-fatal logging on error
- [x] Task 7: Router: `/login` route + redirect guard using `authStatusProvider`
- [x] Task 8: `LoginPage` UI + widget test

## Checkpoint 3 (final)
- [x] Full test suite green (49 tests), `flutter analyze` 0 issues
- [x] code-review-and-quality pass — found and fixed a security gap:
      `LoggingInterceptor`'s debug-only URI logging leaked `access_token`/
      `client_secret`/`client_id` once those moved from header to query
      param (Task 3); now redacted via `redactSensitiveQueryParams`.
- [x] Summary shown to user before Step 3
