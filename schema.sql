-- Rent.Goa PostgreSQL Database Schema for Supabase
-- Created for Rent.Goa Smart Vehicle Rental Platform

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL,
  full_name text,
  company text,
  contact_number text,
  role text DEFAULT 'provider'::text,
  address text,
  dob text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 2. Provider Locations Table
CREATE TABLE IF NOT EXISTS public.provider_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL DEFAULT auth.uid(),
  name text NOT NULL,
  address text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT provider_locations_pkey PRIMARY KEY (id),
  CONSTRAINT provider_locations_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- 3. Vehicles Table
CREATE TABLE IF NOT EXISTS public.vehicles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  brand text,
  model text,
  year integer,
  fuel_type text,
  transmission text,
  color text,
  plate_number text NOT NULL UNIQUE,
  image_url text,
  category text,
  price_per_day numeric DEFAULT 0,
  is_listed boolean DEFAULT false,
  location_id uuid,
  CONSTRAINT vehicles_pkey PRIMARY KEY (id),
  CONSTRAINT vehicles_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT vehicles_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.provider_locations(id) ON DELETE SET NULL
);

-- 4. Sensor Data Table (IoT Telemetry)
CREATE TABLE IF NOT EXISTS public.sensor_data (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  vehicle_id uuid NOT NULL,
  alcohol_level text,
  fuel_level numeric,
  speed numeric,
  engine_temperature numeric,
  latitude numeric,
  longitude numeric,
  CONSTRAINT sensor_data_pkey PRIMARY KEY (id),
  CONSTRAINT sensor_data_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE
);

-- 5. Alerts Table (IoT Security Alerts)
CREATE TABLE IF NOT EXISTS public.alerts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  alert_type text,
  value text,
  timestamp timestamp with time zone NOT NULL DEFAULT now(),
  status text DEFAULT 'new'::text,
  CONSTRAINT alerts_pkey PRIMARY KEY (id),
  CONSTRAINT alerts_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE
);

-- 6. Bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  renter_id uuid NOT NULL,
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone NOT NULL,
  total_price numeric,
  status text DEFAULT 'confirmed'::text,
  created_at timestamp with time zone DEFAULT now(),
  pickup_location text,
  pickup_lat double precision,
  pickup_lng double precision,
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE,
  CONSTRAINT bookings_renter_id_fkey FOREIGN KEY (renter_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- 7. Video Clips Table (Dashcam Video Storage)
CREATE TABLE IF NOT EXISTS public.video_clips (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  camera_type text NOT NULL,
  file_path text NOT NULL UNIQUE,
  CONSTRAINT video_clips_pkey PRIMARY KEY (id),
  CONSTRAINT video_clips_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE
);

-- 8. Driver Licenses Table (KYC Document Storage)
CREATE TABLE IF NOT EXISTS public.licenses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  license_number text NOT NULL,
  front_photo_url text,
  back_photo_url text,
  verification_status text NOT NULL DEFAULT 'pending'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  holder_name text,
  father_name text,
  date_of_birth date,
  blood_group text,
  address text,
  valid_till date,
  vehicle_classes text[],
  issue_date date,
  CONSTRAINT licenses_pkey PRIMARY KEY (id),
  CONSTRAINT licenses_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 9. Valid DL Records Table (RTO Verification Cache)
CREATE TABLE IF NOT EXISTS public.valid_dl_records (
  dl_number text NOT NULL,
  holder_name text NOT NULL,
  father_name text,
  date_of_birth date NOT NULL,
  valid_till date NOT NULL,
  status text DEFAULT 'active'::text,
  rto_code text,
  CONSTRAINT valid_dl_records_pkey PRIMARY KEY (dl_number)
);
