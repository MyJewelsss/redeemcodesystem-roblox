# 🎟️ Redeem Code System — Panduan Setup Roblox

## 📁 Struktur Folder di Explorer

```
game
├── ServerScriptService
│   └── RedeemSystem          ← Script (paste isi ServerScript_RedeemSystem.lua)
│
├── ReplicatedStorage
│   └── RedeemEvents          ← Folder (dibuat OTOMATIS oleh ServerScript)
│       ├── RedeemCodeEvent   ← RemoteEvent (dibuat OTOMATIS)
│       └── RedeemResultEvent ← RemoteEvent (dibuat OTOMATIS)
│
└── StarterGui
    └── RedeemUI              ← ScreenGui
        └── LocalScript       ← paste isi LocalScript_RedeemUI.lua
```

---

## 🚀 Langkah Instalasi

### Step 1 — ServerScript
1. Buka **ServerScriptService** di Explorer
2. Klik kanan → **Insert Object** → pilih **Script**
3. Rename jadi `RedeemSystem`
4. Paste seluruh isi `ServerScript_RedeemSystem.lua` ke dalamnya

### Step 2 — ScreenGui & LocalScript
1. Buka **StarterGui** di Explorer
2. Klik kanan → **Insert Object** → pilih **ScreenGui**
3. Rename jadi `RedeemUI`
4. Klik kanan pada `RedeemUI` → **Insert Object** → pilih **LocalScript**
5. Paste seluruh isi `LocalScript_RedeemUI.lua` ke dalamnya

### Step 3 — Konfigurasi Admin
Buka `RedeemSystem` (ServerScript) dan edit bagian ini:

```lua
local Config = {
    AdminUserIds = {
        123456789,  -- ← Ganti dengan UserId
    },
    AdminGroup = {
        GroupId = 0,     -- ← Set ke Group ID (0 = nonaktif)
        MinRank = 200,   -- ← Rank minimum buat akses admin
    },
}
```

> 💡 Cara cari UserId: buka profile Roblox kalian, angka di URL adalah UserId.

---

## 🎮 Cara Penggunaan

### Player — Redeem Code
1. Klik tombol **🎁 Redeem Code** di pojok kiri bawah layar
2. Ketik kode di kotak input (contoh: `WELSCOMMUNITY`)
3. Klik **Klaim Reward** atau tekan **Enter**
4. Lihat hasil di area feedback

 Status        Deskripsi                                      

✅ Hijau      Kode valid, reward berhasil diklaim            
❌ Merah     Kode salah / tidak ditemukan                  
⚠️ Kuning    Kode sudah pernah diklaim / limit habis       

### Admin — Buat Kode Baru via Chat
Ketik di chat box Roblox:

```
/createredeemcode [NamaKode] [Cash] [ExpMultiplier] [MaxUses (opsional)]
```

**Contoh:**
```
/createredeemcode WELSCOMMUNITY 500 150
/createredeemcode LIMITEDCODE 1000 200 50
/createredeemcode FREECASH 250 100
```

### Perintah Admin Lainnya

 Command                           Fungsi                                 

 `/createredeemcode [K] [C] [E]`  Buat kode baru                        
 `/listcodes`                     Lihat semua kode aktif                
 `/deletecode [NamaKode]`         Hapus kode dari database              

---

## 💰 Kode Bawaan (Pre-loaded)

 Kode             Cash    EXP Mult  Max Uses  

 `WELSCOMMUNITY`  $500    150%      Unlimited 
 `LAUNCH2025`     $1000   200%      100x      
 `FREECASH`       $250    100%      Unlimited 

---

## ⚙️ Cara Tambah/Edit Kode di Script

Di ServerScript, cari bagian `RedeemCodes` dan tambah:

```lua
local RedeemCodes = {
    ["KODEBARU"] = {
        cash      = 300,    -- Reward uang
        expMult   = 125,    -- 125% EXP multiplier
        maxUses   = 0,      -- 0 = unlimited
        usedCount = 0,      -- Jangan diubah
    },
}
```

---

## 📊 Leaderstats yang Digunakan

 Stat             Tipe         Lokasi               Keterangan               

 `Cash`           IntValue     `player.leaderstats` Uang player              
 `ExpMultiplier`  NumberValue  `player`             Multiplier EXP (%)       

> ⚠️ Jika game kalian sudah punya leaderstats sendiri, sesuaikan nama stat di fungsi `ensureLeaderstats()` di ServerScript.

---

## 🔒 Keamanan Sistem

- ✅ Semua validasi kode dilakukan di **Server** (tidak bisa di exploit client)
- ✅ Data redeem per-player disimpan di **DataStore** (persisten antar sesi)
- ✅ Input dibatasi maksimal 50 karakter (anti spam)
- ✅ Kode di-normalisasi ke UPPERCASE sebelum dicek
- ✅ Admin command hanya bisa digunakan oleh UserId/Group yang terdaftar

---

## ❓ Troubleshooting

**Q: Panel tidak muncul saat tombol diklik**
→ Pastikan `LocalScript` ada di dalam `ScreenGui`, bukan di tempat lain.

**Q: Kode selalu "tidak ditemukan"**
→ Pastikan `ServerScript` tidak ada error di Output. Cek apakah `RedeemEvents` folder terbuat otomatis di ReplicatedStorage.

**Q: Admin command tidak bekerja**
→ Pastikan UserId di `Config.AdminUserIds` sudah benar (bukan username).

**Q: Cash tidak bertambah saat redeem**
→ Pastikan leaderstats ada. Script akan otomatis membuat leaderstats jika belum ada.
