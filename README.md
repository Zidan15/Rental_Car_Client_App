# 🛵 Rent.Goa — Renter Client App

[![Flutter](https://img.shields.io/badge/Flutter-3.41.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Groq AI](https://img.shields.io/badge/Groq%20AI-Qwen%203.6%20Vision-F34B21?style=for-the-badge&logo=openai&logoColor=white)](https://groq.com)
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-On--Device%20OCR-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)

A modern, mobile-first vehicle rental platform designed for tourists and renters in Goa. The application features AI-powered Driver's License verification, camera OCR extraction, real-time vehicle search, location filtering, and seamless booking flows.

---

## 🌟 Key Features

* **🔍 Smart Vehicle Discovery**: Browse scooters and cars on an interactive map or list view, complete with price filtering, car types, transmission, and distance calculation.
* **🤖 Dual-Engine License Verification (Vision AI + On-Device OCR)**:
  * **Primary Cloud AI**: Uses Groq's `qwen/qwen3.6-27b` multimodal Vision model for intelligent document extraction (DL Number, Name, DOB, Address, Expiry).
  * **On-Device ML Kit Fallback**: Automatic, zero-latency offline extraction using Google ML Kit and spatial bounding box text parsing (`SmartDLParser`).
* **📸 Guided Damage & Inspection Photo Capture**: AR-guided camera overlay for pre-trip and post-trip photo inspection.
* **💳 Instant Booking & UPI Payment**: Seamless checkout flow with instant dynamic UPI QR code generation (`qr_flutter`).

---

## 🛠️ Technology Stack

* **Framework**: Flutter (Dart)
* **Backend & Auth**: Supabase (PostgreSQL, Auth, Storage)
* **Vision AI OCR**: Groq API (`qwen/qwen3.6-27b` multimodal vision model)
* **On-Device OCR**: Google ML Kit Text Recognition (`google_mlkit_text_recognition`)
* **Maps & Distance**: `flutter_map`, `latlong2`
* **QR Code Generation**: `qr_flutter`

---

## 📁 Project Structure

```text
lib/
├── models/         # Listing, Booking, UserProfile data models
├── screens/        # RecommendedCars, LicenseVerification, BookingSummary, Payment screens
├── services/       # OCRService, CloudOCRService, SmartDLParser, ListingService, UserService
└── main.dart       # Application entry point & Supabase client setup
```

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.11.0`)
* Android Studio / Xcode for emulators or physical device deployment

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Zidan15/Rental_Car_Client_App.git
   cd Rental_Car_Client_App
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the project root:
   ```env
   GROQ_API_KEY=your-groq-api-key
   SUPABASE_URL=https://your-supabase-url.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 📄 Author

Developed by **[Zidan Shaikh](https://github.com/Zidan15)** as part of the **Rent.Goa** Smart Vehicle Rental Platform.
