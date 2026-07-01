# Blood Pressure Reader for iOS

Aplikasi iOS berbasis SwiftUI untuk mengambil atau memilih foto layar tensimeter digital, membaca nilai **systolic**, **diastolic**, dan **pulse** menggunakan FastVLM secara on-device, lalu memasukkan hasilnya ke form pencatatan tekanan darah.

> [!IMPORTANT]
> Aplikasi ini membaca tampilan perangkat dan bukan alat diagnosis medis. Hasil inference harus tetap dapat diperiksa dan dikoreksi oleh pengguna sebelum disimpan.

## Fitur

* Mengambil foto menggunakan kamera atau memilih gambar dari galeri.
* Memeriksa apakah gambar merupakan tensimeter digital.
* Memeriksa apakah tampilan cukup jelas untuk dibaca.
* Membaca nilai systolic, diastolic, dan pulse.
* Mengembalikan hasil inference dalam format JSON terstruktur.
* Mengisi form pencatatan tekanan darah secara otomatis.
* Menjalankan inference secara lokal menggunakan MLX dan FastVLM.
* Tidak menggunakan Apple Foundation Models atau layanan inference eksternal.

## Alur Pemrosesan

```text
UIImage
   │
   ├─ Normalisasi orientasi
   ├─ Center crop ke rasio 4:3
   ├─ Resize ke 640 × 480
   │
   ▼
FastVLM
   │
   ├─ Prompt pembacaan tensimeter
   ├─ Temperature 0.0
   ├─ Maximum tokens 240
   │
   ▼
JSON response
   │
   ├─ Validasi struktur
   ├─ Parse systolic
   ├─ Parse diastolic
   └─ Parse pulse
   │
   ▼
Form pencatatan tekanan darah
```

Format respons yang diharapkan:

```json
{
  "is_blood_pressure_monitor": true,
  "is_clear": true,
  "systolic": 120,
  "diastolic": 80,
  "pulse": 72
}
```

Ketika suatu nilai tidak dapat dibaca dengan yakin, model harus mengembalikan `0` dan tidak menebak digit yang tidak jelas.

## Persyaratan

* macOS dengan Apple Silicon direkomendasikan.
* Xcode yang mendukung iOS 18.2 atau lebih baru.
* Deployment target: **iOS 18.2**.
* Swift language version: **Swift 5**.
* Perangkat iPhone atau iPad fisik direkomendasikan.
* Ruang penyimpanan yang cukup untuk model FastVLM.

FastVLM menggunakan Metal melalui MLX. Pengujian pada perangkat fisik lebih representatif daripada simulator untuk penggunaan memory dan performa inference.

## Dependency

Project menggunakan Swift Package Manager dengan versi exact berikut:

| Repository                                          |  Version | Products                               |
| --------------------------------------------------- | -------: | -------------------------------------- |
| `https://github.com/ml-explore/mlx-swift`           | `0.21.2` | `MLX`, `MLXNN`, `MLXFast`              |
| `https://github.com/ml-explore/mlx-swift-examples`  | `2.21.2` | `MLXVLM`, `MLXLMCommon`                |
| `https://github.com/huggingface/swift-transformers` | `0.1.18` | `Transformers`                         |

> [!WARNING]
> Jangan memperbarui package MLX secara otomatis tanpa pengujian ulang. Versi package yang tidak kompatibel dapat menyebabkan error pada attention mask, `UserInput.Prompt`, atau argumen image grid.

## Struktur Project

```text
Blood Pressure/
├── Blood Pressure.xcodeproj/
├── Blood Pressure/
│   ├── FastVLM/
│   │   ├── FastVLM.swift
│   │   ├── MediaProcessingExtensions.swift
│   │   └── model/                         # lokal, tidak di-push
│   ├── Models/
│   │   └── OCRParsedResult.swift
│   ├── Services/
│   │   └── FastVLMBloodPressureService.swift
│   ├── Views/
│   │   └── AddReadingView.swift
│   ├── Assets.xcassets/
│   └── ...
├── .gitignore
├── Package.resolved
└── README.md
```

Ketentuan Git:

* `FastVLM.swift` di-commit.
* `MediaProcessingExtensions.swift` di-commit.
* Folder `FastVLM/model/` tidak di-commit karena ukurannya besar.
* Repository resmi `ml-fastvlm` hanya digunakan sebagai sumber download sementara.

# Instalasi

## 1. Clone Repository Aplikasi

```bash
git clone <URL_REPOSITORY_APLIKASI>
cd "<NAMA_FOLDER_REPOSITORY>"
```

Buka project:

```bash
open "Blood Pressure.xcodeproj"
```

Sesuaikan nama file `.xcodeproj` apabila nama project berbeda.

## 2. Clone Repository Resmi FastVLM

Clone repository FastVLM di luar folder project aplikasi. Contoh berikut menggunakan folder `Downloads`:

```bash
cd ~/Downloads
git clone https://github.com/apple/ml-fastvlm.git
cd ml-fastvlm
```

Repository tersebut hanya digunakan sebagai sumber untuk mengambil source FastVLM dan model.

## 3. Download Model FastVLM 0.5B

Masih dari folder:

```text
~/Downloads/ml-fastvlm
```

Berikan permission executable pada script:

```bash
chmod +x app/get_pretrained_mlx_model.sh
```

Download model:

```bash
./app/get_pretrained_mlx_model.sh \
  --model 0.5b \
  --dest app/FastVLM/model
```

Setelah selesai, model tersedia di:

```text
~/Downloads/ml-fastvlm/app/FastVLM/model/
```

Model `0.5b` dipilih karena lebih sesuai untuk penggunaan pada perangkat mobile dibandingkan varian yang lebih besar.

## 4. Memindahkan FastVLM ke Project Aplikasi

### Integrasi Pertama Kali

Langkah ini hanya diperlukan ketika pertama kali memasukkan FastVLM ke project.

Buat folder FastVLM di dalam target aplikasi:

```bash
mkdir -p "/PATH/KE/PROJECT/Blood Pressure/FastVLM"
```

Salin source FastVLM:

```bash
cp ~/Downloads/ml-fastvlm/app/FastVLM/FastVLM.swift \
  "/PATH/KE/PROJECT/Blood Pressure/FastVLM/"

cp ~/Downloads/ml-fastvlm/app/FastVLM/MediaProcessingExtensions.swift \
  "/PATH/KE/PROJECT/Blood Pressure/FastVLM/"
```

Salin model:

```bash
cp -R ~/Downloads/ml-fastvlm/app/FastVLM/model \
  "/PATH/KE/PROJECT/Blood Pressure/FastVLM/"
```

Hasil akhirnya:

```text
Blood Pressure/
└── Blood Pressure/
    └── FastVLM/
        ├── FastVLM.swift
        ├── MediaProcessingExtensions.swift
        └── model/
```

File `FastVLM.h` tidak diperlukan karena source FastVLM dikompilasi langsung ke target aplikasi Swift.

### Setelah Clone Repository Aplikasi

Pada repository ini, file berikut sudah di-commit:

```text
FastVLM/FastVLM.swift
FastVLM/MediaProcessingExtensions.swift
```

Developer yang baru melakukan clone hanya perlu menyalin folder model:

```bash
mkdir -p "/PATH/KE/PROJECT/Blood Pressure/FastVLM"

rm -rf "/PATH/KE/PROJECT/Blood Pressure/FastVLM/model"

cp -R ~/Downloads/ml-fastvlm/app/FastVLM/model \
  "/PATH/KE/PROJECT/Blood Pressure/FastVLM/"
```

Ganti `/PATH/KE/PROJECT` dengan lokasi project pada komputer Anda.

Contoh:

```bash
cp -R ~/Downloads/ml-fastvlm/app/FastVLM/model \
  "/Users/username/Documents/Blood Pressure/Blood Pressure/FastVLM/"
```

## 5. Tambahkan FastVLM ke Xcode

Apabila file belum muncul di Project Navigator:

1. Klik kanan group utama **Blood Pressure**.
2. Pilih **Add Files to "Blood Pressure"...**.
3. Tambahkan:

   * `FastVLM.swift`
   * `MediaProcessingExtensions.swift`
   * folder `model`
4. Aktifkan target membership untuk target aplikasi.
5. Pastikan struktur folder model tetap dipertahankan.

Periksa Build Phases:

```text
Target
└── Build Phases
    ├── Compile Sources
    │   ├── FastVLM.swift
    │   ├── MediaProcessingExtensions.swift
    │   └── FastVLMBloodPressureService.swift
    └── Copy Bundle Resources
        └── model
```

Jangan menambahkan file yang sama lebih dari satu kali karena dapat menyebabkan duplicate build command atau duplicate symbol.

## 6. Tambahkan Swift Package Dependencies

Di Xcode:

1. Pilih project pada Project Navigator.
2. Buka tab **Package Dependencies**.
3. Tekan tombol **+**.
4. Tambahkan package berikut.

### MLX Swift

Repository:

```text
https://github.com/ml-explore/mlx-swift
```

Dependency rule:

```text
Exact Version: 0.21.2
```

Products:

```text
MLX
MLXNN
MLXFast
MLXRandom
```

### MLX Swift Examples

Repository:

```text
https://github.com/ml-explore/mlx-swift-examples
```

Dependency rule:

```text
Exact Version: 2.21.2
```

Products:

```text
MLXVLM
MLXLMCommon
```

### Swift Transformers

Repository:

```text
https://github.com/huggingface/swift-transformers
```

Dependency rule:

```text
Exact Version: 0.1.18
```

Product:

```text
Transformers
```

Setelah package selesai di-resolve, commit `Package.resolved` agar developer lain menggunakan versi dependency yang sama.

## 7. Atur Deployment Target

Di Xcode:

```text
Project
└── Targets
    └── Blood Pressure
        └── General
            └── Minimum Deployments
                └── iOS 18.2
```

Pastikan deployment target project dan target aplikasi konsisten.

## 8. Tambahkan Camera Permission

Pada target aplikasi, buka tab **Info** lalu tambahkan:

```text
Privacy - Camera Usage Description
```

Contoh value:

```text
Kamera digunakan untuk mengambil foto tampilan tensimeter.
```

Untuk `Info.plist` manual:

```xml
<key>NSCameraUsageDescription</key>
<string>Kamera digunakan untuk mengambil foto tampilan tensimeter.</string>
```

## 9. Atur Signing

Di Xcode:

```text
Target
└── Signing & Capabilities
    ├── Automatically manage signing: Enabled
    ├── Team: akun Apple Developer Anda
    └── Bundle Identifier: identifier unik
```

## 10. Resolve Package Versions

Gunakan menu:

```text
File
└── Packages
    └── Resolve Package Versions
```

Apabila Xcode masih menggunakan cache dependency lama:

```text
File
└── Packages
    └── Reset Package Caches
```

Kemudian resolve kembali package versions.

## 11. Build dan Jalankan

Pilih perangkat iPhone fisik, lalu build:

```text
Command + B
```

Jalankan aplikasi:

```text
Command + R
```

Inference pertama dapat lebih lambat karena model harus dimuat ke memory. `ModelContainer` disimpan oleh service agar tidak dimuat ulang untuk setiap foto.

# Konfigurasi Inference

Implementasi saat ini menggunakan:

```swift
let parameters = GenerateParameters(temperature: 0.0)
let maximumTokens = 240
MLXRandom.seed(...)
```

Sebelum dikirim ke model, gambar:

1. dinormalisasi orientasinya;
2. di-center-crop ke rasio 4:3;
3. di-resize menjadi 640 × 480;
4. dikirim sebagai `CIImage` melalui `UserInput`.

Model dimuat menggunakan:

```swift
VLMModelFactory.shared.loadContainer(
    configuration: FastVLM.modelConfiguration
)
```

`FastVLM.modelConfiguration` mencari `config.json` dari resource bundle yang sama dengan class `FastVLM`. Karena itu, seluruh isi folder `model` harus tersedia di bundle aplikasi.

## Prompt Pembacaan Tensimeter

Prompt memperlakukan gambar sebagai satu-satunya sumber kebenaran dan tidak boleh menggunakan nilai tekanan darah normal atau umum sebagai tebakan.

Output harus mengikuti struktur JSON pada bagian **Alur Pemrosesan**.

Nama field berikut tidak boleh diubah tanpa memperbarui parser dan `OCRParsedResult`:

```text
is_blood_pressure_monitor
is_clear
systolic
diastolic
pulse
```

# Git Setup

File yang harus di-commit:

```text
Blood Pressure.xcodeproj/project.pbxproj
Package.resolved
Blood Pressure/FastVLM/FastVLM.swift
Blood Pressure/FastVLM/MediaProcessingExtensions.swift
Blood Pressure/Models/
Blood Pressure/Services/
Blood Pressure/Views/
Blood Pressure/Assets.xcassets/
README.md
.gitignore
```

File yang tidak di-commit:

```text
DerivedData/
build/
xcuserdata/
.swiftpm/
Blood Pressure/FastVLM/model/
Xcode archives
provisioning profiles
signing certificates
local secrets
```

Periksa file sebelum commit:

```bash
git status
```

Source FastVLM harus muncul sebagai tracked files, sedangkan folder `model` tidak boleh muncul.

Commit perubahan:

```bash
git add .
git status
git commit -m "Add FastVLM blood pressure reader"
git push origin main
```

# Troubleshooting

## FastVLM Tidak Ditemukan

Pastikan file berikut ada dan memiliki target membership pada target aplikasi:

```text
Blood Pressure/FastVLM/FastVLM.swift
Blood Pressure/FastVLM/MediaProcessingExtensions.swift
Blood Pressure/Services/FastVLMBloodPressureService.swift
```

## Model Tidak Ditemukan

Pastikan file berikut tersedia:

```text
Blood Pressure/FastVLM/model/config.json
```

Pastikan juga folder `model` terdapat pada:

```text
Target
└── Build Phases
    └── Copy Bundle Resources
```

Apabila model belum ada, ulangi langkah **Download Model FastVLM 0.5B** dan **Memindahkan FastVLM ke Project Aplikasi**.

Setelah itu, lakukan Clean Build Folder dan build ulang.

## Package Product Tidak Ditemukan

Pastikan seluruh products pada bagian **Tambahkan Swift Package Dependencies** sudah ditambahkan ke target aplikasi.

## Error API MLX atau MLXVLM

Contoh error akibat versi package tidak kompatibel:

```text
Cannot convert value of type
'MLXFast.ScaledDotProductAttentionMaskMode'
to expected argument type 'MLXArray'
```

```text
Value of type 'UserInput.Prompt' has no member 'asMessages'
```

```text
Extra argument 'imageGridThw' in call
```

Perbaikan:

1. Periksa `Package.resolved`.
2. Gunakan kembali versi exact yang tercantum pada README.
3. Reset package cache.
4. Resolve package versions.
5. Clean Build Folder.
6. Build ulang.

## Duplicate Build Command

Periksa apakah `FastVLM.swift`, `MediaProcessingExtensions.swift`, atau folder `model` ditambahkan lebih dari satu kali pada Build Phases.

Hapus reference yang duplikat tanpa menghapus file fisik yang benar.

## Cache Build Lama

Pilih:

```text
Product
└── Clean Build Folder
```

atau tekan:

```text
Shift + Command + K
```

# Update FastVLM

Untuk memperbarui repository sumber:

```bash
cd ~/Downloads/ml-fastvlm
git pull
```

Bandingkan perubahan pada:

```text
app/FastVLM/FastVLM.swift
app/FastVLM/MediaProcessingExtensions.swift
```

Jangan langsung menimpa source yang sudah berjalan tanpa menguji kompatibilitas package.

Setelah source diperbarui:

1. Build project.
2. Jalankan pada perangkat fisik.
3. Uji beberapa foto tensimeter.
4. Periksa struktur JSON.
5. Commit source dan `Package.resolved` setelah seluruh pengujian berhasil.

# Referensi

* FastVLM: `https://github.com/apple/ml-fastvlm`
* MLX Swift: `https://github.com/ml-explore/mlx-swift`
* MLX Swift Examples: `https://github.com/ml-explore/mlx-swift-examples`
* Swift Transformers: `https://github.com/huggingface/swift-transformers`
