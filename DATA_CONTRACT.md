# Rent.Goa — Client App Data Contract

**Purpose:** This document lists every Supabase table, column, status value, and API call the **Client (Renter) App** uses. The Provider App agent should cross-check this against its own codebase to find mismatches.

**Generated from:** `d:\Github_Repo\Rental_Car_Client_App` on 2026-02-20

---

## 1. Supabase Tables & Columns

### `profiles`

| Column | Type | Written by Client? | Read by Client? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ✅ INSERT | ✅ SELECT | Matches `auth.users.id` |
| `full_name` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `contact_number` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `address` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `dob` | text (ISO date) | ✅ INSERT/UPDATE | ✅ SELECT | Stored as ISO string, not date type |
| `role` | text | ✅ INSERT (`'renter'`) | ❌ | Always set to `'renter'` by Client App |

---

### `vehicles`

| Column | Type | Written by Client? | Read by Client? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ | ✅ SELECT | Used as `vehicle_id` in bookings |
| `owner_id` | uuid (FK) | ❌ | ✅ (via join) | |
| `brand` | text | ❌ | ✅ SELECT | |
| `model` | text | ❌ | ✅ SELECT | |
| `year` | integer | ❌ | ✅ SELECT | |
| `fuel_type` | text | ❌ | ✅ SELECT | |
| `transmission` | text | ❌ | ✅ SELECT | |
| `category` | text | ❌ | ✅ SELECT | |
| `color` | text | ❌ | ✅ SELECT | |
| `plate_number` | text | ❌ | ✅ SELECT | |
| `image_url` | text | ❌ | ✅ SELECT | |
| `price_per_day` | numeric | ❌ | ✅ SELECT | Used for price calculation |
| `is_listed` | boolean | ❌ | ✅ FILTER | `.eq('is_listed', true)` |
| `created_at` | timestamp | ❌ | ✅ SELECT | |

**Client query:**
```sql
SELECT *, provider_locations(lat, lng, name) 
FROM vehicles 
WHERE is_listed = true
```

---

### `provider_locations` (joined via FK from vehicles)

| Column | Type | Read by Client? | Notes |
|---|---|---|---|
| `lat` | double | ✅ (join) | Vehicle location latitude |
| `lng` | double | ✅ (join) | Vehicle location longitude |
| `name` | text | ✅ (join) | Location display name |

---

### `bookings`

| Column | Type | Written by Client? | Read by Client? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ (auto) | ✅ SELECT | |
| `vehicle_id` | uuid (FK) | ✅ INSERT | ✅ SELECT | References `vehicles.id` |
| `renter_id` | uuid (FK) | ✅ INSERT | ✅ FILTER | `auth.uid()` — `.eq('renter_id', userId)` |
| `start_date` | timestamp | ✅ INSERT | ✅ SELECT | ISO 8601 string |
| `end_date` | timestamp | ✅ INSERT | ✅ SELECT | ISO 8601 string |
| `total_price` | numeric | ✅ INSERT | ✅ SELECT | |
| `pickup_location` | text | ✅ INSERT | ✅ SELECT | |
| `pickup_lat` | double | ✅ INSERT | ✅ SELECT | Nullable |
| `pickup_lng` | double | ✅ INSERT | ✅ SELECT | Nullable |
| `status` | text | ✅ INSERT/UPDATE | ✅ SELECT | See status flow below |
| `created_at` | timestamp | ❌ (auto) | ✅ SELECT | Used for ordering |

**Client queries:**
```sql
-- Fetch user's bookings (with vehicle join)
SELECT *, vehicles(brand, model, year)
FROM bookings
WHERE renter_id = :userId
ORDER BY created_at DESC

-- Fetch single booking
SELECT *, vehicles(brand, model, year)
FROM bookings
WHERE id = :bookingId

-- Create booking
INSERT INTO bookings (vehicle_id, renter_id, start_date, end_date, total_price, pickup_location, pickup_lat, pickup_lng, status)
VALUES (:vehicleId, :userId, :startDate, :endDate, :totalPrice, :location, :lat, :lng, 'pending')

-- Update status (cancel or confirm)
UPDATE bookings SET status = :newStatus WHERE id = :bookingId
```

---

### `licenses`

| Column | Type | Written by Client? | Read by Client? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ (auto) | ✅ SELECT | |
| `user_id` | uuid (FK) | ✅ INSERT | ✅ FILTER | `.eq('user_id', userId)` |
| `license_number` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `front_photo_url` | text | ✅ INSERT/UPDATE | ✅ SELECT | URL from storage |
| `back_photo_url` | text | ✅ INSERT/UPDATE | ✅ SELECT | URL from storage |
| `holder_name` | text | ✅ INSERT/UPDATE | ✅ SELECT | OCR extracted |
| `father_name` | text | ✅ INSERT/UPDATE | ✅ SELECT | OCR extracted |
| `date_of_birth` | text (date) | ✅ INSERT/UPDATE | ✅ SELECT | |
| `blood_group` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `address` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `valid_till` | text (date) | ✅ INSERT/UPDATE | ✅ SELECT | |
| `vehicle_classes` | jsonb/text[] | ✅ INSERT/UPDATE | ✅ SELECT | Array of strings |
| `issue_date` | text (date) | ✅ INSERT/UPDATE | ✅ SELECT | |
| `verification_status` | text | ✅ INSERT/UPDATE | ✅ SELECT | See status flow below |
| `created_at` | timestamp | ❌ (auto) | ✅ SELECT | |
| `updated_at` | timestamp | ✅ UPDATE | ✅ SELECT | Manually set on update |

---

### `valid_dl_records` (lookup table)

| Column | Type | Read by Client? | Notes |
|---|---|---|---|
| `dl_number` | text | ✅ FILTER | `.eq('dl_number', licenseNumber)` — uppercased, spaces removed |
| `status` | text | ✅ SELECT | Expected: `'active'` or other |
| `valid_till` | text (date) | ✅ SELECT | Compared against `DateTime.now()` |

---

## 2. Supabase Storage

| Bucket | Used by Client? | Notes |
|---|---|---|
| `license-images` | ✅ UPLOAD + GET URL | File format: `{userId}_{type}_{timestamp}.jpg` |

---

## 3. Status Flows

### Booking Status Flow

```
pending  →  approved  →  confirmed  →  completed
   ↓           ↓            ↓
cancelled  cancelled    cancelled
```

| Status | Set by | Meaning |
|---|---|---|
| `pending` | Client App (on create) | Renter submitted booking request |
| `approved` | **Provider App** | Owner approved the request |
| `confirmed` | Client App (after payment) | Renter confirmed & paid |
| `completed` | **Provider App** | Trip finished |
| `cancelled` | Client App OR Provider App | Booking cancelled |

### Booking Status Colors (Client App UI)

| Status | Color | Text Color | Display Text |
|---|---|---|---|
| `pending` | Orange | White | `PENDING` |
| `approved` | Blue | White | `PAY NOW` ← special label! |
| `confirmed` | Green | White | `CONFIRMED` |
| `completed` | Grey | Black | `COMPLETED` |
| `cancelled` | Red | White | `CANCELLED` |

### License Verification Status Flow

```
pending  →  verified
   ↓
rejected
```

| Status | Set by | Meaning |
|---|---|---|
| `pending` | Client App (on submit) | License submitted for review |
| `verified` | **Provider App** or auto-verify | License confirmed valid |
| `rejected` | **Provider App** | License rejected |

### License Status Colors (Client App UI)

| Status | Color | Icon |
|---|---|---|
| `pending` | Orange | `Icons.pending` |
| `verified` | Green | `Icons.check_circle` |
| `rejected` | Red | `Icons.cancel` |

---

## 4. Cancellation Rules

The Client App allows cancellation when booking status is one of: `pending`, `approved`, `confirmed`.

The cancel button triggers:
```dart
await _bookingService.updateBookingStatus(bookingId, 'cancelled');
```

**Provider App must also support this status transition.**

---

## 5. Payment Flow

When status = `approved`, the Client App shows a **"Pay Now"** button that navigates to `PaymentScreen`.

On payment confirmation:
```dart
await _bookingService.updateBookingStatus(bookingId, 'confirmed');
```

Payment methods supported: **Pay at Pickup** (default) and **UPI QR code** (demo).

---

## 6. Auth Metadata

The Client App stores these fields in `auth.users.user_metadata` during signup:

| Key | Value |
|---|---|
| `full_name` | User's full name |
| `contact_number` | Phone number |
| `address` | Address |
| `dob` | ISO date string |
| `role` | Always `'renter'` |

---

## Sync Checklist for Provider App Agent

- [ ] Does Provider App use the **exact same column names** for all tables?
- [ ] Does Provider read `renter_id` from bookings to identify the renter?
- [ ] Does Provider set status to lowercase `'approved'` (not `'Approved'`)?
- [ ] Does Provider set status to `'completed'` when trip ends?
- [ ] Does Provider join `vehicles(brand, model, year)` the same way?
- [ ] Does Provider read from `licenses` table with same column names?
- [ ] Does Provider update `verification_status` to `'verified'` or `'rejected'`?
- [ ] Does Provider handle `'cancelled'` status (set by Client App)?
- [ ] Does Provider read `pickup_location`, `pickup_lat`, `pickup_lng` from bookings?
- [ ] Are status colors consistent between both apps?
