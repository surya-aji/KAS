# Task Breakdown Development Application POS (Frontend-First Approach)

Dokumen ini berisi daftar tugas pengembangan aplikasi Kasir (Point of Sale) menggunakan Flutter dengan pendekatan **Frontend-First**. Seluruh antarmuka (UI), navigasi, dan *state management* dengan dummy/mock data akan disiapkan terlebih dahulu sebelum dihubungkan ke *database* lokal (Drift/SQLite).

---

## T0: Fondasi & Setup Proyek Flutter

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T0.1** | Buat proyek Flutter | Struktur proyek dasar terbuat |
| **T0.2** | Pasang dependensi UI & Navigasi | Package `go_router`, `flutter_riverpod`, ikon, dll. terpasang |
| **T0.3** | Buat struktur folder arsitektur | Folder fitur, core, widget reusable tersusun rapi |
| **T0.4** | Desain Sistem Tema & Komponen Global | Warna, tipografi, tombol, dan input kustom konsisten |

---

## T1: Manajemen Data & Master (Frontend & Mock State)

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T1.1** | UI & State Form Profil Usaha | Halaman pengaturan profil usaha statis/tersimpan di Provider lokal |
| **T1.2** | UI & State CRUD Kategori | Tampilan daftar, tambah, edit, dan hapus kategori (dummy state) |
| **T1.3** | UI & State CRUD Produk | Tampilan manajemen produk, pencarian, filter, dan form input |
| **T1.4** | Validasi Form Harga & Stok | Validasi input angka, stok minimum, dan pesan error UI |
| **T1.5** | UI Riwayat Perubahan Stok | Tampilan log histori perubahan stok produk (dummy data) |

---

## T2: Modul Kasir / POS (Point of Sale)

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T2.1** | UI Halaman Kasir (Grid Produk & Pencarian) | Layout kasir responsif untuk tablet/smartphone |
| **T2.2** | UI Keranjang Belanja Interaktif | Tambah, kurangi, hapus item, dan ubah jumlah langsung di keranjang |
| **T2.3** | Logika & Tampilan Kalkulasi Transaksi | Perhitungan subtotal, diskon item/total, dan pajak secara real-time |
| **T2.4** | UI Modal / Halaman Metode Pembayaran | Pilihan pembayaran Tunai, Transfer, dan QRIS |
| **T2.5** | UI Pembayaran Campuran (Multi-payment) | Input nominal untuk kombinasi metode pembayaran |
| **T2.6** | Simulasi Checkout & Dialog Sukses | Alur sukses transaksi dan cetak struk sementara |
| **T2.7** | UI Riwayat & Detail Transaksi | Daftar transaksi masa lalu beserta rincian item yang dibeli |
| **T2.8** | UI Pembatalan / Void Transaksi | Modal alasan pembatalan dan konfirmasi PIN/otorisasi |

---

## T3: Manajemen Kas (Cash Drawer) & Aktivitas

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T3.1** | UI Form Kas Masuk / Keluar | Pencatatan arus kas operasional harian |
| **T3.2** | UI Modal Buka Kas (Open Shift) | Input saldo awal kasir sebelum mulai shift |
| **T3.3** | UI Rekonsiliasi & Tutup Kas (Close Shift) | Perhitungan selisih kas fisik vs sistem saat tutup kas |
| **T3.4** | UI Audit Log Aktivitas | Tampilan daftar log aktivitas penting di aplikasi |

---

## T4: Dashboard & Laporan

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T4.1** | UI Dashboard & Ringkasan Operasional | Kartu statistik omzet, produk terlaris, dan grafik ringkas |
| **T4.2** | UI Laporan Penjualan & Filter Tanggal | Tabel laporan penjualan dengan filter rentang tanggal |
| **T4.3** | UI Laporan Rekap Pembayaran | Grafik/tabel rekapitulasi per metode pembayaran |
| **T4.4** | UI Laporan Kas & Stok | Tampilan rekap arus kas dan sisa stok opname |
| **T4.5** | UI Laporan Laba Kotor | Rekapitulasi laba kotor berdasarkan perbandingan harga modal dan jual |

---

## T5: Struk & Integrasi Perangkat Cetak (Mock/UI Preview)

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T5.1** | Desain Template Struk Digital | Layout struk rapi siap cetak atau dibagikan |
| **T5.2** | UI Pratinjau Ekspor Struk PDF | Halaman preview dokumen PDF sebelum dibagikan via WhatsApp/Email |
| **T5.3** | UI Pengaturan & Pencarian Printer | Tampilan status koneksi Bluetooth/Network printer |
| **T5.4** | Simulasi Cetak & Cetak Ulang | Tombol cetak struk dengan pencegahan cetak ganda di UI |

---

## T6: Keamanan & Autentikasi Frontend

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T6.1** | UI Pembuatan & Masuk PIN | Halaman input PIN numerik (Numpad custom) |
| **T6.2** | UI Pengaturan Keamanan PIN | Konfirmasi PIN baru, aturan batas salah percobaan |
| **T6.3** | UI Integrasi Biometrik (Opsional) | Tombol/opsi login sidik jari/Face ID |
| **T6.4** | UI Auto-lock & Pemulihan Akses | Layar terkunci otomatis saat idle (tidak aktif) |

---

## T7: Manajemen Data, Backup & Impor (UI Layer)

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T7.1** | UI Menu Pengaturan Pencadangan | Opsi menu ekspor/impor data |
| **T7.2** | UI Proses Ekspor Berkas Backup | Tombol unduh file backup JSON |
| **T7.3** | UI Validasi Berkas Masuk | Tampilan peringatan jika file backup tidak valid/rusak |
| **T7.4** | UI Progress Pemulihan (Restore) | Indikator loading saat memulihkan data |
| **T7.5** | UI Tombol Ekspor CSV/PDF Laporan | Tombol unduh laporan terpisah |
| **T7.6** | UI Preview Impor CSV Produk | Tabel pratinjau baris data CSV sebelum dimasukkan sistem |

---

## T8: Pengujian Frontend & Integrasi Backend (Tahap Sambung)

| Kode | Task Kecil | Hasil yang Diharapkan |
| :--- | :--- | :--- |
| **T8.1** | Setup Drift + SQLite (Backend Integration) | Hubungkan state management/provider yang tadinya mock ke database lokal Drift |
| **T8.2** | Implementasi Migrasi Database | Skema database relasional aktif dan migrasi berjalan lancar |
| **T8.3** | Widget & Unit Test Frontend | Menguji komponen UI utama dan alur navigasi |
| **T8.4** | Uji Integrasi Alur Transaksi Nyata | Memastikan alur dari input produk -> kasir -> simpan database berjalan konsisten |
| **T8.5** | Uji Lintas Platform & Build Rilis | Memastikan tampilan responsif di Android/iOS dan siap rilis |