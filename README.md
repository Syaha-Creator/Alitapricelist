# Alita Pricelist v3

Rewrite dari nol aplikasi internal B2B Alita Pricelist. Lihat [`SPEC.md`](SPEC.md) untuk
spesifikasi lengkap (goals, tech stack, fitur, guardrail arsitektur, urutan kerja).

## Status

**Langkah 1 selesai**: skeleton project — folder structure, error handling global (`Result<T>` +
`AppException`), `ApiClient` (Dio + retry/logging interceptor), `runZonedGuarded` + Crashlytics
wiring, router dasar dengan guard "loading" eksplisit. Belum ada fitur.

## Setup

1. Salin `.env.example` menjadi `.env` dan isi kredensial REST API yang sebenarnya:

   ```bash
   cp .env.example .env
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Generate kode (Freezed/json_serializable, akan dipakai mulai step 2):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Hubungkan project Firebase yang sudah ada (Crashlytics/Analytics/App Check/Cloud
   Functions/Data Connect) — belum dilakukan di skeleton ini:

   ```bash
   flutterfire configure
   ```

   Sampai langkah ini dijalankan, app tetap bisa di-build dan dijalankan; Crashlytics hanya
   nonaktif (di-log ke console saja) karena `main.dart` menangkap error inisialisasi Firebase
   secara graceful.

5. Jalankan:

   ```bash
   flutter run
   ```

## Struktur folder

```
lib/
├── main.dart                  # runZonedGuarded + Firebase/Crashlytics init + entry point
└── core/
    ├── bootstrap/              # BootstrapState (loading|ready|failed) + provider
    ├── config/                 # AppConfig (.env)
    ├── error/                  # AppException (sealed) + Result<T> (sealed)
    ├── logging/                # AppLogger (satu-satunya jalur ke Crashlytics)
    ├── network/                # ApiClient (Dio) + interceptors (retry, logging)
    ├── router/                 # GoRouter + redirect guard eksplisit
    └── widgets/                # SplashPage, BootstrapErrorPage, PlaceholderHomePage
features/
└── auth/                       # skeleton folder, diisi di step 2
```

## Agent skills (Cursor)

Project ini memakai seluruh 24 skill dari
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), disinkronkan ke
`.cursor/skills/` (lokasi yang dibaca Cursor — bukan `.agents/skills/`, yang hanya lokasi
copy generik dari CLI-nya) dengan routing rule tipis di `.cursor/rules/agent-skills.mdc` yang
menunjuk ke meta-skill `using-agent-skills` (skill ini yang memilihkan skill lain sesuai fase
kerja — lihat tabel routing di `.cursor/skills/using-agent-skills/SKILL.md`).

Skill yang paling relevan untuk rewrite ini: `spec-driven-development`,
`planning-and-task-breakdown`, `incremental-implementation`, `test-driven-development`,
`debugging-and-error-recovery`, `code-review-and-quality`, `security-and-hardening`,
`git-workflow-and-versioning`.

Update ke versi terbaru semua skill:

```bash
npx skills add addyosmani/agent-skills
# lalu sinkronkan ke lokasi yang dibaca Cursor:
rsync -a .agents/skills/ .cursor/skills/ && rm -rf .agents
```

`SPEC.md` di root tetap jadi sumber kebenaran untuk scope, tech stack, dan guardrail
crash-prevention — skill di atas mengatur *proses kerja*, bukan menggantikan spec ini.

## Catatan teknis

- **Riverpod tanpa code generator**: `riverpod_generator` menyebabkan konflik dependency yang
  tidak bisa diresolusi di snapshot pub ecosystem saat ini (`custom_lint_core` menarik `analyzer`
  versi yang bertentangan dengan constraint `freezed`). Provider ditulis manual
  (`Provider`/`AsyncNotifierProvider`) — tetap valid & testable, bisa dievaluasi ulang nanti kalau
  versi-versi paket sudah kompatibel.
- **Backend**: REST API custom Alita tetap dipakai sebagai sumber data utama (lihat `SPEC.md`
  §4). Firebase hanya untuk Crashlytics/Analytics/App Check/Cloud Functions/Data
  Connect/Auth-anonymous.
