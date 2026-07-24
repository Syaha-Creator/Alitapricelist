# Implementation Plan: Auth Module (SPEC.md §8 Step 2)

## Overview

Login ke REST API custom "Alita" (bukan Firebase Auth), simpan sesi (profil di
SharedPreferences, token di FlutterSecureStorage), sambungkan ke `ApiClient` yang sudah ada
lewat `AccessTokenProvider`/`UnauthorizedCallback` untuk auto-logout saat 401/403, lalu tambahkan
guard router `authStatusProvider` (pola sama seperti `bootstrapProvider`). Firebase Auth anonymous
diinisialisasi setelah login sukses, non-blocking terhadap hasil login.

## Kontrak API asli (diverifikasi dari baseline `alitapricelist copy`, bukan tebakan)

Sumber: audit langsung ke `lib/features/auth/data/services/auth_service.dart`,
`lib/core/services/storage_service.dart`, `lib/features/auth/logic/auth_provider.dart` di
`~/StudioProjects/alitapricelist copy`.

- **Login:** `POST {API_BASE_URL}/sign_in?client_id=...&client_secret=...`
  - Body: `{"email": "...", "password": "..."}`
  - Header: `Content-Type: application/json`, `Accept: application/json` — **tidak ada Bearer**
- **Response sukses:** `{"token": "...", "user": {"id", "email", "name"|"user_name", "area_id",
  "image": {"url"}, "address_number"|"sales_code"|"salesCode"|"code_sales"}}`
  - Field top-level namanya **`token`**, bukan `access_token`
  - Tidak ada `refresh_token`/`expires_in`/`token_type`
- **Error:** 401/403 → pesan generik "email/password salah" (tidak parse body); ≥500 → pesan
  server generik; lainnya → baca `error`/`message` dari body JSON kalau ada
- **Auth pada call lain:** token dikirim sebagai **query param `access_token`** (+ `client_id` +
  `client_secret`), bukan header `Authorization: Bearer`
- **Sesi lokal:** satu `access_token` di FlutterSecureStorage, tanpa refresh token. Profil dasar
  (`user_id`, `user_name`, `user_image_url`, dll) di SharedPreferences
- **401/403 di call lain:** tidak ada refresh flow — langsung dianggap sesi habis → trigger logout
- **Firebase Auth anonymous:** dipanggil setelah `saveAuth` + set state logged-in, di-`await`
  (menunda selesainya `login()`), tapi errornya **hanya di-log**, tidak mem-fail-kan login yang
  sudah sukses di sisi REST API

## Keputusan arsitektur

1. **`client_id`/`client_secret` sebagai query param, bukan header** — ini mengoreksi desain
   `_AuthHeaderInterceptor` di `ApiClient` (step 1) yang memakai `Authorization: Bearer`. Karena
   API asli tidak memakai Bearer sama sekali, interceptor itu diganti jadi query-param injector
   (`access_token`, `client_id`, `client_secret`) supaya konsisten dengan kontrak API asli. Endpoint
   login sendiri tidak butuh `access_token` (belum ada sesi), jadi query injector harus skip kalau
   token belum ada — sudah begitu (query hanya ditambah kalau token tersedia); `client_id`/
   `client_secret` untuk login dikirim manual oleh `AuthRepository` lewat `queryParameters` di
   `ApiClient.post`, bukan lewat interceptor global (supaya tidak bergantung pada urutan
   inisialisasi auth module).
2. **Model login pakai Freezed**, field mengikuti kontrak asli tapi dengan default value (tidak
   ada `!`): `LoginResponse` (token + user), `AuthUser` (id, email, name, areaId, imageUrl,
   addressNumber — semua optional/default). TIDAK menyalin arsitektur "AuthLoginResult" lama
   (plain class, banyak fallback manual) — diringkas jadi model Freezed + json_serializable.
3. **`AuthSession`** (Freezed) = representasi sesi tersimpan: `accessToken`, `userId`, `userName`,
   `userEmail`, `userImageUrl`, `areaId`, `addressNumber`. Dipisah dari `LoginResponse` (response
   API) supaya storage layer tidak coupled ke bentuk JSON API.
4. **`AuthStatus`** sealed state (pola sama seperti `BootstrapState`): `AuthLoading` |
   `AuthAuthenticated(AuthSession)` | `AuthUnauthenticated`. Dipakai provider `authStatusProvider`.
5. **Auto-logout via `UnauthorizedCallback`**: `AuthRepository` register callback ke `ApiClient`
   saat dibuat; saat dipanggil, repository clear storage + set state `AuthUnauthenticated` —
   **tidak** memanggil `ApiClient` lagi dari dalam callback (hindari re-entrancy), cukup ubah state
   lokal + storage.
6. **Firebase Anonymous non-blocking**: dipanggil dengan `unawaited()` (atau fire-and-forget
   dengan try-catch sendiri) setelah state diset `AuthAuthenticated` — TIDAK di-`await` di jalur
   utama `login()`, supaya UI login langsung lanjut begitu REST API sukses (ini sedikit beda dari
   app lama yang men-`await` — dipilih non-blocking karena §5.1 di prompt eksplisit minta "jangan
   blocking").
7. **Router guard**: `authStatusProvider` dipakai di `redirect` GoRouter persis seperti
   `bootstrapProvider` — cek `loading` dulu sebelum ambil keputusan redirect (guardrail SPEC.md
   §6). Alur: `BootstrapLoading` → splash; `BootstrapReady` + `AuthLoading` → splash; `BootstrapReady`
   + `AuthUnauthenticated` → `/login`; `BootstrapReady` + `AuthAuthenticated` → `/` (home).

## Task List

### Phase 1: Foundation (model + storage, tanpa network dulu)

- [ ] **Task 1**: `AuthSession` (Freezed) + `SecureSessionStorage` (FlutterSecureStorage untuk
      token, SharedPreferences untuk profil) — save/load/clear, dikembalikan sebagai `Result<T>`.
      Test: mock `SharedPreferences`/`FlutterSecureStorage` (pakai
      `shared_preferences`'s `setMockInitialValues` + fake secure storage), verifikasi
      save→load round-trip dan clear.
- [ ] **Task 2**: `LoginResponse`/`AuthUser` (Freezed, json_serializable) sesuai kontrak API asli
      di atas. Test: parsing JSON dengan field lengkap, field opsional hilang (pakai default,
      bukan `!`), dan JSON rusak (harus gagal jadi exception yang tertangkap layer atas, bukan di
      level model itu sendiri — model boleh throw saat `fromJson`, itu ditangkap `ApiClient`).

### Checkpoint 1
- [ ] Semua test Phase 1 hijau, `flutter analyze` bersih.

### Phase 2: Network + repository

- [ ] **Task 3**: Ganti `_AuthHeaderInterceptor` di `ApiClient` jadi query-param injector
      (`access_token` kalau ada token; TIDAK menambah `client_id`/`client_secret` di sini — itu
      tanggung jawab caller per keputusan #1). Test: existing `ApiClient` tidak punya test
      langsung; tambahkan test kecil untuk interceptor ini (verifikasi query param muncul saat
      token ada, tidak muncul saat tidak ada).
- [ ] **Task 4**: `AuthRepository` — `login(email, password)` panggil `ApiClient.post('/sign_in',
      queryParameters: {client_id, client_secret})`, parse ke `LoginResponse`, simpan ke
      `SecureSessionStorage`, return `Result<AuthSession>`. Register `onUnauthorized` ke
      `ApiClient` yang clear session. Test: mock `ApiClient`/Dio, cover sukses, 401 (pesan
      credentials salah), network error, parsing gagal — semua harus jadi `AppException` yang
      sesuai (`UnauthorizedException`, `NetworkException`, `ParsingException`), tidak ada
      exception mentah lolos ke caller.

### Checkpoint 2
- [ ] Repository + interceptor test hijau. `flutter analyze` bersih.

### Phase 3: State, router guard, UI

- [ ] **Task 5**: `authStatusProvider` (`AsyncNotifierProvider`, manual — konsisten dengan
      `bootstrapProvider`) dengan state `AuthStatus` (`loading|authenticated|unauthenticated`).
      Restore sesi dari storage saat `build()`. Expose `login()`/`logout()` di notifier yang
      dipanggil UI.
- [ ] **Task 6**: Firebase Auth anonymous — fungsi terpisah, dipanggil fire-and-forget setelah
      `AuthAuthenticated` diset, error hanya di-log via `AppLogger.recordError` (non-fatal).
- [ ] **Task 7**: Perluas `app_router.dart` — tambah route `/login`, redirect guard cek
      `bootstrapProvider` dulu (sudah ada), lalu `authStatusProvider` (loading→splash,
      unauthenticated→/login, authenticated & di /login→home).
- [ ] **Task 8**: `LoginPage` (email/password form) + widget test dasar (render, submit
      memanggil notifier, error ditampilkan).

### Checkpoint 3 (final)
- [ ] Semua test (unit + widget) hijau, `flutter analyze` 0 issues.
- [ ] `code-review-and-quality` pass: cek token tidak pernah lolos ke `AppLogger`/log manapun.
- [ ] Ringkasan ditunjukkan ke user sebelum lanjut ke Langkah 3.

## Risks and Mitigations

| Risk | Impact | Mitigasi |
|---|---|---|
| Kontrak API asli berubah di server production (field `token` vs `access_token`, dll) | Medium | Model terpisah dari storage; kalau field berubah, cuma `LoginResponse.fromJson` yang perlu diubah |
| Query-param based auth (bukan Bearer) tidak lazim di banyak contoh Dio/tutorial | Low | Sudah didesain eksplisit di interceptor baru, dites langsung |
| Test tanpa akses ke server asli (tidak ada staging/mock server) | Medium | Semua test pakai mock Dio/`http` — tidak ada test yang benar-benar memanggil API asli |

## Open Questions

- ~~Apakah endpoint `/sign_out` (logout server-side) perlu dipanggil di langkah ini, atau cukup
  clear storage lokal?~~ → **Resolved (sesi bugfix AppConfig)**: user memutuskan implementasikan
  sekarang. `AuthRepository.logout()` memanggil `DELETE /sign_out` (body:
  `client_id`/`client_secret`/`access_token`, lihat `tasks/api-map.md`) secara best-effort —
  kegagalan panggilan remote (config hilang, network error, dll.) tidak menghalangi clear session
  lokal, karena itu adalah bagian yang security-critical.
