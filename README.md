tolong buatkan sesuai dengan yang saya mau.
tolong lakukan perlahan, bertahap, best practice.

cukup berikan saya kode yang perlu di tambah atau di modifikasi, tapi jagan lupa untuk memberitahu saya lokasi kode nya mana yang diubah dan di tambah.

Role: Senior Flutter Developer & System Architect.
Objective: Bantu saya membangun aplikasi Android untuk skripsi berjudul "Implementasi Aplikasi Tabungan Kurban untuk Meningkatkan Konsistensi Menabung Berbasis Android".

1. Tech Stack Requirements:

- Framework: Flutter (Latest Stable).
- Backend & Auth: Firebase (Firestore & Firebase Auth).
- Storage: Supabase Storage (khusus untuk menyimpan file gambar bukti transfer).
- State Management: Bloc (flutter_bloc).
- Code Quality: Strict Typing (Dilarang menggunakan any atau dynamic. Gunakan class model yang kuat untuk setiap entitas data).

2. Project Folder Structure:
   Buatlah project dengan struktur folder yang modular sebagai berikut:

- lib/models/: Data class & factory (from/to JSON).
- lib/services/: Logika koneksi Firebase, Supabase, dan API.
- lib/blocs/: Manajemen state (Events, States, Blocs).
- lib/pages/: UI Screens / Halaman utama aplikasi.
- lib/widgets/: Komponen UI yang reusable.
- lib/utils/: Helper (currency formatter, date formatter, constants).

3. Business Logic & Fitur Utama:

- Role-Based Access: Pisahkan alur navigasi dan hak akses untuk Peserta dan Admin.
- Dashboard Peserta: Tampilkan progres visual tabungan secara real-time.
- Rumus Progres: (CurrentBalance / TargetAmount) \* 100.
- Transaction Flow: Peserta mengunggah bukti transfer ke Supabase Storage -> Ambil Public URL -> Simpan metadata ke Firestore dengan status pending.
- Admin Verification:
  - Approved: Otomatis menambahkan nilai amount transaksi ke current_balance pada koleksi user_savings.
  - Rejected: Admin wajib menyertakan alasan penolakan pada field admin_note.

4. Database Schema (Firestore):

- users: {uid, name, email, role}
- saving_targets: {id, animal_type, target_amount}
- user_savings: {id, user_id, target_id, current_balance, status}
- transactions: {id, user_id, amount, evidence_url, status, admin_note, created_at}

Langkah Pertama:
Tolong buatkan Per Modul / Per Fitur sesuai dengan urutan.
