## IMPLEMENTATION PLAN

Aplikasi Kasir & Manajemen Kas Offline Berbasis Flutter

Platform: Android dan iOS

Arsitektur: Offline-first, single-business, single-device

Database: SQLite + Drift

State management: Riverpod

Keamanan: PIN dan biometrik jika didukung perangkat

Output: Dokumen spesifikasi teknis dan backlog implementasi

## DAFTAR ISI

- 1. Ringkasan proyek

- 2. Tujuan dan ruang lingkup

- 3. Arsitektur teknis

- 4. Struktur folder proyek

- 5. Spesifikasi database

- 6. Spesifikasi fitur aplikasi

- 7. Aturan bisnis dan konsistensi data

- 8. Sistem backup, import, dan export

- 9. Keamanan aplikasi

- 10. Struk digital dan printer Bluetooth

- 11. Roadmap implementasi

- 12. Backlog coding

- 13. Strategi pengujian

- 14. Kriteria penerimaan MVP

- 15. Risiko dan mitigasi

- 16. Definisi selesai dan rencana rilis

## 1. RINGKASAN PROYEK

Aplikasi merupakan sistem kasir dan manajemen kas yang berjalan pada Android dan iOS menggunakan Flutter.

Seluruh data bisnis disimpan secara lokal di perangkat menggunakan SQLite. Aplikasi tetap berfungsi tanpa internet dan tidak memerlukan server untuk operasional sehari-hari.


Pengguna dapat mengelola produk, melakukan transaksi penjualan, mencatat kas masuk dan keluar,

mengontrol stok, melihat laporan, mencetak struk, serta melakukan backup dan pemulihan data.

- 1.1 Keputusan utama

- Satu usaha menggunakan satu perangkat aktif.

- Tidak ada server wajib, akun online, atau sinkronisasi cloud.

- Database lokal merupakan sumber data utama.

- Backup lengkap menggunakan JSON dengan versi format.

- CSV digunakan untuk pertukaran data dan analisis spreadsheet.

- PDF digunakan untuk laporan dan struk.

- Printer Bluetooth didukung melalui lapisan adapter printer.

- PIN wajib dapat digunakan sebagai mekanisme akses aplikasi; biometrik bersifat opsional.

- Semua transaksi keuangan dan perubahan stok harus konsisten dan dapat ditelusuri.

## 1.2 Target MVP

Versi pertama harus memungkinkan pengguna menjalankan operasional dasar usaha tanpa internet, mulai dari mengelola produk hingga membuat laporan dan memulihkan backup.

## 2. TUJUAN DAN RUANG LINGKUP

## 2.1 Fitur yang termasuk MVP

- 1. Profil dan pengaturan usaha.

- 2. Produk dan kategori.

- 3. Harga jual, harga modal, dan stok.

- 4. Keranjang dan transaksi kasir.

- 5. Metode pembayaran tunai, transfer, QRIS, dan pembayaran campuran.

- 6. Riwayat transaksi dan pembatalan yang tercatat.

- 7. Kas masuk dan kas keluar.

- 8. Buka dan tutup kas harian.

- 9. Dashboard dan laporan.

- 10. Struk digital, PDF, dan printer Bluetooth yang kompatibel.

- 11. PIN dan autentikasi biometrik opsional.

- 12. Backup JSON dan restore.

- 13. Ekspor CSV dan PDF.


- 14. Pengaturan serta migrasi database.

- 15. Pengujian Android dan iOS.

## 2.2 Fitur yang ditunda

- Sinkronisasi cloud otomatis.

- Multi-cabang dan multi-perangkat.

- Pengguna online dengan hak akses terpusat.

- Integrasi akuntansi eksternal.

- Akuntansi double-entry lengkap.

- Integrasi pembayaran otomatis dengan penyedia layanan.

- Manajemen gudang kompleks.

## 2.3 Fleksibilitas jenis usaha

Model produk perlu mendukung usaha retail, warung makan, kedai, jasa, dan usaha umum.

Setiap produk memiliki pengaturan apakah produk tersebut mengurangi stok ketika dijual. Produk jasa dapat menggunakan stok nonaktif.

Pajak, diskon, kategori, satuan, dan metode pembayaran harus dapat dikonfigurasi sesuai kebutuhan usaha.

## 3. ARSITEKTUR TEKNIS

## 3.1 Stack teknologi

Komponen

Framework

Database

ORM dan query

State management

Routing

Identitas record

Pemilih file

Berbagi file

Pembuatan PDF

Printer

Pilihan

Flutter dan Dart

SQLite

Drift

Riverpod

go_router

UUID

File picker

Share Plus atau API platform setara

Paket PDF Flutter

Adapter ESC/POS Bluetooth


## Komponen Pilihan

PIN dan penyimpanan rahasia Hash PIN yang aman dan Secure Storage jika diperlukan

Biometrik

Testing

Versi dependensi harus dikunci pada versi stabil yang kompatibel ketika proyek dibuat.

Kompatibilitas printer harus dibuktikan pada perangkat Android dan iOS nyata sebelum paket printer ditetapkan secara permanen.

Local Authentication

flutter_test dan integration_test

## 3.2 Diagram arsitektur

Aplikasi Flutter → Presentation Layer → Application dan Domain Layer → Repository → SQLite melalui Drift

Modul tambahan:

- Backup Service

- Import/Restore Service

- Export Service

- Receipt Service

- Printer Adapter

- Authentication Service

- Reporting Service

Semua modul bisnis beroperasi tanpa koneksi internet.

## 3.3 Prinsip arsitektur

- 1. UI tidak mengakses SQL secara langsung.

- 2. Perhitungan bisnis tidak ditempatkan di widget.

- 3. Repository menjadi jalur akses data.

- 4. Database menjadi sumber kebenaran.

- 5. Transaksi penting menggunakan database transaction.

- 6. Operasi file, printer, dan biometrik dipisahkan melalui service.

- 7. Error ditangani dengan pesan yang jelas.

- 8. Migrasi database wajib tersedia untuk perubahan skema.

- 3.4 Struktur folder

lib/

├── main.dart


├── app/

│ ├── app.dart

│ ├── router.dart

│ ├── bootstrap.dart

│ └── theme/

├── core/

│ ├── database/

│ │ ├── app_database.dart

│ │ ├── tables/

│ │ ├── daos/

│ │ └── migrations/

│ ├── errors/

│ ├── security/

│ ├── printing/

│ ├── backup/

│ ├── export/

│ └── utils/

├── features/

│ ├── onboarding/

│ ├── authentication/

│ ├── dashboard/

│ ├── business_settings/

│ ├── catalog/

│ ├── inventory/

│ ├── pos/

│ ├── sales_history/

│ ├── cash_management/

│ ├── cash_sessions/

│ ├── reports/

│ ├── receipts/


│ ├── backup_restore/

│ └── app_settings/

└── shared/

├── widgets/

├── formatters/

└── constants/

## 4. SPESIFIKASI DATABASE

## 4.1 Daftar tabel

## Tabel Tanggung jawab

business_settings Profil usaha, mata uang, pengaturan pajak

app_metadata ID database dan versi skema

categories

products

stock_movements Riwayat perubahan stok

sales

sale_items

sale_payments Metode dan nominal pembayaran

payment_methods Tunai, transfer, QRIS, dan metode lain

cash_transactions Kas masuk dan kas keluar

cash_sessions

audit_logs

receipt_settings Preferensi dan konfigurasi struk

Kategori produk dan transaksi kas

SKU, nama, satuan, harga jual, harga modal, status stok

Nomor transaksi, waktu, total, diskon, pajak, status

Detail produk dan snapshot harga saat transaksi

Buka/tutup kas dan rekonsiliasi

Riwayat tindakan penting

## 4.2 Aturan penyimpanan

- Gunakan integer untuk nilai rupiah, bukan floating-point.

- Gunakan UUID untuk identitas record.

- Simpan timestamp secara konsisten, misalnya UTC, lalu tampilkan menurut zona waktu lokal.

- Aktifkan foreign key SQLite.

- Gunakan constraint dan indeks untuk data yang sering dicari.


- Produk yang sudah memiliki riwayat transaksi sebaiknya dinonaktifkan daripada dihapus permanen.

- Snapshot nama produk, SKU, harga jual, dan harga modal harus tersimpan pada item penjualan.

- Nomor transaksi harus unik.

- Perubahan skema harus melalui migrasi database.

## 4.3 Relasi utama

- Satu penjualan memiliki banyak item penjualan.

- Satu penjualan dapat memiliki beberapa catatan pembayaran.

- Penjualan yang memengaruhi stok menghasilkan pergerakan stok.

- Pembayaran tunai menghasilkan arus kas terkait.

- Pembayaran QRIS dan transfer tidak otomatis menambah saldo uang tunai.

- Sesi kas mengacu pada transaksi kas yang terjadi dalam periode operasionalnya.

## 4.4 Data integritas

Database harus memastikan bahwa transaksi tidak tersimpan sebagian.

Contohnya, sistem tidak boleh menyimpan penjualan tanpa item, mengurangi stok tanpa penjualan, atau mencatat arus kas ganda akibat tombol pembayaran ditekan berulang.

## 5. SPESIFIKASI FITUR APLIKASI

## 5.1 Onboarding dan profil usaha

- Form nama usaha, alamat, dan nomor telepon.

- Konfigurasi mata uang.

- Konfigurasi pajak dan diskon.

- Identitas database dibuat secara otomatis.

- Profil tersimpan secara permanen.

## 5.2 Produk dan kategori

- Tambah, lihat, edit, dan nonaktifkan produk.

- Kelola kategori.

- SKU dan barcode opsional.

- Harga jual dan harga modal.

- Satuan produk.

- Pengaturan produk dengan atau tanpa stok.

- Pencarian produk.


- Riwayat penyesuaian stok.

- Validasi harga dan jumlah stok.

## 5.3 Kasir

- Pencarian dan pemilihan produk.

- Keranjang belanja.

- Ubah kuantitas.

- Diskon per item atau transaksi sesuai konfigurasi.

- Pajak opsional.

- Kalkulasi subtotal dan total.

- Pembayaran tunai, transfer, QRIS, atau campuran.

- Kalkulasi kembalian.

- Penyelesaian transaksi.

- Riwayat dan detail transaksi.

- Pembatalan dengan alasan dan audit.

- Cetak ulang struk tanpa membuat transaksi baru.

## 5.4 Manajemen kas

- Kas masuk.

- Kas keluar.

- Kategori transaksi kas.

- Saldo awal.

- Buka kas harian.

- Tutup kas.

- Saldo teoritis.

- Saldo aktual.

- Selisih kas.

- Catatan penjelasan selisih.

- Riwayat kas yang dapat difilter berdasarkan tanggal.

## 5.5 Dashboard

Tampilkan:

- Omzet hari ini.

- Jumlah transaksi.


- Total diskon.

- Ringkasan pembayaran.

- Kas masuk dan keluar.

- Saldo kas.

- Ringkasan stok.

- Produk terlaris bila tersedia.

- 5.6 Laporan

- Laporan penjualan berdasarkan tanggal.

- Rekap pembayaran.

- Laporan kas masuk dan keluar.

- Laporan sesi kas.

- Laporan stok.

- Riwayat pergerakan stok.

- Produk terlaris.

- Laba kotor berdasarkan snapshot harga modal.

- Filter tanggal dan kategori.

Laba kotor bukan laba bersih. Biaya operasional lain perlu diperhitungkan jika kelak dibutuhkan laporan laba bersih.

- 6. ATURAN BISNIS DAN KONSISTENSI DATA

## 6.1 Saldo kas

Saldo akhir kas teoritis:

Saldo awal + kas masuk − kas keluar.

Saldo aktual berasal dari penghitungan fisik pengguna. Selisih dihitung dari saldo aktual dikurangi saldo teoritis.

Pisahkan saldo tunai dari pembayaran non-tunai. Jika kelak diperlukan, buat ringkasan aset pembayaran

per metode.

- 6.2 Penyelesaian penjualan

Gunakan satu use case utama, misalnya CompleteSaleUseCase.

Urutannya:

- 1. Validasi keranjang dan pembayaran.

- 2. Mulai transaksi database.


- 3. Periksa stok terakhir.

- 4. Simpan transaksi penjualan.

- 5. Simpan item penjualan.

- 6. Simpan pembayaran.

- 7. Simpan pergerakan stok.

- 8. Buat arus kas yang relevan.

- 9. Commit transaksi.

- 10. Tampilkan struk dan pilihan cetak.

Jika proses database gagal sebelum commit, rollback seluruh perubahan.

Pencetakan dilakukan setelah commit. Kegagalan printer tidak membatalkan penjualan yang sudah berhasil.

- 6.3 Pembatalan

Transaksi yang sudah selesai tidak boleh dihapus begitu saja.

Pembatalan harus:

- Menyimpan alasan.

- Membuat catatan audit.

- Menghasilkan koreksi pembayaran atau kas sesuai keadaan.

- Memulihkan stok jika barang benar-benar dikembalikan.

- Mempertahankan riwayat transaksi asli.

- 7. SISTEM BACKUP, IMPORT, DAN EXPORT

## 7.1 Backup lengkap JSON

Backup harus mencakup semua tabel bisnis yang diperlukan, ID record, relasi, versi format, ID database, waktu ekspor, dan informasi integritas.

Contoh struktur:

{

"format": "kasir_backup",

"formatVersion": 1,

"databaseId": "uuid-database",

"exportedAt": "2026-10-19T02:00:00Z",

"appVersion": "1.0.0",


```
"tables": {
"products": [],
"categories": [],
"sales": [],
"sale_items": [],
"sale_payments": [],
"cash_transactions": [],
"cash_sessions": [],
"stock_movements": []
},
"integrity": {
"algorithm": "SHA-256",
"checksum": "..."
}
}
```

Struktur tersebut adalah contoh kontrak awal. Implementasi final harus mencantumkan seluruh tabel, aturan serialisasi, dan perhitungan checksum yang tidak ambigu.

## 7.2 Kebijakan ekspor

- JSON: backup lengkap.

- CSV: data produk, transaksi, stok, dan kas.

- PDF: laporan siap dibaca atau dicetak.

CSV tidak dianggap sebagai backup penuh karena dapat kehilangan relasi dan metadata penting.

- 7.3 Alur backup

- 1. Pengguna memilih Backup.

- 2. Aplikasi menyiapkan snapshot data yang konsisten.

- 3. Data divalidasi dan diekspor.

- 4. File sementara dibuat.

- 5. File diverifikasi.

- 6. Pengguna memilih lokasi penyimpanan atau membagikan file.

- 7. Aplikasi menampilkan status berhasil atau gagal.

## 7.4 Alur restore


- 1. Pilih file backup.

- 2. Validasi format, versi, checksum, dan relasi.

- 3. Tampilkan ringkasan isi backup.

- 4. Minta konfirmasi restore penuh.

- 5. Buat backup pengaman database aktif.

- 6. Pulihkan data melalui mekanisme atomik.

- 7. Verifikasi jumlah record dan integritas relasi.

- 8. Tampilkan hasil pemulihan.

Restore yang gagal tidak boleh merusak database aktif.

## 7.5 Kebijakan import

Mode MVP:

- Restore penuh dari JSON.

- Import CSV dengan pemetaan kolom.

- Preview data sebelum import.

- Validasi setiap baris.

- Laporan baris berhasil dan gagal.

Mode merge dapat ditambahkan setelah kebijakan konflik, identitas database, dan duplikasi record didefinisikan secara menyeluruh.

## 7.6 Keamanan backup

Sediakan opsi enkripsi backup menggunakan algoritma yang sesuai, misalnya AES-256-GCM dengan derivasi kunci yang kuat dari kata sandi pengguna.

Kata sandi tidak boleh disimpan dalam teks biasa. Jangan mengklaim backup terenkripsi jika implementasinya baru berupa checksum.

- 8. KEAMANAN APLIKASI

## 8.1 PIN

- PIN dibuat saat konfigurasi awal.

- PIN dikonfirmasi sebelum disimpan.

- Simpan hash PIN dengan salt menggunakan algoritma yang sesuai.

- Batasi percobaan PIN.

- Beri jeda setelah kegagalan berulang.

- Jangan mencatat PIN dalam log.


- Kunci aplikasi ketika kembali dari latar belakang sesuai pengaturan.

## 8.2 Biometrik

- Gunakan API autentikasi lokal sistem operasi.

- Aktifkan hanya jika perangkat mendukungnya dan pengguna memilih untuk mengaktifkannya.

- Sediakan fallback PIN.

- Jangan mengakses atau menyimpan data biometrik mentah.

- Uji perilaku ketika biometrik tidak tersedia atau dinonaktifkan.

## 8.3 Pemulihan akses

Karena aplikasi tidak menggunakan server, prosedur pemulihan PIN harus ditentukan sejak awal.

Reset akses tidak boleh secara diam-diam menghapus data bisnis. Berikan penjelasan tentang konsekuensi reset dan kebutuhan backup.

## 9. STRUK DIGITAL DAN PRINTER BLUETOOTH

## 9.1 Struk digital

Struk minimal memuat:

- Nama dan informasi usaha.

- Nomor transaksi.

- Tanggal dan waktu.

- Daftar produk.

- Kuantitas dan harga.

- Diskon dan pajak bila ada.

- Total transaksi.

- Rincian pembayaran.

- Nominal tunai dan kembalian jika relevan.

- Footer yang dapat dikonfigurasi.

## 9.2 Printer Bluetooth

- Buat PrinterService atau interface setara.

- Pisahkan logika bisnis dari implementasi protokol printer.

- Target awal adalah printer ESC/POS Bluetooth yang kompatibel.

- Uji Bluetooth Classic dan BLE secara terpisah bila keduanya dibutuhkan.

- Tangani izin Bluetooth sesuai versi sistem operasi.


- Simpan preferensi printer secara lokal.

- Tampilkan status koneksi dan error.

- Cetak ulang transaksi yang sudah tersimpan.

## 9.3 Pengujian printer

Sebelum memilih paket printer final, lakukan proof of concept pada Android dan iOS dengan model printer yang nyata.

Keberhasilan pada satu model printer tidak otomatis menjamin kompatibilitas seluruh perangkat.

- 10. ROADMAP IMPLEMENTASI

Tahap

Fondasi proyek dan database 1 minggu

Master data produk dan stok 1 minggu

Modul kasir

Manajemen kas

Dashboard dan laporan

Backup, restore, dan ekspor 1–2 minggu

Printer, keamanan, QA, dan rilis 1–2 minggu

Estimasi awal keseluruhan sekitar 6–9 minggu untuk MVP dengan ruang lingkup terbatas. Dengan backlog dan pengujian menyeluruh, perencanaan kalender yang lebih aman adalah sekitar 8–10 minggu.

Durasi bergantung pada pengalaman developer, desain UI, kompatibilitas printer, dan kebutuhan revisi.

Durasi estimasi

1–2 minggu

1 minggu

1 minggu

## 11. BACKLOG CODING

## Sprint 0 — Fondasi

Prioritas P0:

- Setup Flutter dan build Android/iOS.

- Konfigurasi Drift, Riverpod, dan go_router.

- Struktur folder dan dependency injection.

- Error handling dan logging.

- Migrasi database awal.

- UUID dan foreign key.


- Proof of concept printer Bluetooth.

Kriteria selesai: aplikasi berjalan pada kedua platform dan dapat membuat serta membuka database lokal.

## Sprint 1 — Master data

- Onboarding profil usaha.

- CRUD kategori.

- CRUD produk.

- SKU dan barcode opsional.

- Harga jual dan modal.

- Pengaturan stok.

- Stock movements.

- Produk tanpa stok.

Kriteria selesai: produk tersimpan secara persisten dan seluruh perubahan stok dapat ditelusuri.

## Sprint 2 — Kasir

- Keranjang belanja.

- Kalkulasi subtotal.

- Diskon dan pajak.

- Metode pembayaran.

- Pembayaran campuran.

- Kalkulasi kembalian.

- CompleteSaleUseCase.

- Proteksi double-submit.

- Riwayat dan detail transaksi.

- Pembatalan dan koreksi.

Kriteria selesai: penjualan, item, pembayaran, dan stok konsisten dalam satu transaksi database.

## Sprint 3 — Manajemen kas

- Kas masuk.

- Kas keluar.

- Kategori kas.

- Buka kas.

- Tutup kas.

- Saldo sistem dan saldo aktual.


- Perhitungan selisih.

- Audit log.

Kriteria selesai: saldo kas sesuai dengan arus kas dan transaksi yang tercatat.

## Sprint 4 — Dashboard dan laporan

- Dashboard omzet.

- Ringkasan transaksi.

- Laporan penjualan.

- Laporan pembayaran.

- Laporan kas.

- Laporan stok.

- Filter tanggal.

- Laporan laba kotor.

- Produk terlaris.

Kriteria selesai: seluruh angka laporan dapat direkonsiliasi dengan database.

## Sprint 5 — Struk dan printer

- Template struk digital.

- Ekspor struk PDF.

- Printer adapter.

- Koneksi printer.

- Pemilihan ukuran kertas.

- Status koneksi.

- Cetak ulang.

- Pengaturan header/footer.

Kriteria selesai: struk dapat dibagikan dan dicetak pada model printer target tanpa menggandakan transaksi.

## Sprint 6 — Keamanan

- Setup PIN.

- Hash PIN yang aman.

- Pembatasan percobaan.

- Integrasi biometrik.

- Fallback PIN.


- Auto-lock.

- Uji lifecycle aplikasi.

Kriteria selesai: PIN dan biometrik berfungsi sesuai kebijakan keamanan yang ditentukan.

## Sprint 7 — Backup dan export

- Definisikan format JSON berversi.

- Ekspor backup lengkap.

- Validasi checksum.

- Restore penuh.

- Backup pengaman.

- Rollback saat gagal.

- Ekspor CSV.

- Ekspor PDF laporan.

- Import CSV dan preview.

- Laporan kesalahan impor.

Kriteria selesai: data dapat dipulihkan dan file yang rusak ditolak tanpa merusak database aktif.

## Sprint 8 — QA dan rilis

- Unit test perhitungan uang.

- Unit test aturan stok.

- Integration test transaksi database.

- Uji rollback.

- Uji backup dan restore.

- Uji file rusak.

- Uji persistensi offline.

- Uji Android dan iOS.

- Uji printer nyata.

- Build release.

- Konfigurasi signing.

- Checklist distribusi aplikasi.

Kriteria selesai: seluruh alur inti lulus pengujian dan build produksi siap diuji pengguna.

## 12. STRATEGI PENGUJIAN


## 12.1 Unit test

Uji:

- Subtotal dan total.

- Diskon.

- Pajak.

- Pembayaran campuran.

- Kembalian.

- Saldo kas.

- Perhitungan selisih kas.

- Perubahan stok.

- Laba kotor.

## 12.2 Integration test

Uji:

- Penjualan berhasil.

- Penjualan gagal dan rollback.

- Stok tidak cukup.

- Pembayaran ganda.

- Restore berhasil.

- Restore gagal.

- Migrasi database.

- Persistensi setelah aplikasi dimulai ulang.

## 12.3 Pengujian perangkat

- Android dengan izin Bluetooth yang relevan.

- iOS dengan izin dan API Bluetooth yang relevan.

- Printer target.

- Aplikasi berjalan offline.

- Aplikasi ditutup paksa.

- Ruang penyimpanan hampir penuh.

- File backup besar.

- Biometrik tidak tersedia.

- PIN salah berulang kali.


## 13. KRITERIA PENERIMAAN MVP

Aplikasi dinyatakan memenuhi MVP jika:

- Berjalan di Android dan iOS.

- Dapat digunakan tanpa internet.

- Data bertahan setelah aplikasi ditutup dan dibuka kembali.

- Produk, stok, dan transaksi konsisten.

- Pembayaran tunai dan non-tunai dibedakan dengan benar.

- Saldo kas sesuai dengan arus uang yang tercatat.

- Laporan sesuai dengan data transaksi.

- Struk digital dapat dibuat dan dibagikan.

- Printer target dapat digunakan dan kegagalan cetak tidak membatalkan transaksi.

- PIN dan biometrik mengikuti aturan keamanan.

- Backup lengkap dapat diekspor.

- Restore dapat dilakukan tanpa kehilangan data akibat kegagalan proses.

- CSV dapat dibuka di aplikasi spreadsheet.

- File backup rusak atau tidak kompatibel ditolak.

- Migrasi database telah diuji.

## 14. RISIKO DAN MITIGASI

Risiko

Perangkat rusak atau aplikasi dihapus Backup rutin ke lokasi eksternal

File backup rusak

Data transaksi tidak konsisten

Stok tidak sesuai

Cetak gagal

Printer tidak kompatibel

PIN terlupa

Data sensitif bocor melalui backup Enkripsi backup opsional dan pengamanan file

Mitigasi

Checksum, validasi, dan backup pengaman

Transaksi database atomik

Stock movements dan rekonsiliasi

Pisahkan proses cetak dari transaksi penjualan

Proof of concept sejak awal

Prosedur pemulihan akses yang jelas


Risiko

Mitigasi

Migrasi merusak database

Uji migrasi dan backup sebelum pembaruan

Nilai uang salah pembulatan

Integer untuk nilai rupiah

## 15. DEFINITION OF DONE

Setiap fitur dianggap selesai apabila:

- 1. Logika bisnis berada di layer yang tepat.

- 2. UI menangani kondisi loading, kosong, berhasil, dan gagal.

- 3. Database memiliki constraint dan migrasi yang diperlukan.

- 4. Unit test dan integration test relevan telah lulus.

- 5. Tidak ada ketidakkonsistenan saldo atau stok.

- 6. Perilaku offline telah diuji.

- 7. Perubahan penting dapat ditelusuri.

- 8. Tidak ada rahasia sensitif di log.

- 9. Fitur diuji pada Android dan iOS sesuai ruang lingkupnya.

- 10. Dokumentasi teknis diperbarui.

## 16. RENCANA MULAI CODING DAN RILIS

Urutan implementasi yang direkomendasikan:

- 1. Setup proyek Flutter.

- 2. Setup database dan migrasi.

- 3. Implementasikan produk dan kategori.

- 4. Implementasikan mesin transaksi kasir.

- 5. Buat UI kasir.

- 6. Implementasikan manajemen kas.

- 7. Implementasikan dashboard dan laporan.

- 8. Integrasikan struk dan printer.

- 9. Implementasikan PIN dan biometrik.

- 10. Implementasikan backup, restore, dan ekspor.

- 11. Jalankan pengujian menyeluruh.


- 12. Siapkan build rilis Android dan iOS.

## Keputusan teknis final

Aplikasi menggunakan Flutter, SQLite, dan Drift sebagai fondasi offline-first. Database lokal adalah sumber data utama. Semua transaksi keuangan dan perubahan stok harus atomik. Backup JSON menjadi jalur pemulihan utama, sedangkan CSV dan PDF digunakan untuk ekspor laporan.

Dengan spesifikasi dan backlog ini, proyek siap memasuki tahap implementasi kode tanpa memerlukan server atau sinkronisasi antarperangkat untuk MVP.
