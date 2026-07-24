# API Map — Alita REST API (source: Postman collection "Alita Pricelist")

This is the authoritative endpoint reference pulled directly from the team's Postman collection
(`16020265-08e701d8-99a6-469b-ac4f-4043fd7f1703`, workspace "My Workspace", last synced
2026-07-24). It supersedes guesses — every endpoint below is a real request from that collection,
not reverse-engineered from app code. Cross-referenced against SPEC.md §8 step numbers where
applicable.

**Standard auth pattern** (unless noted otherwise): every endpoint appends
`access_token={{access_token}}&client_id={{client_id}}&client_secret={{client_secret}}` as query
parameters — this matches `ApiClient`'s `_AccessTokenQueryInterceptor` (Step 2) exactly. Only
`/sign_in` omits `access_token` (no session yet); only `/sign_out` sends all three in the body
instead of the query string.

## 01. Auth — SPEC.md §8 Step 2 (done)

| Request | Method | Path | Notes |
|---|---|---|---|
| Sign In | POST | `/api/sign_in?client_id&client_secret` | Body: `{email, password}`. Matches `AuthRepository.login()`. |
| Sign Out | DELETE | `/api/sign_out` | Body (not query): `{client_id, client_secret, access_token}`. **Not yet implemented** — deferred per `tasks/plan.md` open question. |

## 02. Attendance

| Request | Method | Path | Notes |
|---|---|---|---|
| Attendance List | GET | `/api/attendance_list?user_id` | Standard auth. |

## 03. Pricelist — SPEC.md §8 Step 3 (next)

| Request | Method | Path | Query params | Notes |
|---|---|---|---|---|
| PL Areas | GET | `/api/pl_areas` | standard auth | |
| PL Channels | GET | `/api/pl_channels` | standard auth | |
| PL Brands | GET | `/api/pl_brands` | standard auth | |
| Filtered PL | GET | `/api/rawdata_price_lists/filtered_pl` | + `area`, `channel`, `brand` | The core pricelist browsing query. Example: `area=Nasional&channel=Indirect&brand=Spring Air - American Classic`. |
| Item Lookup | GET | `/api/pl_lookup_item_nums` | standard auth | |
| PL Accessories | GET | `/api/pl_accessories` | standard auth | |

## 04. Indirect Store

| Request | Method | Path | Notes |
|---|---|---|---|
| Assigned Stores by Sales Code | GET | `http://103.165.210.58/address_number/address_number_by_sales_code?sales_code=` | **Different host entirely**, not `{{baseURL}}`. Auth via headers `x-api-key: {{indirect_api_key}}` + `x-client-key: {{indirect_client_key}}` — no query auth. Matches `.env`'s `INDIRECT_STORES_BASE_URL`/`INDIRECT_API_KEY`/`INDIRECT_CLIENT_KEY` (deferred, not yet in this project's `.env`). |
| Store Discounts | GET | `/api/store_discounts?kode_toko=` | On `{{baseURL}}`, no access_token/client_id in this one (as captured — verify against live server before relying on it). |

## 05. Order Letters (cart/checkout — SPEC.md later step)

| Request | Method | Path | Body | Notes |
|---|---|---|---|---|
| List Order Letters | GET | `/api/order_letters?user_id` | — | |
| Get Order Letter by ID | GET | `/api/order_letters/{id}` | — | |
| Update Order Letter | PUT | `/api/order_letters/{id}` | `{take_away: bool}` | |
| Create Order Letter (Header) | POST | `/api/order_letters` | see below | Header `Content-Type: application/json`. |
| List Order Letter Details | GET | `/api/order_letter_details` | — | |
| Create Order Letter Detail | POST | `/api/order_letter_details` | see below | |
| Delete Order Letter Detail | DELETE | `/api/order_letter_details/{{detail_id}}` | — | |
| All Stores | GET | `/api/all_stores` | — | |
| Discount Limits | GET | `/api/order_letter_limits?user_id` | — | |
| Create Order Letter Payment | POST | `/api/order_letter_payments` | formdata (empty in collection — likely file upload, needs live verification) | |
| Create Order Letter Contact | POST | `/api/order_letter_contacts` | `{order_letter_id, phone, ship}` | |

**Create Order Letter (Header) body:**
```json
{
  "order_date": "2026-07-14",
  "request_date": "2026-07-20",
  "creator": 5206,
  "customer_name": "Sample Customer",
  "phone": "08123456789",
  "email": "{{email}}",
  "address": "Jl. Sample",
  "ship_to_name": "Sample Customer",
  "address_ship_to": "Jl. Sample",
  "extended_amount": 1000000,
  "harga_awal": 1200000,
  "discount": 16.67,
  "note": "",
  "status": "Pending",
  "sales_code": null,
  "work_place_id": 0,
  "take_away": null,
  "postage": 0,
  "channel": "S1"
}
```

**Create Order Letter Detail body:**
```json
{
  "order_letter_id": 921,
  "no_sp": "26021211011045",
  "item_number": "I110340492",
  "desc_1": "iSleep Silent",
  "desc_2": "090x200",
  "brand": "iSleep",
  "unit_price": 5700000,
  "customer_price": 1700000,
  "net_price": 1700000,
  "qty": 1,
  "item_type": "Kasur",
  "take_away": true
}
```

## 06. Order Letter Discounts (approval flow)

All four discount-request variants POST to the **same** endpoint (`/api/order_letter_discounts`),
distinguished only by body content (`approver_level_id`/`approver_level`):

| Variant | `approver_level_id` | `approver_level` |
|---|---|---|
| User (L1) | 1 | `"User"` |
| Direct | 2 | `"Direct Leader"` |
| Indirect | 3 | `"Indirect Leader"` |
| Analyst (L4) | 4 | `"Analyst"` |

Example body (User L1 — includes `approved: true`, the others omit it):
```json
{
  "order_letter_id": 921,
  "order_letter_detail_id": 5236,
  "discount": 0,
  "approver": 1047,
  "approver_name": "Indra  Sukmana",
  "approver_level_id": 1,
  "approver_level": "User",
  "approved": true
}
```

| Request | Method | Path | Notes |
|---|---|---|---|
| Update Discount Approval | PUT | `/api/order_letter_discounts/{{discount_id}}` | Body `{approved, approved_at}` (both nullable — `null` resets, non-null approves). |
| Delete Order Letter Discount | DELETE | `/api/order_letter_discounts/{{discount_id}}` | — |

## 07. Approvals

| Request | Method | Path | Notes |
|---|---|---|---|
| Order Letter Approves | GET | `/api/order_letter_approves` | standard auth |
| Order Letter Approvals | GET | `/api/order_letter_approvals?user_id` | standard auth |
| Order Letter Rejected | GET | `/api/order_letters/{id}/order_letters_rejected?user_id` | |
| Approval Sales (Atasan) | GET | `/api/approval_sales?company_id&area_id` | |
| Create Order Letter Approve | POST | `/api/order_letter_approves` | Body: `{order_letter_id, order_letter_discount_id, leader, job_level_id, location, lokasi_approval}` |

## 08. User & Hierarchy

| Request | Method | Path |
|---|---|---|
| Leader by User | GET | `/api/leaderbyuser?user_id` |
| Team Hierarchy | GET | `/api/team_hierarchy?user_id` |
| Contact Work Experiences | GET | `/api/contact_work_experiences?user_id` |

## 09. Device & Ops

| Request | Method | Path | Notes |
|---|---|---|---|
| Device Tokens | GET | `/api/device_tokens?user_id` | standard auth |
| Register Device Token | POST | `/api/device_tokens` | Body: `{user_id, token, app_name: "Alita Pricelist"}` — FCM registration. |
| Cron Fix Approver Names | GET | `http://localhost/api/cron/fix-approver-names` | Header `Authorization: Bearer {{cron_secret}}`. Internal ops endpoint, not app-facing. |

## 10. Region (External — emsifa.com, no auth)

| Request | Method | Path |
|---|---|---|
| Provinces | GET | `https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json` |
| Regencies by Province | GET | `.../regencies/{{province_id}}.json` |
| Districts by Regency | GET | `.../districts/{{regency_id}}.json` |

Matches `.env`'s `REGION_API_BASE_URL` (deferred).

## 11–14. Brand Specs (External — Comforta / Spring Air / Therapedic / iSleep)

Each brand has its own host + credentials, one endpoint each:

```
GET https://{{brand}_host}/api/types_with_features?access_token={{brand}_access_token}&client_id={{brand}_client_id}&client_secret={{brand}_client_secret}
```

Matches `.env`'s `COMFORTA_*`/`SPRINGAIR_*`/`THERAPEDIC_*`/`ISLEEP_*` keys (all deferred — not yet
needed until a step that surfaces brand spec sheets).

## Open items to resolve before the steps that need them

- **Sign Out** (`DELETE /sign_out`) — contract known, not implemented in the auth module yet.
- **Store Discounts** — collection shows no access_token/client_id on this one request; verify
  against the live server before relying on it (could be a stale/simplified example).
- **Create Order Letter Payment** — collection has an empty `formdata` body; likely a file upload
  (receipt/proof of payment) — needs a live call or backend docs to confirm field names.
- **Indirect Store** host/credentials (`103.165.210.58`, `x-api-key`/`x-client-key`) — separate
  from the main Alita API entirely; not yet in this project's `.env`.
