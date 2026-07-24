# Implementation Plan: Pricelist Browsing (SPEC.md §8 Step 3)

## Overview

Home page (tidak ada dashboard terpisah) yang menampilkan grid produk pricelist, dengan filter
berjenjang Area → Channel → Brand, search (nama produk), sort (nama/harga), dan fallback ke cache
lokal (file JSON) saat network gagal, dengan indikator `isFromStaleCache` ke UI. Endpoint dan
bentuk response semuanya diverifikasi dari audit langsung ke
`~/StudioProjects/alitapricelist copy` (subagent report, bukan tebakan) — lihat bagian "Kontrak
API" di bawah.

## Keputusan yang sudah dikonfirmasi user (AskQuestion sebelum implementasi)

1. **Area/Channel/Brand: TANPA file cache di langkah ini** — panggil network langsung setiap kali
   (`network_only`). Cache file + TTL bisa ditambah nanti kalau perlu; app lama punya ini (TTL 6
   jam) tapi scope eksplisit user hanya minta cache untuk `filtered_pl`.
2. **Grid mengelompokkan baris per nama model** (`group_by_name`) — `filtered_pl` mengembalikan
   banyak baris per model (satu per ukuran/varian), direplikasi dari app lama: satu card per nama
   produk, harga yang ditampilkan = harga terendah yang > 0 di antara variannya. Ini demi SPEC
   goal #1 ("semua fitur versi lama berjalan tanpa regresi").
3. **Search hanya mencocokkan nama produk** (`name_only`) — TIDAK match ke `description`, karena
   `description` (dari `detail_list`) sering kosong dan jatuh ke placeholder string default yang
   sama untuk semua produk (beda dari app lama yang match name+description).

## Kontrak API (diverifikasi dari audit `alitapricelist copy`, BUKAN tebakan)

Sumber: `lib/features/pricelist/logic/master_data_provider.dart`, `product_provider.dart`,
`item_lookup_provider.dart`, `accessory_provider.dart`, `data/models/{product,item_lookup,
accessory}.dart`, `core/services/api_client.dart`.

**Auth pada semua endpoint ini**: query param `access_token` + `client_id` + `client_secret` —
sudah otomatis lewat `ApiClient` (`access_token`) untuk yang perlu ditambah manual
(`client_id`/`client_secret`, sama seperti `AuthRepository.login()`).

### GET `/api/pl_areas`, `/api/pl_channels`, `/api/pl_brands`

- Tidak ada model Dart di app lama (raw `Map`) — field di bawah ini disimpulkan dari cara field
  itu dibaca di provider (bukan dari `fromJson` eksplisit).
- **Envelope toleran** — app lama menerima SEMUA bentuk ini: bare `List`, `{"data": [...]}`,
  `{"pl_areas"/"pl_channels"/"pl_brands": [...]}`, atau nested `{"result": {...salah satu di
  atas...}}`. Kita replikasi toleransi ini (bukan cuma pilih satu bentuk) supaya tidak crash kalau
  backend kembalikan bentuk yang sedikit berbeda antar endpoint.
- **Area**: field `name` (fallback ke `area` kalau `name` tidak ada) → `String`.
- **Channel**: `{"id": 223, "channel": "Direct"}` → `id` (int), `channel` (String, nama).
- **Brand**: `{"id": 622, "brand": "Comforta", "pl_channel_id": 223}` → `id` (int), `brand`
  (String, nama), `plChannelId` (int) — dipakai untuk filter Brand berdasarkan Channel terpilih
  (join client-side, PERSIS app lama: `brand.pl_channel_id == channel.id`).

### GET `/api/rawdata_price_lists/filtered_pl?area=...&channel=...&brand=...`

- Query: `area` (Title Case — app lama selalu Title-Case sebelum kirim), `channel`, `brand` (nama
  channel/brand, bukan id).
- Envelope: `{"data": [...]}` atau bare `[...]`.
- Baris (`PricelistItem`) — snake_case dari API, field & fallback (SEMUA sudah exact, dari
  `mapFilteredPlRawListToProducts`):

  | Field model | JSON key(s) | Parsing |
  |---|---|---|
  | `id` | `id` | `.toString()`, default `''` |
  | `name` | `kasur` + `ukuran` | `'$kasur $ukuran'.trim()`; kosong → `'Produk Tanpa Nama'` |
  | `price` | `end_user_price` | num→double, else `tryParse`, else `0.0` |
  | `imageUrl` | `image_url`/`imageUrl`/`gambar`/`foto`/`thumbnail`/`photo_url`/`product_image`/`image` | url http(s) pertama yang ditemukan; else placeholder |
  | `category` | `series` | default `'Uncategorized'` |
  | `description` | `detail_list` | default placeholder Indonesia |
  | `channel`, `brand` | `channel`/`brand` | fallback ke param request kalau kosong |
  | `program` | `program` | default `'-'` |
  | `kasur`,`ukuran`,`divan`,`headboard`,`sorong` | sama | default `''` |
  | `isSet` | `set` | `json['set'] == true` (strict, tidak ada `!`) |
  | `pricelist`,`eupKasur`,`eupDivan`,`eupHeadboard`,`eupSorong` | `pricelist`,`eup_kasur`,`eup_divan`,`eup_headboard`,`eup_sorong` | toDouble |
  | `plKasur`,`plDivan`,`plHeadboard`,`plSorong` | `pl_kasur`,`pl_divan`,`pl_headboard`,`pl_sorong` | toDouble |
  | `bonus1..8` | `bonus_1..8` | `?.toString()` |
  | `qtyBonus1..8` | `qty_bonus1..8` | int atau `tryParse` |
  | `plBonus1..8` | `pl_bonus_1..8` | null kalau key null, else toDouble |
  | `bottomPriceAnalyst` | `bottom_price_analyst` | toDouble, default 0 |
  | `disc1..8` | `disc_i`/`disc$i`/`discount_i`/`max_disc_i` | key pertama yang bernilai > 0; kalau > 1 dibagi 100 |

  Model ini disengaja mencakup SEMUA field mentah (bukan cuma yang dipakai grid browsing), supaya
  Langkah 4 (configurator/kalkulasi harga) tidak perlu parsing ulang — field kasur/divan/headboard/
  sorong/bonus/disc memang tidak dipakai UI grid di langkah ini, tapi sudah benar secara kontrak.

### GET `/api/pl_lookup_item_nums`, GET `/api/pl_accessories`

- Tidak dipakai UI grid di langkah ini (dipakai configurator, Langkah 4) — tapi repository tetap
  menyediakan method-nya sekarang (sesuai instruksi user: "Repository ... untuk kelima endpoint di
  atas") supaya tidak ada raw JSON yang lolos dari layer network.
- **ItemLookupEntry**: `{"tipe","ukuran","item_num","jenis_kain","warna_kain"}` → semua
  `?.toString()`, default `''` kecuali `jenisKain`/`warnaKain` nullable.
- **Accessory**: `{"tipe","item_num","ukuran","pricelist"}` → sama, `pricelist` toDouble.
- Envelope: `status == 'success'` lalu ambil `result` (item lookup) atau `result`/`data` (accessory).

## Keputusan arsitektur

1. **Model API (snake_case) == model domain** — tidak ada pemisahan DTO vs domain seperti
   `LoginResponse` vs `AuthUser`; `PricelistItem` langsung dipakai baik untuk hasil network maupun
   yang disimpan ke cache file (as JSON, camelCase field Dart standar via `toJson`). Ini lebih
   simpel dari app lama (yang punya 2 bentuk: live snake_case vs cache camelCase) karena kita
   kontrol keduanya lewat satu `fromJson`/`toJson` Freezed.
2. **Cascading filter = satu `PricelistFilterNotifier`** (bukan 3 `StateProvider` independen +
   `ref.listen` untuk reset). State: `{String? area, String? channel, String? brand}`. Method
   `selectArea()`/`selectChannel()`/`selectBrand()` masing-masing reset field di bawahnya secara
   eksplisit — ini yang membuat guard "ganti Area reset Channel+Brand" mudah di-unit-test tanpa
   widget.
3. **Brand list = derived provider**, bukan network call terpisah per channel — filter brand dari
   HASIL `brandsProvider` (semua brand) berdasarkan `plChannelId == channel.id` milik channel
   terpilih (`selectedChannel`). Kalau channel belum dipilih → list brand kosong.
4. **Cache**: `PricelistCacheStore` (file JSON di `getApplicationSupportDirectory()`, pola sama
   `path_provider` yang sudah ada di `pubspec.yaml`). Key = hash dari
   `area|channel|brand` (lowercase, trim) supaya tidak ada karakter aneh di nama file. Isi file:
   `{"cachedAt": "<ISO8601>", "items": [...PricelistItem.toJson()]}`. TIDAK ada TTL check saat
   baca — dipakai HANYA sebagai fallback saat network gagal (persis instruksi user & app lama).
5. **`PricelistSnapshot`** (bukan Freezed, cukup value object sederhana) = `{items:
   List<PricelistItem>, isFromStaleCache: bool, fetchedAt: DateTime}` — dikembalikan repository
   sebagai `Result<PricelistSnapshot>`. `fetchedAt` diisi dari `cachedAt` file kalau dari cache,
   atau `DateTime.now()` kalau dari network — dipakai UI untuk teks "data dari cache jam ...".
6. **Repository, bukan network call langsung dari provider** (beda dari app lama yang manggil
   `ApiClient.instance` langsung dari provider) — `PricelistRepository` di
   `features/pricelist/data/services/`, konsisten dengan `AuthRepository`. Semua network+cache
   logic ada di repository; provider hanya orkestrasi state.
7. **Grouping by name**: `PricelistRepository` mengembalikan raw items (semua baris/varian) —
   grouping-jadi-satu-card-per-nama dilakukan di provider layer (`groupedPricelistProvider`, murni
   fungsi tanpa side effect), BUKAN di repository, supaya repository tetap merepresentasikan
   kontrak API asli 1:1 dan grouping bisa diuji terpisah dari network/cache.
   **Koreksi ditemukan lewat TDD (Task 9)**: grouping key yang benar adalah `kasur` (dengan
   fallback ke `divan`/`headboard`/`sorong`/`name` kalau `kasur` kosong/`"Tanpa Kasur"`) — BUKAN
   `PricelistItem.name` (yang berisi `"<kasur> <ukuran>"`). Kalau grouping pakai `name`, tiap
   ukuran akan tetap jadi card sendiri-sendiri karena `name` selalu unik per ukuran — itu
   menggagalkan tujuan grouping. Ini sesuai persis `groupProductsByVariantModel` di app lama
   (`product_provider.dart:534`), ditemukan test gagal duluan sebelum kode diperbaiki (RED→GREEN).
   Card hasil grouping menampilkan `name` = nama model (misal `"Comforta Elite"`), bukan nama
   varian ukuran.
8. **Sort options**: "Nama (A-Z)" (default), "Harga: Rendah ke Tinggi", "Harga: Tinggi ke Rendah"
   — tidak menyalin opsi "Terbaru" app lama (itu sebenarnya no-op/placeholder karena tidak ada
   field timestamp asli untuk sorting kronologis di data ini).
9. **UI**: ganti `PlaceholderHomePage` jadi `PricelistHomePage` langsung di route `/` (bukan
   halaman baru + placeholder tetap ada) — sesuai instruksi "home page (tidak ada dashboard
   terpisah)".

## Task List

### Phase 1: Models (murni data, tanpa network)

- [ ] **Task 1**: Model `Area`, `Channel`, `Brand` (Freezed, hand-written `fromJson` seperti
      `LoginResponse`/`AuthUser` — bukan `json_serializable` karena perlu logic
      fallback/toleransi-envelope). Tambah fungsi murni `parseMasterDataEnvelope(dynamic decoded,
      {required String listKey})` yang menangani semua bentuk envelope (bare list/`data`/
      `listKey`/nested `result`), dipakai ketiganya. Test: setiap bentuk envelope + field
      fallback (`area` vs `name`) + JSON kosong/rusak → list kosong, bukan throw.
- [ ] **Task 2**: Model `PricelistItem` (Freezed, hand-written `fromJson` sesuai tabel kontrak di
      atas) + `toJson` untuk cache. Test: parsing lengkap, fallback tiap field (terutama
      `imageUrl` multi-key, `disc1..8` multi-key-first-match, `bonus`/`qtyBonus`/`plBonus` null
      handling), dan envelope `{"data":[...]}` vs bare list.
- [ ] **Task 3**: Model `ItemLookupEntry`, `Accessory` (Freezed, hand-written `fromJson`, lebih
      sederhana dari Task 2). Test: field lengkap + field hilang → default.

### Checkpoint 1
- [ ] Semua test Phase 1 hijau, `flutter analyze` bersih, commit.

### Phase 2: Repository + cache

- [ ] **Task 4**: `PricelistRepository.getAreas()/getChannels()/getBrands()` — panggil
      `ApiClient.get`, parse pakai `parseMasterDataEnvelope`, `Result<List<T>>`. Test: sukses,
      401/network/parsing error → `AppException` yang sesuai (pola sama `AuthRepository` test).
- [ ] **Task 5**: `PricelistCacheStore` (file JSON, `path_provider`) — `save(key, items)`,
      `load(key)` (return `null` kalau file tidak ada/corrupt, bukan throw), `keyFor(area, channel,
      brand)`. Test: round-trip save→load, load saat file belum ada, load saat file corrupt
      (harus `null`, tidak throw).
- [ ] **Task 6**: `PricelistRepository.getFilteredPricelist(area, channel, brand)` — network dulu;
      sukses → simpan ke cache + `isFromStaleCache: false`; network gagal
      (`NetworkException`/`TimeoutAppException`) → coba cache; ada isi → `isFromStaleCache: true`;
      cache kosong juga → propagate error asli (jangan ditelan). Error lain (401/parsing/dll,
      BUKAN network/timeout) → **tidak** fallback ke cache, langsung `Result.failure` (biar user
      tahu ada masalah nyata, bukan cuma sinyal lemah). Test: kasus TDD wajib dari instruksi user:
      network sukses (`isFromStaleCache=false` + cache ter-refresh), network gagal + ada cache
      (`isFromStaleCache=true`), network gagal + tidak ada cache (failure asli diteruskan), error
      non-network (401/parsing) tidak fallback ke cache.
- [ ] **Task 7**: `PricelistRepository.getItemLookups()/getAccessories()` — sama pola Task 4,
      tanpa cache (di luar scope UI langkah ini, tapi tetap `Result<T>`, bukan raw JSON).

### Checkpoint 2
- [ ] Repository + cache test hijau (termasuk semua kasus cache fallback), `flutter analyze`
      bersih, commit.

### Phase 3: Filter berjenjang + grouping/search/sort (logic, sebelum UI)

- [ ] **Task 8**: `PricelistFilterNotifier` (`Notifier<PricelistFilterState>`) —
      `selectArea(String)` reset channel+brand ke null; `selectChannel(String)` reset brand ke
      null; `selectBrand(String)` tidak reset apa-apa. Test murni logic (tanpa widget): urutan
      pilih Area→Channel→Brand lalu ganti Area di tengah → Channel & Brand harus null lagi; ganti
      Channel setelah Brand terpilih → Brand harus null.
- [ ] **Task 9**: `brandsForSelectedChannelProvider` (derived, filter `brand.plChannelId ==
      channel.id`), `groupedPricelistProvider` (pure function: group by `name`, ambil item dengan
      `price` terendah yang `> 0`; kalau semua harga 0/tidak ada yang valid, tetap ambil satu
      representatif — jangan sampai grup hilang total). Test: grouping dengan beberapa
      harga (termasuk yang 0), channel→brand filter join.
- [ ] **Task 10**: `searchQueryProvider` + `sortOptionProvider` + `filteredSortedPricelistProvider`
      (pure function: filter nama case-insensitive, lalu sort sesuai opsi). Test: search
      cocok/tidak cocok (case-insensitive), tiap opsi sort.

### Checkpoint 3
- [ ] Semua test logic Phase 3 hijau (murni Dart, tanpa widget), `flutter analyze` bersih, commit.

### Phase 4: UI — ganti PlaceholderHomePage

- [ ] **Task 11**: `PricelistHomePage` — search box (debounce ringan), tombol sort (bottom sheet
      atau menu), filter pills Area→Channel→Brand (pakai `PricelistFilterNotifier`, sembunyikan
      Channel sampai Area dipilih, sembunyikan Brand sampai Channel dipilih), grid
      `MasonryGridView` (`flutter_staggered_grid_view`, tambah ke `pubspec.yaml`) dari
      `filteredSortedPricelistProvider`, banner/badge kecil kalau `isFromStaleCache == true`.
      Wire ke `app_router.dart` (ganti `PlaceholderHomePage` → `PricelistHomePage` di route `/`).
      Widget test: render filter awal (cuma Area pills), pilih Area → Channel muncul, pilih semua
      3 filter → grid muncul, banner cache muncul saat `isFromStaleCache=true`.

### Checkpoint 4 (final)
- [ ] Full test suite hijau, `flutter analyze` 0 issues.
- [ ] `code-review-and-quality` pass.
- [ ] Ringkasan + keputusan yang diambil ditunjukkan ke user sebelum lanjut ke Langkah 4.

## Risks and Mitigations

| Risk | Impact | Mitigasi |
|---|---|---|
| Bentuk response Area/Channel/Brand di server production ternyata beda dari yang disimpulkan dari app lama (karena app lama juga cuma baca raw Map, tidak ada kontrak resmi) | Medium | `parseMasterDataEnvelope` toleran ke banyak bentuk; field pakai `?? fallback`, tidak ada `!` — kalau bentuk beda, hasilnya list kosong/field default, bukan crash |
| `filtered_pl` bisa mengembalikan ribuan baris (banyak varian ukuran) — grouping di client bisa lambat kalau list besar | Low-Medium | Grouping pakai `Map` (O(n)), bukan nested loop; profil kalau ada masalah performa nanti setelah data asli terlihat |
| Cache file JSON bisa korup (app force-close saat menulis) | Low | `PricelistCacheStore.load()` bungkus try-catch, kembalikan `null` (bukan throw) kalau parse gagal — network tetap jadi sumber utama |
| Tidak ada akses ke server asli untuk verifikasi response real (sama seperti Langkah 2) | Medium | Semua test pakai mock Dio; kontrak API dari audit kode app lama yang sudah terbukti jalan di production, bukan tebakan baru |

## Open Questions

*(Tidak ada — 3 keputusan yang perlu dikonfirmasi sudah dijawab user sebelum plan ini ditulis;
lihat bagian "Keputusan yang sudah dikonfirmasi user" di atas.)*
