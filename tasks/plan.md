# Implementation Plan: Kalkulasi Harga / Configurator (SPEC.md §8 Step 4)

## Overview

Modul kalkulasi harga murni (`price_calculator.dart`) untuk configurator, plus resolusi varian
sibling, item lookup (untuk nomor artikel kain/warna), dan halaman configurator itu sendiri —
dibangun di atas `PricelistItem` (Step 3, sudah punya seluruh field mentah `eupKasur..eupSorong`,
`disc1..8`, `bonus1..8`, `bottomPriceAnalyst`) tanpa parser kedua. Kontrak formula di bawah
diverifikasi dari audit langsung ke `~/StudioProjects/alitapricelist copy` (`product_detail_
utils.dart`, `product_variant_resolver.dart`, `product_detail_page.dart`, `discount_modal.dart`,
`item_lookup_provider.dart`, plus test lama `product_detail_utils_test.dart` untuk angka yang
sudah terverifikasi oleh test itu sendiri) — bukan tebakan baru.

## Keputusan yang sudah dikonfirmasi user

1. **Scope varian disederhanakan, hanya anchor kasur** — mayoritas kasus (set kasur+divan+
   headboard+sorong). Anchor divan/headboard/sorong standalone (produk aksesoris tanpa kasur)
   didokumentasikan sebagai follow-up terpisah, bukan blocker Step 4.
2. **Item lookup disertakan sekarang** — fungsinya murni memilih varian kain/warna per komponen
   (nomor artikel pabrik); dikonfirmasi dari kode lama bahwa lookup TIDAK pernah masuk ke
   kalkulasi harga, hanya dipakai untuk snapshot cart/order.
3. **Floor (`bottomPriceAnalyst`) SELALU ditegakkan di kedua jalur input** (target-harga ATAU
   input manual per-tier) — deviasi yang disengaja dari app lama, yang punya bug nyata: floor
   hanya dicek di jalur target-harga, input manual per-tier bisa lolos di bawah floor tanpa
   peringatan sama sekali kalau ceiling `disc1..8` mengizinkan. Modul baru menutup celah ini
   dengan satu titik enforcement yang dijalankan seragam di akhir `resolveFinalPrice`, apa pun
   jalur yang dipakai untuk sampai ke `finalPrice`.
4. **Markup (target ≥ base) didukung** — app lama diam-diam mengabaikan kasus ini (harga tetap
   di base). Sekarang: `target > base` → `finalPrice = target` langsung, tanpa diskon
   (`isMarkup = true`).

## Kontrak formula

### Anchor (komponen utama produk)

Hierarki kasur > divan > headboard > sorong, pola SAMA dengan `_modelGroupName` yang sudah ada
di `pricelist_grouping.dart` (Step 3) — sekarang diekstrak jadi helper bersama
`lib/features/pricelist/logic/pricelist_anchor.dart` supaya tidak ada dua implementasi
"isPresent"/hierarki yang bisa drift (salah satu temuan audit di app lama: ada 2 implementasi
reverse-calc yang beda file, dengan angka yang beda pula).

```
isComponentPresent(field) = field.trim().toLowerCase() tidak kosong && tidak diawali "tanpa"

anchor = isComponentPresent(kasur) ? kasur
       : isComponentPresent(divan) ? divan
       : isComponentPresent(headboard) ? headboard
       : sorong
```

### Base price (`baseTotalEup`)

EUP di-mask berdasar anchor — kasur EUP hanya ikut kalau anchor==kasur; divan EUP ikut kalau
anchor==kasur ATAU anchor==divan (produk beranchor divan tetap punya biaya divan-nya sendiri);
headboard/sorong EUP SELALU ikut (aksesori yang menempel di komponen utama apa pun):

```
kasurEup = anchor == kasur ? item.eupKasur : 0
divanEup = (anchor == kasur || anchor == divan) ? item.eupDivan : 0
baseTotalEup = kasurEup + divanEup + item.eupHeadboard + item.eupSorong
```

**Contoh angka konkret (diverifikasi dari data app lama):**
`eupKasur = 3.500.000, eupDivan = 1.750.000, eupHeadboard = 1.155.000, eupSorong = 0`
→ anchor=kasur → `baseTotalEup = 6.405.000`.
Anchor bukan kasur (misal headboard) pada item yang sama → `baseTotalEup = 1.155.000` (hanya
headboard+sorong, kasur & divan di-mask ke 0).

`pricelist`/`plKasur..plSorong` = harga coret (display saja). `bonus1..8`/`qtyBonus*`/`plBonus*`
= barang gratis (display saja). Keduanya **tidak** masuk formula harga sama sekali.

### Cascading discount (`disc1..disc8`)

Fraksi 0–1, ceiling per tier dari API. Tier dengan ceiling `0` di-drop (tidak dikonfigurasi untuk
item ini), urutan index tier lain tetap dipertahankan:

```
ceilings = [disc1..disc8].where(d > 0)

finalPrice = baseTotalEup
for d in appliedDiscounts (urutan tier 1→8):
    finalPrice *= (1 - d)
```

**Contoh angka konkret (diverifikasi ke test app lama `product_detail_utils_test.dart`):**
`cascade(100, [0.1, 0.2]) == 72` (100 × 0.9 × 0.8 = 72).

### Reverse-calc dari target harga akhir

Closed-form greedy per tier (BUKAN binary search) — untuk tiap ceiling (urut), ambil diskon
terbesar yang cukup untuk mencapai target tanpa melebihi ceiling tier itu, lalu lanjut ke tier
berikutnya dengan base yang sudah terdiskon:

```
if target <= 0 or baseTotalEup <= 0 or ceilings kosong: return []

base = baseTotalEup
hasil = []
for limit in ceilings:
    if base <= 0: break
    d = clamp(1 - target/base, 0, limit)
    if d ≈ 0 (<= 1e-9): break
    hasil.add(d)
    base *= (1 - d)
return hasil
```

**Contoh angka konkret (diverifikasi ke behavior app lama):**
`base=100, ceilings=[0.5, 0.5]`:
- `target=50` → `[0.5]` (tier 1 sendiri: `1 - 50/100 = 0.5`, pas ceiling, base jadi 50, tier 2
  butuh `1 - 50/50 = 0` → stop).
- `target=40` → `[0.5, 0.2]` (tier 1 ambil MAKSIMAL dulu sampai ceilingnya: `1 - 40/100 = 0.6`
  dipangkas ke ceiling `0.5` → base jadi 50; tier 2: `1 - 40/50 = 0.2`, di bawah ceiling jadi
  dipakai penuh).

Guard `baseTotalEup <= 0` mencegah pembagian oleh nol/negatif (NaN/Infinity) — sesuai guardrail
crash-prevention SPEC.md §6: fungsi ini tidak pernah throw, selalu `[]` yang aman.

### Floor price (`bottomPriceAnalyst`)

App lama: strict `<` (bukan `<=`), clamp NAIK ke floor (bukan ditolak), toast "Harga disesuaikan
ke nilai minimum", diskon dihitung ulang dari floor. Batas `target == bottomPriceAnalyst` (persis
sama) TIDAK dianggap di bawah floor — tidak ada re-clamp, tidak ada warning.

**Keputusan Anda (lihat #3 di atas)**: floor SELALU ditegakkan di kedua jalur, satu titik
enforcement di akhir `resolveFinalPrice`, dijalankan setelah `finalPrice` dihitung dari jalur
apa pun (target-based reverse-calc, manual per-tier, ATAUPUN markup — edge case, tapi
pengecekannya harus seragam):

```
if item.bottomPriceAnalyst > 0 and finalPrice < item.bottomPriceAnalyst:
    appliedDiscounts = computeDiscountsFromTarget(target: bottomPriceAnalyst, baseTotalEup, ceilings)
    finalPrice = applyCascadingDiscounts(baseTotalEup, appliedDiscounts)
    isFloorApplied = true
```

### Markup (target ≥ base)

App lama: diam-diam diabaikan, harga tetap di base (bug tersembunyi — user yang input target di
atas base tidak mendapat apa yang mereka minta, tanpa penjelasan).

**Keputusan Anda (lihat #4 di atas)**: didukung — `target > baseTotalEup` → `finalPrice = target`
langsung, `appliedDiscounts = []`, `isMarkup = true`. Floor check tetap dijalankan seragam di
akhir (secara teori tidak akan pernah trigger di jalur ini karena `target > base >= floor` pada
data valid, tapi enforcement tetap seragam demi keamanan alih-alih mengasumsikan invarian itu).

### Rounding

TIDAK ADA rounding di pipeline `price_calculator.dart` — semua `double` mentah, sama seperti app
lama. Rounding hanya terjadi di layer formatting tampilan (mata uang), bukan di kalkulasi.

### Item lookup (`pl_lookup_item_nums`)

Disertakan sekarang (keputusan #2). Fungsinya murni memilih varian kain/warna per komponen
(untuk nomor artikel pabrik) — TIDAK mempengaruhi harga sama sekali. Grouping:
`Map<tipe.toLowerCase(): List<ItemLookupEntry>>`, difilter lagi per `ukuran == effectiveSize`.
Belum diimplementasikan di iterasi ini (task `item-lookup` di `tasks/todo.md`, dikerjakan agent
lain secara paralel).

## Keputusan arsitektur

1. **Anchor logic diekstrak jadi shared helper** — `lib/features/pricelist/logic/
   pricelist_anchor.dart` (`enum AnchorType`, `isComponentPresent`, `resolveAnchor`), dipakai baik
   oleh `pricelist_grouping.dart` (Step 3, `_modelGroupName`) maupun `price_calculator.dart`
   (Step 4). Behavior `_modelGroupName` TIDAK berubah — hanya delegasi ke helper bersama, semua
   test Step 3 yang sudah ada tetap hijau tanpa modifikasi.
2. **Modul kalkulasi murni, tanpa Widget/BuildContext** (SPEC.md §6) — `price_calculator.dart`
   hanya berisi top-level functions + satu value class hasil (`PriceCalculationResult`, plain
   class dengan `==`/`hashCode` manual, bukan Freezed — terlalu kecil untuk butuh code gen).
   Single entry point `resolveFinalPrice({item, anchor, manualDiscounts?, targetPrice?})`
   menegakkan floor & markup secara seragam, apa pun jalur inputnya.
3. **Tidak ada `Result<T>`/`AppException` di modul ini** — semua fungsi di sini murni matematika
   tanpa I/O dan tidak pernah gagal (menurut definisi, degradasi ke default aman `0`/`[]`
   menggantikan exception, SPEC.md §6), jadi tidak ada kegagalan yang perlu direpresentasikan.
4. **TDD ketat**: test ditulis mengacu angka yang SAMA dengan yang sudah terverifikasi oleh test
   app lama (`product_detail_utils_test.dart`) untuk kasus-kasus yang overlap, plus kasus baru
   sesuai 2 keputusan deviasi (floor manual-tier, markup) yang secara sengaja akan GAGAL kalau
   modul baru punya celah yang sama dengan app lama.

## Task List

- [x] **Task `spec`**: Tulis kontrak formula lengkap (rumus + contoh angka) ke `tasks/plan.md`
      (dokumen ini).
- [x] **Task `calc-module`**: Implement `price_calculator.dart` (`calculateBaseTotalEup`,
      `nonZeroDiscountCeilings`, `applyCascadingDiscounts`, `computeDiscountsFromTarget`,
      `resolveFinalPrice`, `PriceCalculationResult`) + refactor dedup `pricelist_anchor.dart`.
- [x] **Task `calc-tests`**: Test murni untuk semua kasus kontrak formula di atas, termasuk edge
      case floor manual-tier & markup, plus guard `baseTotalEup <= 0`.
- [ ] **Task `variant-resolver`**: Implement `variant_resolver.dart` (simplified, anchor kasur,
      dari raw sibling `filteredPricelistSnapshotProvider`) + test. *(Dikerjakan agent lain,
      paralel — tidak disentuh di iterasi ini.)*
- [ ] **Task `item-lookup`**: Implement `item_lookup_grouping.dart` + wiring ke
      `PricelistRepository.getItemLookups()` + test. *(Dikerjakan agent lain, paralel.)*
- [ ] **Task `configurator-ui`**: Build `ConfiguratorPage` — variant picker, kain/warna picker,
      breakdown harga, input diskon manual/target, indikator floor/markup.
- [ ] **Task `wiring`**: Wire tap grid card (`PricelistHomePage`) → `ConfiguratorPage` lewat
      router.
- [ ] **Task `review`**: `code-review-and-quality` + ringkasan akhir ke user sebelum Langkah 5
      (Favorites/Cart).

## Risks and Mitigations

| Risk | Impact | Mitigasi |
|---|---|---|
| Angka reverse-calc/cascading bisa salah kalau ditebak ulang dari nol | Tinggi (langsung memengaruhi harga jual) | Semua contoh angka di kontrak formula diverifikasi ke test app lama yang sudah terbukti benar di production, bukan tebakan baru |
| Refactor `_modelGroupName` ke helper bersama bisa mengubah behavior Step 3 tanpa disadari | Medium | Test Step 3 (`pricelist_grouping_test.dart`) dijalankan ulang TANPA modifikasi setelah refactor — harus tetap hijau semua sebagai bukti behavior identik |
| Floor enforcement yang seragam (deviasi dari app lama) bisa punya efek samping tak terduga di kombinasi tier tertentu | Medium | Test eksplisit untuk kasus "manual discount di bawah floor" — kasus yang justru dulu jadi bug nyata di app lama, dibuktikan tertutup di modul baru |
| Pekerjaan paralel oleh agent lain (`variant_resolver.dart`, `item_lookup_grouping.dart`) bisa konflik file/commit | Low | Scope commit dibatasi hanya ke file yang benar-benar dibuat/diubah pada iterasi ini (`git add` per-file, bukan `-A`) |

## Open Questions

*(Tidak ada — 4 keputusan yang perlu dikonfirmasi sudah dijawab user sebelum plan ini ditulis;
lihat bagian "Keputusan yang sudah dikonfirmasi user" di atas. Scope varian standalone
divan/headboard/sorong didokumentasikan sebagai follow-up eksplisit, bukan open question yang
memblokir Step 4.)*
