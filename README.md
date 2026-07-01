# Blood Pressure Reader for iOS

Aplikasi iOS berbasis SwiftUI untuk mengambil atau memilih foto layar tensimeter digital, membaca nilai **systolic**, **diastolic**, dan **pulse** menggunakan FastVLM secara on-device, lalu memasukkan hasilnya ke form pencatatan tekanan darah.

> [!IMPORTANT]
> Aplikasi ini merupakan implementasi pembacaan tampilan perangkat dan bukan alat diagnosis medis. Hasil inference harus tetap dapat diperiksa dan dikoreksi oleh pengguna sebelum disimpan.

## Fitur

- Mengambil foto menggunakan kamera atau memilih gambar dari galeri.
- Memeriksa apakah gambar merupakan tensimeter digital.
- Memeriksa apakah tampilan cukup jelas untuk dibaca.
- Membaca:
  - systolic blood pressure;
  - diastolic blood pressure;
  - pulse rate.
- Mengembalikan hasil inference dalam JSON terstruktur.
- Mengisi form pencatatan tekanan darah secara otomatis.
- Inference dilakukan secara lokal pada perangkat menggunakan MLX dan FastVLM.
- Tidak memerlukan Apple Foundation Models atau koneksi ke layanan inference eksternal.

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

- macOS dengan Apple Silicon direkomendasikan.
- Xcode yang mendukung iOS 18.2 atau lebih baru.
- Deployment target: **iOS 18.2**.
- Swift language version pada project: **Swift 5**.
- Perangkat iPhone atau iPad fisik direkomendasikan.
- Ruang penyimpanan yang cukup untuk model FastVLM.
- Git dan Git LFS tidak diperlukan selama model tidak dimasukkan ke repository.

FastVLM menggunakan Metal melalui MLX. Menjalankan aplikasi pada perangkat fisik lebih representatif dibandingkan simulator, terutama untuk penggunaan memori dan performa inference.

## Dependency yang Digunakan

Project menggunakan Swift Package Manager.

| Repository | Version rule | Minimum version | Products yang digunakan |
|---|---:|---:|---|
| `https://github.com/ml-explore/mlx-swift` | Up to Next Major | `0.21.2` | `MLX`, `MLXNN`, `MLXFast`, `MLXRandom` |
| `https://github.com/ml-explore/mlx-swift-examples` | Up to Next Major | `2.21.2` | `MLXVLM`, `MLXLMCommon` |
| `https://github.com/huggingface/swift-transformers` | Up to Next Major | `0.1.18` | `Transformers` |

Versi tersebut mengikuti kombinasi dependency yang digunakan oleh demo resmi FastVLM yang menjadi dasar integrasi project ini.

> [!WARNING]
> Jangan mengganti seluruh package ke versi terbaru secara otomatis tanpa menguji ulang. Perubahan API MLX dan MLXVLM dapat menyebabkan error compile seperti perubahan tipe attention mask, perubahan `UserInput.Prompt`, atau perubahan argumen image grid.

## Struktur Project

Struktur utama project kurang lebih sebagai berikut:

```text
Blood Pressure/
├── Blood Pressure.xcodeproj/
├── Blood Pressure/
│   ├── Models/
│   │   └── OCRParsedResult.swift
│   ├── Services/
│   │   └── FastVLMBloodPressureService.swift
│   ├── Views/
│   │   └── AddReadingView.swift
│   ├── Assets.xcassets/
│   └── ...
├── Vendor/
│   └── ml-fastvlm/
├── .gitignore
├── Package.resolved
└── README.md
```

Folder `Vendor/ml-fastvlm` dan model tidak disimpan ke GitHub. Keduanya harus dibuat kembali setelah repository utama di-clone.

## Instalasi

### 1. Clone repository aplikasi

```bash
git clone <URL_REPOSITORY_APLIKASI>
cd "<NAMA_FOLDER_REPOSITORY>"
```

Buka project:

```bash
open "Blood Pressure.xcodeproj"
```

Nama file `.xcodeproj` dapat disesuaikan apabila nama project telah diubah.

### 2. Clone repository FastVLM

Dari root project aplikasi:

```bash
mkdir -p Vendor
git clone https://github.com/apple/ml-fastvlm.git Vendor/ml-fastvlm
```

Path akhirnya harus menjadi:

```text
Vendor/ml-fastvlm/app/FastVLM
```

Project Xcode yang sudah dikonfigurasi akan menggunakan source FastVLM dari lokasi tersebut.

Apabila Xcode menampilkan file FastVLM berwarna merah, periksa bahwa folder hasil clone benar-benar berada pada path relatif yang sama.

### 3. Download model FastVLM 0.5B

Berikan permission executable pada script:

```bash
chmod +x Vendor/ml-fastvlm/app/get_pretrained_mlx_model.sh
```

Download model:

```bash
Vendor/ml-fastvlm/app/get_pretrained_mlx_model.sh \
  --model 0.5b \
  --dest Vendor/ml-fastvlm/app/FastVLM/model
```

Setelah selesai, struktur berikut harus tersedia:

```text
Vendor/ml-fastvlm/app/FastVLM/model/
```

Model `0.5b` dipilih karena lebih sesuai untuk penggunaan mobile dibandingkan varian 1.5B atau 7B.

Model tidak dimasukkan ke GitHub karena ukurannya besar dan memiliki ketentuan lisensi tersendiri.

### 4. Tambahkan Swift Package Dependencies

Di Xcode:

1. Pilih project pada Project Navigator.
2. Pilih tab **Package Dependencies**.
3. Tekan tombol **+**.
4. Tambahkan package berikut satu per satu.

#### MLX Swift

Repository:

```text
https://github.com/ml-explore/mlx-swift
```

Dependency Rule:

```text
Up to Next Major Version
Minimum: 0.21.2
```

Tambahkan products berikut ke target yang menggunakan FastVLM:

```text
MLX
MLXNN
MLXFast
MLXRandom
```

#### MLX Swift Examples

Repository:

```text
https://github.com/ml-explore/mlx-swift-examples
```

Dependency Rule:

```text
Up to Next Major Version
Minimum: 2.21.2
```

Tambahkan products:

```text
MLXVLM
MLXLMCommon
```

#### Swift Transformers

Repository:

```text
https://github.com/huggingface/swift-transformers
```

Dependency Rule:

```text
Up to Next Major Version
Minimum: 0.1.18
```

Tambahkan product:

```text
Transformers
```

Setelah package selesai di-resolve, pastikan file `Package.resolved` ikut di-commit. File tersebut mengunci versi dependency aktual yang sudah terbukti dapat di-build pada project.

### 5. Periksa Target Membership

Pilih source FastVLM dan service yang digunakan aplikasi, lalu buka File Inspector.

Pastikan file yang diperlukan memiliki Target Membership pada target aplikasi atau framework yang sesuai.

Source utama yang harus tersedia mencakup implementasi FastVLM dan file berikut pada aplikasi:

```text
Blood Pressure/Services/FastVLMBloodPressureService.swift
```

Service tersebut menggunakan module berikut:

```swift
import MLX
import MLXLMCommon
import MLXRandom
import MLXVLM
import UIKit
```

FastVLM dimuat melalui:

```swift
VLMModelFactory.shared.loadContainer(
    configuration: FastVLM.modelConfiguration
)
```

### 6. Atur Deployment Target

Di Xcode:

```text
Project
└── Targets
    └── Blood Pressure
        └── General
            └── Minimum Deployments
                └── iOS 18.2
```

Lakukan pemeriksaan yang sama pada target framework FastVLM apabila framework tersebut dipisahkan dari target aplikasi.

Nilai deployment target target aplikasi dan framework sebaiknya konsisten untuk mencegah error linking.

### 7. Tambahkan Camera Permission

Pada target aplikasi, buka tab **Info** dan tambahkan:

```text
Privacy - Camera Usage Description
```

Contoh value:

```text
Kamera digunakan untuk mengambil foto tampilan tensimeter.
```

Apabila project menggunakan `Info.plist` manual, key yang digunakan adalah:

```xml
<key>NSCameraUsageDescription</key>
<string>Kamera digunakan untuk mengambil foto tampilan tensimeter.</string>
```

### 8. Pilih Signing Team

Di Xcode:

```text
Target
└── Signing & Capabilities
    ├── Automatically manage signing: Enabled
    ├── Team: akun Apple Developer Anda
    └── Bundle Identifier: identifier unik
```

Contoh bundle identifier:

```text
com.example.BloodPressure
```

### 9. Resolve Package

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

### 10. Build dan Jalankan

Pilih perangkat iPhone fisik, kemudian:

```text
Product
└── Build
```

atau tekan:

```text
Command + B
```

Jalankan aplikasi:

```text
Command + R
```

Inference pertama dapat terasa lebih lambat karena model perlu dimuat ke memory. Instance `ModelContainer` kemudian disimpan oleh service agar tidak dimuat ulang untuk setiap foto.

## Konfigurasi Inference

Implementasi saat ini menggunakan pengaturan deterministik:

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

Pengaturan tersebut dibuat agar input aplikasi konsisten dengan pipeline demo FastVLM.

## Prompt Pembacaan Tensimeter

Prompt harus memperlakukan gambar sebagai satu-satunya sumber kebenaran dan tidak boleh menggunakan nilai tekanan darah yang dianggap normal atau umum sebagai tebakan.

Field JSON yang digunakan harus tetap sama:

```text
is_blood_pressure_monitor
is_clear
systolic
diastolic
pulse
```

Perubahan nama field harus diikuti dengan perubahan pada parser dan model `OCRParsedResult`.

## File yang Harus Di-commit

File berikut harus tetap dimasukkan ke Git:

```text
Blood Pressure.xcodeproj/project.pbxproj
Blood Pressure.xcworkspace/contents.xcworkspacedata
Package.resolved
Package.swift
*.xcodeproj/xcshareddata/xcschemes/
*.xcworkspace/xcshareddata/xcschemes/
source code Swift
Assets.xcassets
README.md
.gitignore
```

Khususnya, jangan menambahkan pola berikut ke `.gitignore`:

```gitignore
*.pbxproj
*.xcodeproj/
*.xcworkspace/
Package.resolved
```

Mengabaikan `project.pbxproj` akan menyebabkan perubahan file, target membership, build settings, dan package dependencies tidak ikut tersimpan di GitHub.

## File yang Tidak Di-commit

File berikut dibuat kembali secara lokal:

```text
DerivedData/
build/
xcuserdata/
.swiftpm/
Vendor/ml-fastvlm/
FastVLM model weights
Hugging Face cache
Python virtual environment
Xcode archives
provisioning profiles
signing certificates
local secrets
```

Lihat `.gitignore` untuk daftar lengkap.

## Troubleshooting

### File `FastVLM.swift` berwarna merah

Pastikan repository FastVLM berada di:

```text
Vendor/ml-fastvlm
```

dan bukan pada folder lain.

### Model tidak ditemukan

Pastikan folder berikut tersedia:

```text
Vendor/ml-fastvlm/app/FastVLM/model
```

Jalankan kembali:

```bash
Vendor/ml-fastvlm/app/get_pretrained_mlx_model.sh \
  --model 0.5b \
  --dest Vendor/ml-fastvlm/app/FastVLM/model
```

Setelah itu, clean build folder dan build ulang.

### Package product tidak ditemukan

Periksa bahwa product berikut sudah ditambahkan ke target yang benar:

```text
MLX
MLXNN
MLXFast
MLXRandom
MLXVLM
MLXLMCommon
Transformers
```

### Error API MLX atau MLXVLM

Contoh error yang dapat muncul ketika package tidak kompatibel:

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

Solusi:

1. Periksa perubahan pada `Package.resolved`.
2. Kembalikan dependency rule ke versi yang tercantum pada README ini.
3. Reset package cache.
4. Resolve package versions.
5. Clean Build Folder.
6. Build ulang.

Jangan memperbarui hanya satu package MLX tanpa memeriksa kompatibilitas package MLX lainnya.

### Xcode memakai cache build lama

Pilih:

```text
Product
└── Clean Build Folder
```

atau tekan:

```text
Shift + Command + K
```

Apabila masih bermasalah, tutup Xcode dan hapus Derived Data untuk project tersebut.

### Build berhasil tetapi inference gagal

Periksa:

- model sudah selesai di-download;
- seluruh file model termasuk dalam resource yang dapat diakses aplikasi;
- perangkat memiliki ruang penyimpanan dan memory yang cukup;
- input gambar tidak kosong;
- service tidak dijalankan bersamaan berkali-kali;
- JSON response diperiksa sebelum dimasukkan ke form.

## Git Setup

Setelah menambahkan `.gitignore` dan `README.md`:

```bash
git status
```

Pastikan model dan folder `Vendor/ml-fastvlm` tidak muncul sebagai file yang akan di-commit.

Tambahkan file project:

```bash
git add .
git status
```

Commit:

```bash
git commit -m "Add FastVLM blood pressure reader setup"
```

Push:

```bash
git push origin main
```

## Update Dependency

Sebelum memperbarui package:

1. buat branch baru;
2. catat versi pada `Package.resolved`;
3. update package satu per satu;
4. build pada device fisik;
5. uji pembacaan beberapa foto tensimeter;
6. periksa kembali JSON output;
7. commit `Package.resolved` hanya setelah seluruh pengujian berhasil.

## Referensi

- FastVLM: `https://github.com/apple/ml-fastvlm`
- MLX Swift: `https://github.com/ml-explore/mlx-swift`
- MLX Swift Examples: `https://github.com/ml-explore/mlx-swift-examples`
- Swift Transformers: `https://github.com/huggingface/swift-transformers`

## License

Source aplikasi harus menggunakan license milik repository aplikasi ini.

FastVLM, model FastVLM, MLX, dan Swift Transformers masing-masing memiliki license sendiri. Tinjau file license dari setiap dependency sebelum mendistribusikan aplikasi atau mengunggahnya ke App Store.
