# Volunteer Spot Finder (VSF)

Volunteer Spot Finder (VSF) adalah platform pencarian dan manajemen kegiatan sukarelawan (volunteering). Sistem ini dirancang untuk mempertemukan organisasi penyelenggara kegiatan dengan para relawan yang ingin berpartisipasi secara aktif dalam berbagai program sosial, lingkungan, dan kemanusiaan.

Proyek ini terbagi menjadi dua bagian utama:
1. Frontend: Aplikasi mobile berbasis Flutter untuk pengguna (relawan dan organisasi).
2. Backend: RESTful API server berbasis Node.js, Express, dan PostgreSQL untuk melayani manajemen data.

---

## Fitur Utama

### Pengguna (Relawan & Organisasi)
- Registrasi dan autentikasi dengan enkripsi kata sandi.
- Profil pengguna yang dipersonalisasi berdasarkan tipe akun (Relawan Individu atau Organisasi).
- Statistik kontribusi pengguna.

### Kegiatan Sukarelawan (Events)
- Pembuatan dan pengelolaan acara sukarelawan oleh pihak organisasi.
- Pencarian dan filter kegiatan berdasarkan judul, kategori, dan lokasi.
- Peta interaktif terintegrasi untuk menampilkan lokasi spesifik kegiatan.
- Batasan jumlah relawan dan pelacakan partisipasi secara langsung.

### Artikel & Edukasi
- Daftar artikel edukatif dan informatif terkait kegiatan sosial.
- Peningkatan jumlah pembaca (views tracking) untuk setiap artikel.
- Kategori artikel untuk memudahkan navigasi.

### Keamanan & Notifikasi
- Izin lokasi yang aman dan dinamis.
- Layanan notifikasi lokal untuk mengingatkan jadwal kegiatan.
- Keamanan kata sandi berbasis hashing SHA-256.

---

## Teknologi yang Digunakan

### Frontend (Mobile App)
- Framework Utama: Flutter (Dart SDK >=3.0.0 <4.0.0)
- Manajemen State: Provider
- Database Lokal: Hive (NoSQL) & Shared Preferences
- Peta & Lokasi: Google Maps Flutter, Flutter Map, Geolocator, Geocoding
- Notifikasi: Flutter Local Notifications
- Utilitas & Gaya: Cupertino Icons, Timezone, Intl, HTTP Client

### Backend (REST API)
- Runtime Environment: Node.js
- Framework Web: Express.js (v5.1.0)
- Database: PostgreSQL
- Konektor Database: pg (node-postgres)
- ORM: Prisma ORM (siap dikonfigurasi dengan PostgreSQL)
- Utilitas: Dotenv (konfigurasi variabel lingkungan), CORS, Nodemon (alat bantu pengembangan)

---

## Struktur Direktori Proyek

```text
vsf/
├── android/             # Konfigurasi platform Android
├── ios/                 # Konfigurasi platform iOS
├── lib/                 # Kode sumber utama Flutter (Dart)
│   ├── models/          # Model data (User, Event, Article, dll.)
│   ├── pages/           # Halaman UI aplikasi (Auth, Home, Activity, dll.)
│   ├── services/        # Layanan aplikasi (Notifikasi, Sesi)
│   ├── utils/           # Fungsi utilitas pembantu
│   └── widgets/         # Komponen UI reusable
├── pubspec.yaml         # Dependensi dan metadata Flutter
└── vsf-backend/         # Kode sumber backend (Node.js)
    ├── prisma/          # Skema database Prisma
    ├── db.js            # Koneksi pool PostgreSQL
    ├── server.js        # Entry point server Express dan definisi route API
    └── package.json     # Dependensi backend Node.js
```

---

## Petunjuk Instalasi dan Penggunaan

### Persyaratan Sistem
- Flutter SDK (versi terbaru yang mendukung Dart SDK 3.x)
- Node.js (versi 16 atau lebih baru)
- PostgreSQL (database server aktif)

### Langkah 1: Konfigurasi dan Menjalankan Backend

1. Buka direktori backend:
   ```bash
   cd vsf-backend
   ```

2. Instal dependensi Node.js:
   ```bash
   npm install
   ```

3. Buat file `.env` di dalam folder `vsf-backend` dan sesuaikan variabel konfigurasi berikut:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=username_postgres_anda
   DB_PASSWORD=password_postgres_anda
   DB_NAME=nama_database_anda
   DATABASE_URL="postgresql://username:password@localhost:5432/nama_database?schema=public"
   ```

4. Jalankan migrasi database atau pastikan tabel database PostgreSQL Anda sudah terstruktur.

5. Jalankan server backend dalam mode pengembangan:
   ```bash
   npm run dev
   ```
   Server akan aktif di http://localhost:3000.

### Langkah 2: Konfigurasi dan Menjalankan Frontend (Flutter)

1. Kembali ke direktori utama proyek (vsf).

2. Instal semua paket dependensi Flutter:
   ```bash
   flutter pub get
   ```

3. Generate adapter untuk database Hive:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Jalankan aplikasi pada emulator atau perangkat fisik Anda:
   ```bash
   flutter run
   ```

---

## Lisensi
Proyek ini dikembangkan secara internal untuk kebutuhan Volunteer Spot Finder. Seluruh hak cipta dilindungi.
