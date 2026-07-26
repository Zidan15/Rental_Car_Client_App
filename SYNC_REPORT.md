# Rent.Goa — Client ↔ Provider Sync Report

**Generated:** 2026-02-20
**Source:** [Client DATA_CONTRACT.md](file:///d:/Github_Repo/Rental_Car_Service_Provider_App/DATA_CONTRACT.md) vs [Provider DATA_CONTRACT.md](file:///C:/Users/User/.gemini/antigravity/brain/3de9a096-d16e-442f-902f-9549f62d47fb/PROVIDER_DATA_CONTRACT.md)

---

## ✅ Things That Match

| Area | Detail |
|---|---|
| **`vehicles` table** | Both apps use exact same column names: `id`, `owner_id`, `brand`, `model`, `year`, `fuel_type`, `transmission`, `category`, `color`, `plate_number`, `image_url`, `price_per_day`, `is_listed`, `created_at` |
| **`bookings` table** | Both apps use exact same column names: `id`, `vehicle_id`, `renter_id`, `start_date`, `end_date`, `total_price`, `pickup_location`, `pickup_lat`, `pickup_lng`, `status`, `created_at` |
| **`provider_locations` table** | Both apps use same columns: `lat`, `lng`, `name`. Client reads via join, Provider writes directly |
| **`profiles` shared columns** | `id`, `full_name`, `contact_number` — used by both apps |
| **Booking status flow** | `pending → approved → confirmed → completed` is consistent. `cancelled` is supported by both |
| **Status ownership** | `pending` = Client, `approved` = Provider, `confirmed` = Client, `completed` = Provider, `cancelled` = both ✅ |
| **Lowercase statuses** | Both apps use lowercase: `'pending'`, `'approved'`, `'confirmed'`, `'completed'`, `'cancelled'` ✅ |
| **Bookings join → profiles** | Both join `profiles(full_name, contact_number)` on `renter_id` |
| **Status: pending** | Both: Orange |
| **Status: approved** | Client: Blue, Provider: Blue ✅ |
| **Status: confirmed** | Client: Green, Provider: Green ✅ |
| **Status: completed** | Client: Grey, Provider: Grey ✅ |

---

## ❌ Mismatches

### 1. `cancelled` Status Color

| App | Color | Label |
|---|---|---|
| **Client** | 🔴 Red | `CANCELLED` |
| **Provider (list view)** | 🟠 Orange (falls into `default`) | `CANCELLED` |
| **Provider (detail badge)** | ⚪ Grey | `CANCELLED` |

> [!WARNING]
> The Provider `BookingsScreen` doesn't have an explicit `case 'cancelled'` — it falls through to `default: Colors.orange`. The detail badge uses Grey. Neither matches the Client's Red.

**Fix:** Add explicit `case 'cancelled': statusColor = Colors.red;` to `BookingsScreen` and update the detail badge to Red.

---

### 2. Bookings Join — `year` Column

| App | Join Query |
|---|---|
| **Client** | `vehicles(brand, model, year)` |
| **Provider** | `vehicles(brand, model, year, plate_number)` |

The Provider fetches `plate_number` in addition (which is fine), but the Client uses `year` in display while the Provider **strips year from display** (`displayName = '$brand $model'`). **Not a data problem**, just a UI difference by design.

---

### 3. `profiles` Table — Column Mismatch

| Column | Client App | Provider App |
|---|---|---|
| `full_name` | ✅ Read/Write | ✅ Read/Write |
| `contact_number` | ✅ Read/Write | ✅ Read/Write |
| `address` | ✅ Read/Write | ❌ Not used |
| `dob` | ✅ Read/Write | ❌ Not used |
| `role` | ✅ Set to `'renter'` | ❌ **Not set at all** |
| `company` | ❌ Not used | ✅ Read/Write |

> [!IMPORTANT]
> The Provider App does **not set `role`** during signup. If the system needs to distinguish renters from providers via the `role` column, this is a gap. The Provider should set `role = 'provider'` on profile creation.

---

### 4. `rejected` Status — Client App Missing?

| Status | Client App | Provider App |
|---|---|---|
| `rejected` | Not in status flow diagram | ✅ Provider can reject bookings |

The Client App's DATA_CONTRACT does not list `rejected` as a status or color. The Provider App can set bookings to `rejected`. The Client should handle this status in its UI.

---

## ⚠️ Things Only One App Uses

### Provider-Only

| Item | Type | Notes |
|---|---|---|
| `sensor_data` table | Table | IoT sensor readings (alcohol, temp, speed, location) |
| `alerts` table | Table | System-generated alerts for sensor thresholds |
| `company` column | `profiles` column | Provider's business name |
| `location_id` column | `vehicles` column | FK to `provider_locations` |
| `get_vehicles_with_latest_reading` | RPC function | Joins vehicles with latest sensor data |
| `rejected` status | Booking status | Provider rejects bookings; Client might not display this |

### Client-Only

| Item | Type | Notes |
|---|---|---|
| `licenses` table | Table | Renter driver license data |
| `valid_dl_records` table | Table | Government DL verification lookup |
| `license-images` bucket | Storage | License photo uploads |
| `address` column | `profiles` column | Renter's address |
| `dob` column | `profiles` column | Renter's date of birth |
| `role` column | `profiles` column | Set to `'renter'` by Client |

---

## 📋 Action Items

| Priority | Action | Affected File |
|---|---|---|
| 🔴 High | Set `role = 'provider'` during Provider signup | `user_service.dart` |
| 🔴 High | Add explicit `case 'cancelled'` with Red color in `BookingsScreen` | `bookings_screen.dart` |
| 🟡 Medium | Update `cancelled` badge color to Red in `BookingDetailsScreen` | `booking_details_screen.dart` |
| 🟡 Medium | Ensure Client App handles `rejected` status in its UI | Client App (separate repo) |
| 🟢 Low | Consider reading `licenses` table in Provider App (Phase 2 feature) | Future |
