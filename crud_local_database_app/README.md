# crud_local_database_app

Project ini adalah aplikasi Flutter untuk CRUD catatan dengan database lokal `Isar`.
Setiap catatan memiliki:

- teks catatan
- foto dari kamera

## Fitur

- tambah catatan
- lihat daftar catatan
- ubah teks catatan
- hapus catatan
- simpan data secara lokal menggunakan Isar

## Prasyarat

Sebelum menjalankan project, pastikan hal berikut sudah tersedia:

- Flutter SDK terpasang
- Android Studio terpasang
- Android SDK dan emulator sudah siap
- minimal ada 1 device Android aktif, bisa berupa:
  - emulator Android
  - HP Android dengan USB debugging aktif

## Dependency Utama

Project ini menggunakan package berikut:

- `isar`
- `isar_flutter_libs`
- `provider`
- `path_provider`
- `image_picker`

## Langkah Menjalankan Project

Jalankan semua perintah dari folder root project ini.

### 1. Ambil dependency

```powershell
flutter pub get
```

### 2. Generate file Isar jika diperlukan

File generator saat ini sudah ada di repo, yaitu `lib/models/note.g.dart`.
Kalau nanti model berubah atau file generator hilang, jalankan:

```powershell
dart run build_runner build
```

Kalau ada konflik hasil generator, gunakan:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 3. Jalankan emulator atau hubungkan device Android

Cek emulator yang tersedia:

```powershell
flutter emulators
```

Contoh menyalakan emulator:

```powershell
flutter emulators --launch Medium_Phone_API_36.1
```

Lalu cek apakah device sudah terbaca:

```powershell
flutter devices
```

### 4. Jalankan aplikasi

Kalau device Android sudah aktif, jalankan:

```powershell
flutter run
```

Kalau ada lebih dari satu device, pilih salah satu:

```powershell
flutter run -d <device_id>
```

## Contoh Alur Menjalankan

Urutan paling umum:

```powershell
flutter pub get
flutter emulators --launch Medium_Phone_API_36.1
flutter devices
flutter run
```

## Cara Menggunakan Aplikasi

Setelah aplikasi terbuka:

1. tekan tombol `+`
2. isi teks catatan
3. tekan `Take Photo` untuk membuka kamera
4. tekan `Create` untuk menyimpan
5. gunakan ikon edit untuk mengubah teks
6. gunakan ikon hapus untuk menghapus catatan

## Struktur File Penting

- `lib/main.dart` -> entry point aplikasi
- `lib/pages/notes_page.dart` -> halaman utama catatan
- `lib/models/note.dart` -> model data catatan
- `lib/models/note_database.dart` -> operasi database Isar

## Troubleshooting

### `flutter` tidak dikenali

Pastikan folder `flutter/bin` sudah masuk ke PATH, atau jalankan Flutter dengan path lengkap.

### Device tidak muncul di `flutter devices`

- pastikan emulator sudah benar-benar boot
- kalau memakai HP, aktifkan USB debugging
- cek Android SDK dan lisensi dengan:

```powershell
flutter doctor -v
```

### Emulator status `offline`

Tunggu proses boot emulator sampai selesai, lalu jalankan lagi:

```powershell
flutter devices
```

Kalau masih bermasalah, tutup emulator lalu nyalakan ulang dari Android Studio atau dengan:

```powershell
flutter emulators --launch Medium_Phone_API_36.1
```

### Build gagal setelah ubah model Isar

Generate ulang file Isar:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Catatan

- Project ini paling cocok dijalankan di Android karena fitur ambil foto memakai kamera.
- Menjalankan di web tidak direkomendasikan karena kode memakai `dart:io`.
