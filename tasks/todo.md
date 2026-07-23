# Todo: Auth Module (SPEC.md §8 Step 2)

See `tasks/plan.md` for full context and API contract.

## Phase 1: Foundation
- [ ] Task 1: `AuthSession` model + `SecureSessionStorage` (save/load/clear) + tests
- [ ] Task 2: `LoginResponse`/`AuthUser` Freezed models (json_serializable) + parsing tests

## Checkpoint 1
- [ ] All Phase 1 tests green, `flutter analyze` clean

## Phase 2: Network + repository
- [ ] Task 3: Replace `_AuthHeaderInterceptor` with query-param (`access_token`) injector + test
- [ ] Task 4: `AuthRepository.login()` (Result<AuthSession>) + `onUnauthorized` wiring + tests
      (success, 401, network error, parsing error)

## Checkpoint 2
- [ ] Repository + interceptor tests green, `flutter analyze` clean

## Phase 3: State, router guard, UI
- [ ] Task 5: `authStatusProvider` (AsyncNotifierProvider, restores session on build)
- [ ] Task 6: Firebase Auth anonymous init, fire-and-forget, non-fatal logging on error
- [ ] Task 7: Router: `/login` route + redirect guard using `authStatusProvider`
- [ ] Task 8: `LoginPage` UI + widget test

## Checkpoint 3 (final)
- [ ] Full test suite green, `flutter analyze` 0 issues
- [ ] code-review-and-quality pass (verify no token ever reaches AppLogger)
- [ ] Summary shown to user before Step 3
