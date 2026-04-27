# 🗑️ Trash Sorter App

Smart waste classification app using Google ML Kit, Firebase, and a Node.js/Express REST API.

---

## 📁 Project Structure

```
trash_sorter/                   ← Flutter app root
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart 
│   ├── models/
│   │   └── scan_result.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── camera_service.dart
│   │   ├── ml_kit_service.dart
│   │   ├── storage_service.dart
│   │   ├── api_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── scanner_screen.dart
│   │   └── history_screen.dart
│   └── widgets/
│       ├── custom_button.dart
│       └── scan_result_card.dart
└── backend/                    ← Node.js API
    ├── src/
    │   ├── index.js
    │   ├── db.js
    │   ├── routes/trash.js
    │   ├── controllers/trashController.js
    │   └── middleware/authMiddleware.js
    ├── schema.sql
    ├── package.json
    └── .env.example
```

---

## 🔥 Firebase Setup (Required)

### Step 1 — Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**, follow the wizard
3. Enable the following services:

| Service | Location in Console |
|---------|-------------------|
| **Authentication** | Build → Authentication → Sign-in method → Email/Password → Enable |
| **Cloud Firestore** | Build → Firestore Database → Create database (choose **test mode** or set rules) |
| **Cloud Messaging** | Already enabled by default |

---

### Step 2 — Connect Flutter to Firebase

Install FlutterFire CLI (if not already):
```bash
dart pub global activate flutterfire_cli
```

Run from the **Flutter project root**:
```bash
flutterfire configure
```

- Select your Firebase project
- Check ✅ **Android**
- This will:
  - Generate `lib/firebase_options.dart` (replaces the placeholder)
  - Place `google-services.json` in `android/app/`

---

### Step 3 — Firestore Security Rules

In Firebase Console → Firestore Database → Rules, set:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scan_images/{userId}/scans/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

> ℹ️ Gambar disimpan sebagai Base64 string di Firestore. Tidak perlu Firebase Storage.

---

## 🖥️ Backend Setup (Node.js + PostgreSQL)

### Step 1 — PostgreSQL

Create the database and run the schema:
```bash
# Create database
psql -U postgres -c "CREATE DATABASE trash_sorter;"

# Run schema
psql -U postgres -d trash_sorter -f backend/schema.sql
```

### Step 2 — Firebase Admin Service Account

1. In Firebase Console → Project Settings → Service Accounts
2. Click **Generate new private key** → Download JSON
3. Save as `backend/serviceAccountKey.json`

> ⚠️ Never commit `serviceAccountKey.json` to Git — add it to `.gitignore`

### Step 3 — Environment Variables

```bash
cd backend
copy .env.example .env
# Edit .env with your PostgreSQL URL
```

### Step 4 — Install & Run

```bash
cd backend
npm install
npm run dev      # development (nodemon)
# or
npm start        # production


## 📱 Flutter Setup

### Update API URL

In `lib/services/api_service.dart`, update `_baseUrl`:
```dart
// For Android emulator (accesses host machine):
static const String _baseUrl = 'http://10.0.2.2:3000';

// For physical device (use your machine's local IP):
static const String _baseUrl = 'http://192.168.1.x:3000';
```

### Install Dependencies & Run

```bash
flutter pub get
flutter run
```

---

## 🌐 API Endpoints

All endpoints require `Authorization: Bearer <Firebase ID Token>` header.

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| `POST` | `/trash` | Save scan result | `{ image_url, detected_label, category }` |
| `GET` | `/trash` | Get all scans for user | — |
| `PUT` | `/trash/:id` | Update a scan | `{ image_url?, detected_label?, category? }` |
| `DELETE` | `/trash/:id` | Delete a scan | — |
| `GET` | `/health` | Health check | — |

### Example — Save Scan
```bash
curl -X POST http://localhost:3000/trash \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image_url":"https://...","detected_label":"Bottle","category":"Anorganik"}'
```

---

## 🏷️ Category Mapping

| ML Kit Labels | Category |
|---------------|----------|
| food, fruit, vegetable, banana, apple, plant, leaf... | **Organik** |
| plastic, bottle, container, can, paper, cardboard, aluminum... | **Anorganik** |
| (everything else) | **Tidak Diketahui** |

---

## 🔔 Firebase Cloud Messaging

- FCM token is retrieved on app start via `NotificationService`
- When a scan is saved, a **local notification** is shown instantly
- Background FCM messages are handled by `firebaseMessagingBackgroundHandler`
- For server-sent push notifications, send to the FCM token using Firebase Admin SDK or Firebase Console

---

## 📦 Dependencies Summary

### Flutter
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.6.0 | Firebase init |
| `firebase_auth` | ^5.3.1 | Authentication |
| `cloud_firestore` | ^5.4.4 | Image storage (Base64) |
| `firebase_messaging` | ^15.1.3 | FCM push notifications |
| `google_mlkit_image_labeling` | ^0.12.0 | On-device ML |
| `image_picker` | ^1.1.2 | Camera/gallery |
| `flutter_local_notifications` | ^17.2.2 | Local notifications |
| `http` | ^1.2.2 | REST API calls |
| `cached_network_image` | ^3.4.1 | Image display |
| `intl` | ^0.19.0 | Date formatting |

### Backend (Node.js)
| Package | Purpose |
|---------|---------|
| `express` | Web framework |
| `pg` | PostgreSQL client |
| `firebase-admin` | Verify Firebase tokens |
| `cors` | Cross-origin requests |
| `dotenv` | Environment config |
| `nodemon` | Dev auto-restart |
