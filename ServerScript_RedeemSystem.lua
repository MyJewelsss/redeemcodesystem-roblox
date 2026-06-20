--[[
    ╔══════════════════════════════════════════════╗
    ║         REDEEM CODE SYSTEM - SERVER          ║
    ║  Lokasi: ServerScriptService > RedeemSystem  ║
    ╚══════════════════════════════════════════════╝

    STRUKTUR FOLDER:
    ├── ServerScriptService
    │   └── RedeemSystem (Script) ← FILE INI
    ├── ReplicatedStorage
    │   └── RedeemEvents (Folder)
    │       ├── RedeemCodeEvent    (RemoteEvent)
    │       └── RedeemResultEvent  (RemoteEvent)
    └── StarterGui
        └── RedeemUI (ScreenGui) ← Lihat LocalScript
--]]

-- ═══════════════════════════════════════════
--              SERVICES
-- ═══════════════════════════════════════════
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore untuk menyimpan siapa sudah redeem kode apa
local RedeemStore = DataStoreService:GetDataStore("PlayerRedeemData_v1")

-- ═══════════════════════════════════════════
--         KONFIGURASI ADMIN
-- ═══════════════════════════════════════════
local Config = {
    -- Daftar UserId yang punya akses admin
    AdminUserIds = {
        123456789,  -- Ganti dengan UserId admin kamu
        987654321,  -- Tambah lebih jika perlu
    },

    -- (Opsional) Group ID & Rank minimum untuk admin
    AdminGroup = {
        GroupId   = 0,       -- Set ke Group ID kamu (0 = nonaktif)
        MinRank   = 200,     -- Rank minimum di group
    },

    -- Prefix command admin
    CommandPrefix = "/",
}

-- ═══════════════════════════════════════════
--         DATABASE REDEEM CODE
--    (Disimpan di memory server, bisa
--     ditambah via command admin)
-- ═══════════════════════════════════════════
local RedeemCodes = {
    --[[
        Format:
        ["NAMA_KODE"] = {
            cash      = jumlah_cash,     -- Reward uang
            expMult   = persentase_exp,  -- Multiplier EXP (%)
            maxUses   = max_pemakaian,   -- 0 = unlimited
            usedCount = 0,               -- Jangan diubah
        }
    --]]

    ["WELSCOMMUNITY"] = {
        cash      = 500,
        expMult   = 150,
        maxUses   = 0,   -- 0 = unlimited players bisa redeem
        usedCount = 0,
    },
    ["LAUNCH2025"] = {
        cash      = 1000,
        expMult   = 200,
        maxUses   = 100, -- Maksimal 100 pemain
        usedCount = 0,
    },
    ["FREECASH"] = {
        cash      = 250,
        expMult   = 100,
        maxUses   = 0,
        usedCount = 0,
    },
}

-- ═══════════════════════════════════════════
--         SETUP REMOTE EVENTS
-- ═══════════════════════════════════════════
local function setupRemoteEvents()
    -- Pastikan folder Events ada di ReplicatedStorage
    local eventsFolder = ReplicatedStorage:FindFirstChild("RedeemEvents")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "RedeemEvents"
        eventsFolder.Parent = ReplicatedStorage
    end

    -- RemoteEvent: Player kirim kode → Server
    local redeemEvent = eventsFolder:FindFirstChild("RedeemCodeEvent")
    if not redeemEvent then
        redeemEvent = Instance.new("RemoteEvent")
        redeemEvent.Name = "RedeemCodeEvent"
        redeemEvent.Parent = eventsFolder
    end

    -- RemoteEvent: Server kirim hasil → Player
    local resultEvent = eventsFolder:FindFirstChild("RedeemResultEvent")
    if not resultEvent then
        resultEvent = Instance.new("RemoteEvent")
        resultEvent.Name = "RedeemResultEvent"
        resultEvent.Parent = eventsFolder
    end

    return redeemEvent, resultEvent
end

local RedeemCodeEvent, RedeemResultEvent = setupRemoteEvents()

-- ═══════════════════════════════════════════
--         UTILITY FUNCTIONS
-- ═══════════════════════════════════════════

-- Cek apakah player adalah admin
local function isAdmin(player)
    -- Cek UserId
    for _, adminId in ipairs(Config.AdminUserIds) do
        if player.UserId == adminId then
            return true
        end
    end

    -- Cek Group Rank (jika GroupId aktif)
    if Config.AdminGroup.GroupId > 0 then
        local success, rank = pcall(function()
            return player:GetRankInGroup(Config.AdminGroup.GroupId)
        end)
        if success and rank >= Config.AdminGroup.MinRank then
            return true
        end
    end

    return false
end

-- Ambil data redeem player dari DataStore
local function getPlayerRedeemData(player)
    local key = "Player_" .. player.UserId
    local success, data = pcall(function()
        return RedeemStore:GetAsync(key)
    end)

    if success and data then
        return data
    end

    -- Return tabel kosong jika belum ada data
    return {}
end

-- Simpan data redeem player ke DataStore
local function savePlayerRedeemData(player, data)
    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        RedeemStore:SetAsync(key, data)
    end)

    if not success then
        warn("[RedeemSystem] Gagal menyimpan data untuk " .. player.Name .. ": " .. tostring(err))
    end
end

-- Pastikan leaderstats dan stat yang diperlukan ada
local function ensureLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    -- Cash stat
    local cash = leaderstats:FindFirstChild("Cash")
    if not cash then
        cash = Instance.new("IntValue")
        cash.Name = "Cash"
        cash.Value = 0
        cash.Parent = leaderstats
    end

    -- EXP Multiplier stat (disimpan terpisah, bukan di leaderstats)
    local expMultiplier = player:FindFirstChild("ExpMultiplier")
    if not expMultiplier then
        expMultiplier = Instance.new("NumberValue")
        expMultiplier.Name = "ExpMultiplier"
        expMultiplier.Value = 100  -- Default 100%
        expMultiplier.Parent = player
    end

    return leaderstats, cash, expMultiplier
end

-- ═══════════════════════════════════════════
--         LOGIKA REDEEM CODE
-- ═══════════════════════════════════════════
local function processRedeem(player, codeInput)
    -- Normalisasi kode: uppercase & trim spasi
    local code = string.upper(string.gsub(codeInput, "^%s*(.-)%s*$", "%1"))

    -- Validasi: kode tidak boleh kosong
    if code == "" then
        return {
            success = false,
            message = "❌ Kode tidak boleh kosong!",
            type    = "empty",
        }
    end

    -- Cek apakah kode ada di database
    local codeData = RedeemCodes[code]
    if not codeData then
        return {
            success = false,
            message = "❌ Kode \"" .. code .. "\" tidak ditemukan atau sudah kadaluarsa.",
            type    = "invalid",
        }
    end

    -- Cek batas penggunaan kode (jika maxUses > 0)
    if codeData.maxUses > 0 and codeData.usedCount >= codeData.maxUses then
        return {
            success = false,
            message = "⚠️ Kode ini sudah mencapai batas penggunaan maksimal!",
            type    = "maxed",
        }
    end

    -- Cek apakah player sudah pernah redeem kode ini
    local redeemData = getPlayerRedeemData(player)
    if redeemData[code] then
        return {
            success = false,
            message = "⚠️ Kamu sudah pernah menggunakan kode ini sebelumnya!",
            type    = "already_used",
        }
    end

    -- ✅ SEMUA CEK LULUS → Berikan reward
    local _, cashStat, expMultStat = ensureLeaderstats(player)

    -- Tambah Cash
    cashStat.Value = cashStat.Value + codeData.cash

    -- Tambah EXP Multiplier (akumulasi di atas base 100%)
    expMultStat.Value = expMultStat.Value + (codeData.expMult - 100)

    -- Tandai kode sudah digunakan oleh player ini
    redeemData[code] = true
    savePlayerRedeemData(player, redeemData)

    -- Update counter penggunaan kode
    codeData.usedCount = codeData.usedCount + 1

    print(string.format(
        "[RedeemSystem] %s berhasil redeem kode '%s' → +$%d Cash, +%d%% EXP Mult",
        player.Name, code, codeData.cash, codeData.expMult
    ))

    return {
        success  = true,
        message  = string.format(
            "✅ Berhasil! Kamu mendapatkan:\n💰 +$%d Cash\n⚡ +%d%% EXP Multiplier",
            codeData.cash, codeData.expMult
        ),
        type     = "success",
        rewards  = {
            cash    = codeData.cash,
            expMult = codeData.expMult,
        },
    }
end

-- ═══════════════════════════════════════════
--         ADMIN COMMAND: /createredeemcode
-- ═══════════════════════════════════════════
local function handleCreateRedeemCode(player, args)
    --[[
        Format: /createredeemcode [NamaCode] [Cash] [ExpMult] (opsional:[MaxUses])
        Contoh: /createredeemcode WELSCOMMUNITY 500 150
        Contoh: /createredeemcode LIMITEDCODE 1000 200 50
    --]]

    if not isAdmin(player) then
        return  -- Abaikan jika bukan admin
    end

    -- Parsing argumen
    local codeName  = args[1]
    local cashRew   = tonumber(args[2])
    local expMult   = tonumber(args[3])
    local maxUses   = tonumber(args[4]) or 0  -- Default unlimited

    -- Validasi argumen
    if not codeName or not cashRew or not expMult then
        -- Beri tahu admin via chat system message
        game:GetService("StarterGui")  -- Tidak bisa langsung, kirim via RemoteEvent
        warn("[RedeemSystem] Command tidak lengkap dari admin " .. player.Name)

        -- Kirim feedback ke admin
        RedeemResultEvent:FireClient(player, {
            success = false,
            message = "❌ Format salah! Gunakan:\n/createredeemcode [Kode] [Cash] [ExpMult] [MaxUses opsional]",
            type    = "admin_error",
        })
        return
    end

    -- Normalisasi nama kode
    codeName = string.upper(codeName)

    -- Cek apakah kode sudah ada
    if RedeemCodes[codeName] then
        RedeemResultEvent:FireClient(player, {
            success = false,
            message = "⚠️ Kode \"" .. codeName .. "\" sudah ada di database!",
            type    = "admin_error",
        })
        return
    end

    -- Tambahkan kode baru ke database
    RedeemCodes[codeName] = {
        cash      = math.floor(cashRew),
        expMult   = math.floor(expMult),
        maxUses   = math.floor(maxUses),
        usedCount = 0,
    }

    print(string.format(
        "[RedeemSystem] Admin %s membuat kode baru: '%s' | Cash: %d | ExpMult: %d%% | MaxUses: %s",
        player.Name, codeName, cashRew, expMult,
        maxUses > 0 and tostring(maxUses) or "Unlimited"
    ))

    -- Konfirmasi ke admin
    RedeemResultEvent:FireClient(player, {
        success = true,
        message = string.format(
            "✅ [ADMIN] Kode berhasil dibuat!\n📝 Kode: %s\n💰 Cash: $%d\n⚡ ExpMult: %d%%\n👥 MaxUses: %s",
            codeName, math.floor(cashRew), math.floor(expMult),
            maxUses > 0 and tostring(math.floor(maxUses)) or "Unlimited"
        ),
        type = "admin_success",
    })
end

-- ═══════════════════════════════════════════
--         EVENT LISTENERS
-- ═══════════════════════════════════════════

-- Dengarkan request redeem dari player
RedeemCodeEvent.OnServerEvent:Connect(function(player, codeInput)
    -- Validasi tipe data
    if type(codeInput) ~= "string" then return end

    -- Batasi panjang input untuk keamanan
    if #codeInput > 50 then
        RedeemResultEvent:FireClient(player, {
            success = false,
            message = "❌ Kode terlalu panjang!",
            type    = "invalid",
        })
        return
    end

    -- Proses redeem dan kirim hasilnya
    local result = processRedeem(player, codeInput)
    RedeemResultEvent:FireClient(player, result)
end)

-- Dengarkan chat untuk admin command
Players.PlayerAdded:Connect(function(player)
    -- Setup leaderstats saat player join
    task.wait(1)  -- Tunggu sebentar agar character load
    ensureLeaderstats(player)

    -- Sambungkan event chat
    player.Chatted:Connect(function(message)
        -- Cek apakah pesan dimulai dengan prefix command
        if string.sub(message, 1, 1) ~= Config.CommandPrefix then return end

        -- Pecah pesan menjadi bagian-bagian
        local parts = {}
        for part in string.gmatch(message, "%S+") do
            table.insert(parts, part)
        end

        if #parts == 0 then return end

        -- Ambil nama command (tanpa prefix, lowercase)
        local command = string.lower(string.sub(parts[1], 2))

        -- Argumen setelah command
        local args = {}
        for i = 2, #parts do
            table.insert(args, parts[i])
        end

        -- Handle command yang dikenal
        if command == "createredeemcode" then
            handleCreateRedeemCode(player, args)

        elseif command == "listcodes" and isAdmin(player) then
            -- Bonus: /listcodes untuk melihat semua kode aktif
            local codeList = "[ADMIN] Daftar Kode Aktif:\n"
            for name, data in pairs(RedeemCodes) do
                codeList = codeList .. string.format(
                    "• %s → $%d | %d%% EXP | Used: %d/%s\n",
                    name, data.cash, data.expMult, data.usedCount,
                    data.maxUses > 0 and tostring(data.maxUses) or "∞"
                )
            end
            RedeemResultEvent:FireClient(player, {
                success = true,
                message = codeList,
                type    = "admin_info",
            })

        elseif command == "deletecode" and isAdmin(player) then
            -- Bonus: /deletecode [NamaCode]
            local targetCode = args[1] and string.upper(args[1]) or nil
            if targetCode and RedeemCodes[targetCode] then
                RedeemCodes[targetCode] = nil
                RedeemResultEvent:FireClient(player, {
                    success = true,
                    message = "✅ [ADMIN] Kode \"" .. targetCode .. "\" berhasil dihapus!",
                    type    = "admin_success",
                })
            else
                RedeemResultEvent:FireClient(player, {
                    success = false,
                    message = "❌ Kode tidak ditemukan: " .. tostring(targetCode),
                    type    = "admin_error",
                })
            end
        end
    end)
end)

print("[RedeemSystem] ✅ Server Script aktif dan siap digunakan!")
