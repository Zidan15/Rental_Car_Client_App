# Rent.Goa — Provider App Data Contract

**Purpose:** Every Supabase table, column, status value, query, and UI color the **Provider (Owner) App** uses.

**Generated from:** `d:\Github_Repo\Rental_Car_Service_Provider_App` on 2026-02-20

---

## 1. Supabase Tables & Columns

### `profiles`

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ✅ INSERT/UPSERT | ✅ SELECT | Matches `auth.users.id` |
| `full_name` | text | ✅ INSERT/UPSERT | ✅ SELECT | |
| `company` | text | ✅ INSERT/UPSERT | ✅ SELECT | **Provider-only column** |
| `contact_number` | text | ✅ INSERT/UPSERT | ✅ SELECT | |
| `address` | text | ❌ | ❌ | Not used by Provider |
| `dob` | text | ❌ | ❌ | Not used by Provider |
| `role` | text | ❌ | ❌ | Not set by Provider (should be `'provider'`) |

**Provider queries:**
```sql
-- Fetch profile
SELECT * FROM profiles WHERE id = :userId  (maybeSingle)

-- Create profile
INSERT INTO profiles (id, full_name, company, contact_number) VALUES (...)

-- Update profile
UPSERT INTO profiles (id, full_name, company, contact_number)
```

---

### `vehicles`

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ (auto) | ✅ SELECT | Via RPC |
| `owner_id` | uuid (FK) | ✅ INSERT | ✅ FILTER | `auth.uid()` |
| `brand` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `model` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `year` | integer | ✅ INSERT/UPDATE | ✅ SELECT | |
| `fuel_type` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `transmission` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `category` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `color` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `plate_number` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `image_url` | text | ✅ INSERT/UPDATE | ✅ SELECT | |
| `price_per_day` | numeric | ✅ INSERT/UPDATE | ✅ SELECT | |
| `is_listed` | boolean | ✅ UPDATE | ✅ SELECT | Toggle publish/unpublish |
| `location_id` | uuid (FK) | ✅ INSERT/UPDATE | ✅ SELECT | References `provider_locations.id` |
| `created_at` | timestamp | ❌ (auto) | ✅ SELECT | Via RPC |

**Provider queries:**
```sql
-- Fetch vehicles (via RPC with sensor data)
SELECT * FROM get_vehicles_with_latest_reading()

-- Insert vehicle
INSERT INTO vehicles (brand, model, year, fuel_type, transmission, color, plate_number, category, image_url, price_per_day, is_listed, location_id, owner_id)

-- Update vehicle
UPDATE vehicles SET ... WHERE id = :vehicleId

-- Toggle listing
UPDATE vehicles SET is_listed = :bool, price_per_day = :price WHERE id = :vehicleId

-- Delete vehicle
DELETE FROM vehicles WHERE id = :vehicleId

-- Get vehicle IDs for booking lookup
SELECT id FROM vehicles WHERE owner_id = :userId
```

---

### `provider_locations`

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ (auto) | ✅ SELECT | |
| `provider_id` | uuid (FK) | ✅ INSERT | ✅ FILTER | `auth.uid()` |
| `name` | text | ✅ INSERT | ✅ SELECT | |
| `address` | text | ✅ INSERT | ✅ SELECT | |
| `lat` | double | ✅ INSERT | ✅ SELECT | |
| `lng` | double | ✅ INSERT | ✅ SELECT | |

**Provider queries:**
```sql
-- Fetch locations
SELECT * FROM provider_locations WHERE provider_id = :userId ORDER BY name ASC

-- Insert location
INSERT INTO provider_locations (name, address, lat, lng, provider_id)

-- Delete location
DELETE FROM provider_locations WHERE id = :locationId

-- Check vehicle usage
SELECT count(*) FROM vehicles WHERE location_id = :locationId
```

---

### `bookings`

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ | ✅ SELECT | |
| `vehicle_id` | uuid (FK) | ❌ | ✅ FILTER | `.inFilter('vehicle_id', vehicleIds)` |
| `renter_id` | uuid (FK) | ❌ | ✅ SELECT | Used to join `profiles` |
| `start_date` | timestamp | ❌ | ✅ SELECT | |
| `end_date` | timestamp | ❌ | ✅ SELECT | |
| `total_price` | numeric | ❌ | ✅ SELECT | |
| `pickup_location` | text | ❌ | ✅ SELECT | |
| `pickup_lat` | double | ❌ | ✅ SELECT | |
| `pickup_lng` | double | ❌ | ✅ SELECT | |
| `status` | text | ✅ UPDATE only | ✅ SELECT | See status flow below |
| `created_at` | timestamp | ❌ | ✅ SELECT | Used for ordering |

**Provider queries:**
```sql
-- Fetch all bookings for provider's vehicles
SELECT *, vehicles(brand, model, year, plate_number), profiles(full_name, contact_number)
FROM bookings
WHERE vehicle_id IN (:vehicleIds)
ORDER BY created_at DESC

-- Fetch completed bookings for earnings
SELECT *, vehicles(brand, model, year, plate_number), profiles(full_name, contact_number)
FROM bookings
WHERE vehicle_id IN (:vehicleIds) AND status = 'completed'
ORDER BY end_date DESC

-- Update status
UPDATE bookings SET status = :newStatus WHERE id = :bookingId
```

---

### `sensor_data` (Provider-only)

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `vehicle_id` | uuid (FK) | ❌ (IoT) | ✅ SELECT | |
| `alcohol_level` | double | ❌ (IoT) | ✅ SELECT | |
| `engine_temperature` | double | ❌ (IoT) | ✅ SELECT | |
| `speed` | double | ❌ (IoT) | ✅ SELECT | |
| `latitude` | double | ❌ (IoT) | ✅ SELECT | |
| `longitude` | double | ❌ (IoT) | ✅ SELECT | |
| `created_at` | timestamp | ❌ (IoT) | ✅ SELECT | |

**Provider queries:**
```sql
-- Via RPC (get_vehicles_with_latest_reading) for fleet view
-- Direct queries for chart data:
SELECT created_at AS timestamp, alcohol_level AS value FROM sensor_data WHERE vehicle_id = :id ORDER BY created_at DESC LIMIT 50
SELECT created_at AS timestamp, engine_temperature AS value FROM sensor_data WHERE vehicle_id = :id ORDER BY created_at DESC LIMIT 50
SELECT created_at AS timestamp, speed AS value FROM sensor_data WHERE vehicle_id = :id ORDER BY created_at DESC LIMIT 50
```

---

### `alerts` (Provider-only)

| Column | Type | Written by Provider? | Read by Provider? | Notes |
|---|---|---|---|---|
| `id` | uuid (PK) | ❌ (system) | ✅ SELECT | |
| `vehicle_id` | uuid (FK) | ❌ (system) | ✅ SELECT | |
| `alert_type` | text | ❌ (system) | ✅ SELECT | e.g., `'Alcohol Sensor'` |
| `value` | text | ❌ (system) | ✅ SELECT | Parsed to double |
| `status` | text | ❌ (system) | ✅ FILTER | `'new'` / `'acknowledged'` |
| `timestamp` | timestamp | ❌ (system) | ✅ SELECT | |

**Provider queries:**
```sql
-- Count active alerts
SELECT count(*) FROM alerts WHERE status = 'new'

-- Fetch all alerts
SELECT * FROM alerts ORDER BY timestamp DESC

-- Real-time stream
stream(primaryKey: ['id']) on alerts

-- Acknowledge (delete)
DELETE FROM alerts WHERE id = :alertId
```

---

## 2. Supabase Storage

| Bucket | Used by Provider? | Notes |
|---|---|---|
| `license-images` | ❌ | Provider App does not interact with license images |

---

## 3. RPC Functions (Provider-only)

| Function | Used by | Notes |
|---|---|---|
| `get_vehicles_with_latest_reading` | Fleet screen | Joins vehicles + latest sensor_data row |

---

## 4. Status Flows

### Booking Status Flow (Provider's Role)

```
pending  →  approved  →  confirmed  →  completed
   ↓           ↓            ↓
 rejected   cancelled    cancelled
```

| Status | Set by Provider? | Provider Action |
|---|---|---|
| `pending` | ❌ (Client) | Displayed with "Approve" / "Reject" buttons |
| `approved` | ✅ | Provider clicks "Approve" |
| `confirmed` | ❌ (Client) | Displayed, allows "Cancel" / "Complete Trip" |
| `completed` | ✅ | Provider clicks "Complete Trip" |
| `cancelled` | ✅ | Provider clicks "Cancel" |
| `rejected` | ✅ | Provider clicks "Reject" |

### Booking Status Colors (Provider App UI)

#### BookingsScreen (list view)

| Status | Color | Text |
|---|---|---|
| `pending` | Orange (default) | `PENDING` |
| `approved` | Blue | `APPROVED` |
| `confirmed` | Green | `CONFIRMED` |
| `completed` | Grey | `COMPLETED` |
| `rejected` | Red | `REJECTED` |
| `cancelled` | Orange (default) | `CANCELLED` |

#### BookingDetailsScreen (badge)

| Status | Background | Text Color | Label |
|---|---|---|---|
| `pending` | Orange/26 | Orange | `PENDING` |
| `approved` | Blue/26 | Blue | `APPROVED` |
| `confirmed` | Green/26 | Green | `CONFIRMED` |
| `completed` | Grey/26 | Grey | `COMPLETED` |
| `cancelled` | Grey/26 | Grey | `CANCELLED` |
| `rejected` | Red/26 | Red | `REJECTED` |

---

## 5. Auth Metadata

Provider App stores in `auth.users.user_metadata` during signup:

| Key | Value |
|---|---|
| `full_name` | Provider's full name |
| `company` | Company name |
| `contact_number` | Phone number |

> [!WARNING]
> Provider does **NOT** set `role` in user_metadata or profiles table.

---

## 6. Tables NOT Used by Provider App

| Table | Notes |
|---|---|
| `licenses` | Provider does not read or write to this table |
| `valid_dl_records` | Provider does not interact with this lookup table |
