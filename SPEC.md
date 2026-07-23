# Alita Pricelist v3 — Rewrite Spec

> Koreksi terhadap draft awal: draft awal berisi ASUMSI generik app B2B pricelist yang **tidak
> cocok** dengan app lama sebenarnya. Spec ini sudah dikoreksi berdasarkan audit langsung ke
> `~/StudioProjects/alitapricelist` dan `~/StudioProjects/alitapricelist copy` (v1.7.96+124,
> baseline yang dipilih karena lebih baru & superset fitur).

---

## 1. Overview

Alita Pricelist adalah aplikasi internal B2B Flutter untuk tim sales Massindo — bukan sekadar
"lihat pricelist", tapi alat kerja sales lengkap: browse produk & harga, hitung diskon, buat
Surat Pesanan (SP)/checkout, approval diskon berjenjang, quotation/penawaran (PDF), dan riwayat
order. Versi lama (baseline: `alitapricelist copy`) sering crash dengan penyebab yang belum
teridentifikasi jelas.

Tujuan rewrite: bangun ulang dari nol (project Flutter baru) dengan arsitektur yang **secara
struktural** mencegah kelas-kelas crash paling umum — bukan sekadar menyalin kode lama, karena
tech stack level tinggi (Riverpod, GoRouter, Freezed) **sudah dipakai di versi lama**. Sumber
crash yang lebih mungkin: null-assertion (`!`), `.first`/`.last` pada list yang bisa kosong,
force-cast JSON (`as Map<String, dynamic>`) tanpa validasi, dan kemungkinan gap `context.mounted`
di path yang belum teraudit — bukan pilihan state-management/routing/model itu sendiri.

## 2. Goals

- Semua fitur versi lama (baseline `alitapricelist copy`, lihat §5) berjalan tanpa regresi
- Tidak ada uncaught exception yang bisa membuat app force-close
- Crash reporting (Crashlytics) aktif sejak hari pertama skeleton, bukan ditambahkan belakangan
- Codebase testable — logic kritis (kalkulasi diskon/harga, auth, approval chain) punya unit test
- Menghapus kelas bug spesifik yang ditemukan di audit: null-assertion di `customer_repository`,
  `store_repository`, `delivery_info_section`; `.first` tanpa guard di approval/checkout/PDF;
  force-cast JSON tanpa validasi di path approval/history/PDF

## 3. Non-goals

- Tidak menambah fitur baru di luar yang sudah ada di versi lama (kecuali error handling/monitoring)
- **Tidak migrasi backend** — REST API custom ("Alita" API) tetap dipakai sebagai sumber data
  utama; integrasi Firebase (Crashlytics, Analytics, App Check, Cloud Functions, Data Connect,
  Messaging, Auth-anonymous) juga dipertahankan apa adanya, hanya client yang ditulis ulang
- Tidak mengganti provider pembayaran/PDF/geolocation vendor yang sudah dipakai

## 4. Tech Stack

| Layer | Pilihan | Catatan koreksi |
|---|---|---|
| State management | Riverpod (`flutter_riverpod` + `riverpod_generator` untuk kode baru) | Sama dengan versi lama; ditulis ulang dengan generator untuk type-safety lebih baik |
| Routing | GoRouter + `app_links` (deep link) | Sama; redirect logic ditulis ulang dengan guard "loading" eksplisit (lihat §6) |
| Model data | Freezed + json_serializable | Sama; **tidak ada** null-assertion `!` saat parsing — pakai default value/sealed error state |
| Network | `http`/`Dio` (pilih salah satu saat implementasi) via `ApiClient` custom + interceptor retry/timeout/error-mapping terpusat | Versi lama pakai `http` polos tanpa interceptor terpusat — ini titik perbaikan utama |
| Backend utama | **REST API custom** ("Alita" API — OAuth-style `client_id`/`client_secret`, `access_token`) | **Bukan Firestore/RTDB.** Ini koreksi paling penting dari draft awal |
| Backend pendukung (Firebase) | Crashlytics, Analytics, App Check, Cloud Functions (notifikasi approval), Firebase Messaging (push), Firebase Data Connect (lookup/upsert customer), Firebase Auth (**anonymous only**, untuk Data Connect/App Check — bukan login utama) | Login user tetap ke REST API, bukan Firebase Auth email/password |
| Local cache/offline | SharedPreferences (flags) + FlutterSecureStorage (access token) + file JSON cache (master data, pricelist snapshot dgn flag `isFromStaleCache`, draft quotation) | Draft awal salah asumsi Hive/drift; app lama tidak pakai database lokal sama sekali. Boleh dievaluasi ulang saat implementasi kalau mau pakai Hive untuk cache yang lebih terstruktur, tapi bukan requirement wajib |
| Crash reporting | Firebase Crashlytics + `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` | Sudah ada di versi lama; pastikan pola ini ada dari commit pertama skeleton |
| PDF / share | `pdf` + `printing` + `share_plus` | Untuk invoice order & quotation |
| Geolocation | `geolocator` + `geocoding` | Untuk geotag approval diskon |
| Update check | `upgrader` + `in_app_update` (Android) + iTunes check (iOS) | Force/soft update |

## 5. Fitur (dikoreksi berdasarkan audit — baseline `alitapricelist copy` v1.7.96+124)

Urutan pengerjaan disusun dari fondasi → fitur inti → fitur pendukung:

1. **Auth** — login email/password ke REST API (bukan Firebase Auth), session persistence
   (SharedPreferences untuk profil, FlutterSecureStorage untuk token), auto-logout saat token
   invalid/expired, inisialisasi Firebase Auth anonymous pasca-login untuk Data Connect/App Check
2. **Pricelist browsing** (home, tanpa dashboard terpisah) — grid produk (masonry), filter
   berjenjang Area → Channel → Brand, search, sort. Ada fallback ke cache lokal (stale) saat
   koneksi lemah, dengan indikator "data dari cache"
3. **Kalkulasi harga / detail produk** — configurator varian (kasur/divan/headboard/sorong),
   harga dari komponen EUP + pricelist + bonus, diskon berjenjang (cascading `disc1..disc8`) dari
   ceiling API, reverse-calc diskon dari target total, floor price (`bottomPriceAnalyst`), reverse
   ke persentase untuk ditampilkan
4. **Favorites** — tandai produk favorit
5. **Cart** — keranjang sebelum checkout, dibangun dari hasil configurator produk
6. **Checkout / Surat Pesanan** — pilih customer/store/pengiriman, input pembayaran + upload
   bukti bayar, hitung net price per komponen, tentukan approval level berdasarkan besaran diskon
   (contoh: `discount3 > 0` → wajib approval manager), submit SP atau simpan sebagai quotation draft
7. **Approval diskon berjenjang** — inbox approval (pending/history) untuk role
   SPV/RSM/Analyst/Manager (role dideteksi dari string `workTitle`, bukan enum), approve/reject
   dengan geotag lokasi, notifikasi via Firebase Cloud Messaging + Cloud Functions
8. **Quotation / penawaran** — simpan draft quotation lokal, export PDF, restore ke checkout
9. **Order history** — daftar order, detail order, invoice PDF, share via WhatsApp
10. **Indirect Sales Hub** — mode Direct vs Indirect sales (gated admin), termasuk halaman custom
    line pricelist
11. **Profil user** — info akun, statistik ringkas, menu ke history/approval/quotation/help,
    logout
12. **Cross-cutting**: deep link (`app_links`), force/soft update check, help center

## 6. Guardrail Arsitektur Wajib (untuk cegah kelas crash yang ditemukan di audit)

- Setiap pemakaian `BuildContext` setelah `await` **wajib** dicek `context.mounted` dulu
- **Tidak ada** `!` (null assertion) di mana pun untuk data dari API/auth/storage — ganti dengan
  Freezed default value, sealed error state, atau early-return dengan pesan error jelas
  (koreksi konkret dari bug lama: `customer_repository.dart` `currentUser!`/`cred.user!`,
  `store_repository.dart` `_cacheDir!`, `delivery_info_section.dart` `selectedStore!`/`store!`)
- **Tidak ada** `.first`/`.last` pada list tanpa guard `isNotEmpty`/`isEmpty` check terlebih dulu —
  gunakan `firstOrNull`/`lastOrNull` + fallback eksplisit (koreksi konkret: `approval_decision_service.dart`
  `pending.first`, `approval_inbox_provider.dart` `placemarks.first`, `checkout_order_service.dart`
  `data.first`, `checkout_page.dart`/PDF helper `payments.first`)
- **Tidak ada** `as Map<String, dynamic>` mentah pada response JSON — semua parsing lewat model
  Freezed/json_serializable yang exhaustive; kegagalan parsing dipetakan ke `Result.failure`, bukan
  exception yang bocor ke UI (koreksi konkret: pola ini banyak dipakai di
  `approval_inbox_provider.dart`, `approval_detail_page.dart`, PDF/history path)
- Semua network call dibungkus try-catch di layer repository, dipetakan ke sealed `Result<T>`
  (`Success`/`Failure`), UI tidak pernah menerima exception mentah
- GoRouter `redirect` logic tidak boleh bergantung pada state auth yang belum ter-load — harus ada
  guard "loading" state eksplisit sebelum keputusan redirect diambil
- `runZonedGuarded` di `main()` membungkus seluruh app, terhubung ke Crashlytics, dilengkapi
  `FlutterError.onError` dan `PlatformDispatcher.instance.onError` (mengikuti pola yang sudah benar
  di versi lama — pastikan tidak regresi)
- Setiap provider yang punya efek samping (network call) punya state eksplisit:
  `loading | data | error` — tidak ada state "in-between" yang tidak tertangani UI

## 7. Testing

- Unit test wajib untuk: kalkulasi harga/diskon cascading (`calculateCascadingPrice`,
  `computeDiscountsFromTargetTotal`, floor price), auth flow (mock REST API), repository error
  mapping ke `Result<T>`, logika penentuan approval level dari diskon
- Widget test untuk halaman kritis: login, pricelist list, product detail (configurator), checkout
  (approval-level trigger)
- Tidak perlu 100% coverage — fokus ke logic yang paling sering jadi sumber bug lama (kalkulasi
  harga, parsing response, approval chain)

## 8. Urutan Kerja (full rewrite project baru, tapi bertahap secara teknis)

1. Setup project Flutter baru + skeleton arsitektur (folder structure, `Result<T>`, error
   handling global, `runZonedGuarded` + Crashlytics, `ApiClient` dasar) — **tanpa fitur dulu**
2. Auth module lengkap (login REST API, session persistence, Firebase Auth anonymous) + test
3. Pricelist browsing (filter Area/Channel/Brand, search, cache fallback)
4. Kalkulasi harga & detail produk (configurator + diskon cascading) + test
5. Favorites + Cart
6. Checkout/Surat Pesanan (termasuk penentuan approval level) + test
7. Approval workflow (inbox, approve/reject, geotag, notifikasi)
8. Quotation (draft + PDF)
9. Order history + invoice PDF
10. Indirect Sales Hub + custom line pricelist
11. Profil, help center, deep link, force update
12. QA pass: audit ulang semua async/context usage, null-assertion, `.first`, JSON cast sesuai
    guardrail di §6

Setiap langkah dikerjakan satu per satu, tunggu konfirmasi user sebelum lanjut ke langkah
berikutnya.
