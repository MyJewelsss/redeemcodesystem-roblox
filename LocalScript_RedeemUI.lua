--[[
    ╔══════════════════════════════════════════════╗
    ║         REDEEM CODE SYSTEM - CLIENT          ║
    ║  Lokasi: StarterGui > RedeemUI > LocalScript ║
    ╚══════════════════════════════════════════════╝

    CARA SETUP UI di Explorer:
    StarterGui
    └── RedeemUI (ScreenGui)
        └── LocalScript ← FILE INI (taruh di sini)

    Script ini akan membuat seluruh UI secara otomatis
    via kode, jadi tidak perlu membuat Frame dll secara manual.
--]]

-- ═══════════════════════════════════════════
--              SERVICES
-- ═══════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════
--         TUNGGU REMOTE EVENTS SIAP
-- ═══════════════════════════════════════════
local eventsFolder    = ReplicatedStorage:WaitForChild("RedeemEvents", 10)
local RedeemCodeEvent = eventsFolder:WaitForChild("RedeemCodeEvent", 10)
local RedeemResultEvent = eventsFolder:WaitForChild("RedeemResultEvent", 10)

if not RedeemCodeEvent or not RedeemResultEvent then
    warn("[RedeemUI] Remote Events tidak ditemukan! Cek ServerScript.")
    return
end

-- ═══════════════════════════════════════════
--         KONFIGURASI WARNA & STYLE
-- ═══════════════════════════════════════════
local Theme = {
    -- Warna utama
    Primary     = Color3.fromRGB(88, 101, 242),   -- Biru/Ungu (Discord-like)
    PrimaryDark = Color3.fromRGB(66, 75, 198),
    PrimaryLight= Color3.fromRGB(120, 130, 255),

    -- Background
    BgDark      = Color3.fromRGB(18, 18, 30),
    BgPanel     = Color3.fromRGB(28, 28, 45),
    BgInput     = Color3.fromRGB(38, 38, 58),

    -- Status
    Success     = Color3.fromRGB(67, 181, 129),   -- Hijau
    Error       = Color3.fromRGB(237, 66, 69),    -- Merah
    Warning     = Color3.fromRGB(250, 166, 26),   -- Kuning

    -- Teks
    TextWhite   = Color3.fromRGB(255, 255, 255),
    TextGray    = Color3.fromRGB(180, 180, 200),
    TextDim     = Color3.fromRGB(120, 120, 145),

    -- Corner radius
    CornerMain  = UDim.new(0, 14),
    CornerBtn   = UDim.new(0, 10),
    CornerSmall = UDim.new(0, 6),
}

-- ═══════════════════════════════════════════
--         HELPER: BUAT ELEMEN UI
-- ═══════════════════════════════════════════

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerSmall
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Primary
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

local function makeTween(obj, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    )
    return TweenService:Create(obj, info, props)
end

-- ═══════════════════════════════════════════
--         BUILD UI
-- ═══════════════════════════════════════════

-- Dapatkan ScreenGui (parent dari LocalScript)
local screenGui = script.Parent
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ─────────────────────────────────────────
--  TOMBOL REDEEM (pojok kiri bawah)
-- ─────────────────────────────────────────
local redeemButton = Instance.new("TextButton")
redeemButton.Name           = "RedeemButton"
redeemButton.Size           = UDim2.new(0, 140, 0, 46)
redeemButton.Position       = UDim2.new(0, 20, 1, -80)
redeemButton.AnchorPoint    = Vector2.new(0, 1)
redeemButton.BackgroundColor3 = Theme.Primary
redeemButton.Text           = "🎁  Redeem Code"
redeemButton.TextColor3     = Theme.TextWhite
redeemButton.TextSize       = 14
redeemButton.Font           = Enum.Font.GothamBold
redeemButton.AutoButtonColor = false
redeemButton.ZIndex         = 10
redeemButton.Parent         = screenGui
makeCorner(redeemButton, Theme.CornerBtn)
makeStroke(redeemButton, Theme.PrimaryLight, 1)

-- Gradient pada tombol redeem
local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.PrimaryLight),
    ColorSequenceKeypoint.new(1, Theme.Primary),
})
btnGrad.Rotation = 90
btnGrad.Parent = redeemButton

-- ─────────────────────────────────────────
--  PANEL UTAMA (Modal)
-- ─────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name              = "RedeemPanel"
panel.Size              = UDim2.new(0, 360, 0, 0)  -- Height di-animate
panel.Position          = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint       = Vector2.new(0.5, 0.5)
panel.BackgroundColor3  = Theme.BgPanel
panel.BorderSizePixel   = 0
panel.Visible           = false
panel.ClipsDescendants  = true
panel.ZIndex            = 20
panel.Parent            = screenGui
makeCorner(panel, Theme.CornerMain)
makeStroke(panel, Theme.Primary, 1.5)

-- Shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name             = "Shadow"
shadow.Size             = UDim2.new(1, 40, 1, 40)
shadow.Position         = UDim2.new(0, -20, 0, -20)
shadow.BackgroundTransparency = 1
shadow.Image            = "rbxassetid://6014261993"  -- Shadow image
shadow.ImageColor3      = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType        = Enum.ScaleType.Slice
shadow.SliceCenter      = Rect.new(49, 49, 450, 450)
shadow.ZIndex           = 19
shadow.Parent           = panel

-- ─────────────────────────────────────────
--  HEADER PANEL
-- ─────────────────────────────────────────
local header = Instance.new("Frame")
header.Name             = "Header"
header.Size             = UDim2.new(1, 0, 0, 58)
header.Position         = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Theme.BgDark
header.BorderSizePixel  = 0
header.ZIndex           = 21
header.Parent           = panel

-- Corner hanya di atas
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = Theme.CornerMain
headerCorner.Parent = header

-- Fix corner bawah header (agar tidak rounded)
local headerFix = Instance.new("Frame")
headerFix.Size              = UDim2.new(1, 0, 0, 14)
headerFix.Position          = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3  = Theme.BgDark
headerFix.BorderSizePixel   = 0
headerFix.ZIndex            = 21
headerFix.Parent            = header

-- Ikon & Judul header
local headerIcon = Instance.new("TextLabel")
headerIcon.Text     = "🎟️"
headerIcon.Size     = UDim2.new(0, 36, 0, 36)
headerIcon.Position = UDim2.new(0, 16, 0.5, 0)
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.BackgroundTransparency = 1
headerIcon.TextSize = 22
headerIcon.Font     = Enum.Font.GothamBold
headerIcon.ZIndex   = 22
headerIcon.Parent   = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Text            = "Redeem Code"
headerTitle.Size            = UDim2.new(1, -120, 0, 28)
headerTitle.Position        = UDim2.new(0, 56, 0.5, 0)
headerTitle.AnchorPoint     = Vector2.new(0, 0.5)
headerTitle.BackgroundTransparency = 1
headerTitle.TextColor3      = Theme.TextWhite
headerTitle.TextSize        = 17
headerTitle.Font            = Enum.Font.GothamBold
headerTitle.TextXAlignment  = Enum.TextXAlignment.Left
headerTitle.ZIndex          = 22
headerTitle.Parent          = header

local headerSub = Instance.new("TextLabel")
headerSub.Text              = "Masukkan kode untuk mendapatkan reward!"
headerSub.Size              = UDim2.new(1, -120, 0, 16)
headerSub.Position          = UDim2.new(0, 56, 0.5, 14)
headerSub.AnchorPoint       = Vector2.new(0, 0.5)
headerSub.BackgroundTransparency = 1
headerSub.TextColor3        = Theme.TextDim
headerSub.TextSize          = 11
headerSub.Font              = Enum.Font.Gotham
headerSub.TextXAlignment    = Enum.TextXAlignment.Left
headerSub.ZIndex            = 22
headerSub.Parent            = header

-- Tombol tutup (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name               = "CloseBtn"
closeBtn.Size               = UDim2.new(0, 32, 0, 32)
closeBtn.Position           = UDim2.new(1, -12, 0.5, 0)
closeBtn.AnchorPoint        = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3   = Color3.fromRGB(237, 66, 69)
closeBtn.Text               = "✕"
closeBtn.TextColor3         = Theme.TextWhite
closeBtn.TextSize           = 14
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.AutoButtonColor    = false
closeBtn.ZIndex             = 23
closeBtn.Parent             = header
makeCorner(closeBtn, UDim.new(1, 0))  -- Lingkaran penuh

-- ─────────────────────────────────────────
--  KONTEN PANEL
-- ─────────────────────────────────────────
local content = Instance.new("Frame")
content.Name            = "Content"
content.Size            = UDim2.new(1, 0, 1, -58)
content.Position        = UDim2.new(0, 0, 0, 58)
content.BackgroundTransparency = 1
content.ZIndex          = 21
content.Parent          = panel

-- Label "Kode Redeem"
local inputLabel = Instance.new("TextLabel")
inputLabel.Text         = "Kode Redeem"
inputLabel.Size         = UDim2.new(1, -40, 0, 18)
inputLabel.Position     = UDim2.new(0, 20, 0, 20)
inputLabel.BackgroundTransparency = 1
inputLabel.TextColor3   = Theme.TextGray
inputLabel.TextSize     = 12
inputLabel.Font         = Enum.Font.GothamSemibold
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.ZIndex       = 22
inputLabel.Parent       = content

-- Input Box Container
local inputContainer = Instance.new("Frame")
inputContainer.Name             = "InputContainer"
inputContainer.Size             = UDim2.new(1, -40, 0, 46)
inputContainer.Position         = UDim2.new(0, 20, 0, 44)
inputContainer.BackgroundColor3 = Theme.BgInput
inputContainer.BorderSizePixel  = 0
inputContainer.ZIndex           = 22
inputContainer.Parent           = content
makeCorner(inputContainer, Theme.CornerBtn)
local inputStroke = makeStroke(inputContainer, Theme.TextDim, 1)

-- TextBox input kode
local codeInput = Instance.new("TextBox")
codeInput.Name              = "CodeInput"
codeInput.Size              = UDim2.new(1, -16, 1, 0)
codeInput.Position          = UDim2.new(0, 8, 0, 0)
codeInput.BackgroundTransparency = 1
codeInput.PlaceholderText   = "Contoh: WELSCOMMUNITY"
codeInput.PlaceholderColor3 = Theme.TextDim
codeInput.Text              = ""
codeInput.TextColor3        = Theme.TextWhite
codeInput.TextSize          = 15
codeInput.Font              = Enum.Font.GothamSemibold
codeInput.ClearTextOnFocus  = false
codeInput.ZIndex            = 23
codeInput.Parent            = inputContainer

-- Focus/Unfocus border effect
codeInput.Focused:Connect(function()
    makeTween(inputStroke, {Color = Theme.Primary}, 0.2):Play()
    makeTween(inputContainer, {BackgroundColor3 = Color3.fromRGB(45, 45, 68)}, 0.2):Play()
end)
codeInput.FocusLost:Connect(function()
    makeTween(inputStroke, {Color = Theme.TextDim}, 0.2):Play()
    makeTween(inputContainer, {BackgroundColor3 = Theme.BgInput}, 0.2):Play()
end)

-- Divider
local divider = Instance.new("Frame")
divider.Size            = UDim2.new(1, -40, 0, 1)
divider.Position        = UDim2.new(0, 20, 0, 104)
divider.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
divider.BorderSizePixel = 0
divider.ZIndex          = 22
divider.Parent          = content

-- Tombol SUBMIT
local submitBtn = Instance.new("TextButton")
submitBtn.Name              = "SubmitBtn"
submitBtn.Size              = UDim2.new(1, -40, 0, 46)
submitBtn.Position          = UDim2.new(0, 20, 0, 118)
submitBtn.BackgroundColor3  = Theme.Primary
submitBtn.Text              = "🎁  Klaim Reward"
submitBtn.TextColor3        = Theme.TextWhite
submitBtn.TextSize          = 15
submitBtn.Font              = Enum.Font.GothamBold
submitBtn.AutoButtonColor   = false
submitBtn.ZIndex            = 22
submitBtn.Parent            = content
makeCorner(submitBtn, Theme.CornerBtn)

-- Gradient tombol submit
local submitGrad = Instance.new("UIGradient")
submitGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.PrimaryLight),
    ColorSequenceKeypoint.new(1, Theme.Primary),
})
submitGrad.Rotation = 90
submitGrad.Parent = submitBtn

-- ─────────────────────────────────────────
--  FEEDBACK / STATUS AREA
-- ─────────────────────────────────────────
local feedbackFrame = Instance.new("Frame")
feedbackFrame.Name              = "FeedbackFrame"
feedbackFrame.Size              = UDim2.new(1, -40, 0, 0)  -- Collapsed default
feedbackFrame.Position          = UDim2.new(0, 20, 0, 176)
feedbackFrame.BackgroundColor3  = Color3.fromRGB(38, 38, 58)
feedbackFrame.BorderSizePixel   = 0
feedbackFrame.ClipsDescendants  = true
feedbackFrame.ZIndex            = 22
feedbackFrame.Parent            = content
makeCorner(feedbackFrame, Theme.CornerSmall)
local feedbackStroke = makeStroke(feedbackFrame, Theme.Primary, 1)

local feedbackText = Instance.new("TextLabel")
feedbackText.Name           = "FeedbackText"
feedbackText.Size           = UDim2.new(1, -20, 1, 0)
feedbackText.Position       = UDim2.new(0, 10, 0, 0)
feedbackText.BackgroundTransparency = 1
feedbackText.TextColor3     = Theme.TextWhite
feedbackText.TextSize       = 13
feedbackText.Font           = Enum.Font.Gotham
feedbackText.TextXAlignment = Enum.TextXAlignment.Left
feedbackText.TextYAlignment = Enum.TextYAlignment.Center
feedbackText.TextWrapped    = true
feedbackText.ZIndex         = 23
feedbackText.Parent         = feedbackFrame

-- ═══════════════════════════════════════════
--         ANIMASI & STATE MANAGEMENT
-- ═══════════════════════════════════════════

local PANEL_OPEN_HEIGHT    = 270  -- Height panel saat terbuka
local PANEL_FEEDBACK_HEIGHT = 326 -- Height panel saat ada feedback

local isOpen       = false
local isSubmitting = false

-- Fungsi: Tampilkan/sembunyikan feedback
local function showFeedback(message, feedbackType)
    local color = Theme.Primary
    local bgColor = Color3.fromRGB(30, 30, 55)

    if feedbackType == "success" or feedbackType == "admin_success" or feedbackType == "admin_info" then
        color   = Theme.Success
        bgColor = Color3.fromRGB(25, 50, 35)
    elseif feedbackType == "error" or feedbackType == "invalid" or feedbackType == "empty" or feedbackType == "admin_error" then
        color   = Theme.Error
        bgColor = Color3.fromRGB(55, 25, 25)
    elseif feedbackType == "already_used" or feedbackType == "maxed" or feedbackType == "warning" then
        color   = Theme.Warning
        bgColor = Color3.fromRGB(55, 45, 15)
    end

    feedbackText.Text = message
    makeTween(feedbackStroke, {Color = color}, 0.2):Play()
    makeTween(feedbackFrame, {BackgroundColor3 = bgColor}, 0.2):Play()
    feedbackText.TextColor3 = color

    -- Expand feedback frame
    makeTween(feedbackFrame, {Size = UDim2.new(1, -40, 0, 64)}, 0.3):Play()

    -- Expand panel
    makeTween(panel, {Size = UDim2.new(0, 360, 0, PANEL_FEEDBACK_HEIGHT)}, 0.3):Play()
end

local function hideFeedback()
    makeTween(feedbackFrame, {Size = UDim2.new(1, -40, 0, 0)}, 0.2):Play()
    makeTween(panel, {Size = UDim2.new(0, 360, 0, PANEL_OPEN_HEIGHT)}, 0.2):Play()
end

-- Fungsi: Buka panel
local function openPanel()
    if isOpen then return end
    isOpen = true

    panel.Size    = UDim2.new(0, 360, 0, 0)
    panel.Visible = true

    -- Animate buka
    makeTween(panel, {Size = UDim2.new(0, 360, 0, PANEL_OPEN_HEIGHT)}, 0.35,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

    -- Delay focus ke input
    task.delay(0.3, function()
        codeInput:CaptureFocus()
    end)
end

-- Fungsi: Tutup panel
local function closePanel()
    if not isOpen then return end
    isOpen = false

    hideFeedback()

    local tween = makeTween(panel, {Size = UDim2.new(0, 360, 0, 0)}, 0.25,
        Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    tween:Play()
    tween.Completed:Connect(function()
        panel.Visible = false
        codeInput.Text = ""
    end)
end

-- Fungsi: Submit kode
local function submitCode()
    if isSubmitting then return end

    local code = codeInput.Text
    if code == "" or code == nil then
        showFeedback("❌ Masukkan kode terlebih dahulu!", "error")
        return
    end

    -- State: loading
    isSubmitting = true
    submitBtn.Text  = "⏳  Memproses..."
    submitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    hideFeedback()

    -- Kirim ke server
    RedeemCodeEvent:FireServer(code)
end

-- ═══════════════════════════════════════════
--         TERIMA HASIL DARI SERVER
-- ═══════════════════════════════════════════
RedeemResultEvent.OnClientEvent:Connect(function(result)
    -- Reset tombol submit
    isSubmitting = false
    submitBtn.Text = "🎁  Klaim Reward"

    -- Restore gradient
    makeTween(submitBtn, {BackgroundColor3 = Theme.Primary}, 0.2):Play()

    if not result then return end

    -- Tampilkan feedback
    showFeedback(result.message, result.type)

    -- Jika sukses, kosongkan input
    if result.success and (result.type == "success") then
        codeInput.Text = ""

        -- Auto-tutup panel setelah beberapa detik (opsional)
        task.delay(4, function()
            if isOpen then
                closePanel()
            end
        end)
    end
end)

-- ═══════════════════════════════════════════
--         BUTTON INTERACTIONS
-- ═══════════════════════════════════════════

-- Tombol Redeem (pojok layar) - Buka/Tutup panel
redeemButton.MouseButton1Click:Connect(function()
    if isOpen then
        closePanel()
    else
        openPanel()
    end
end)

-- Hover effect tombol redeem
redeemButton.MouseEnter:Connect(function()
    makeTween(redeemButton, {BackgroundColor3 = Theme.PrimaryLight}, 0.15):Play()
    makeTween(redeemButton, {Size = UDim2.new(0, 148, 0, 48)}, 0.15):Play()
end)
redeemButton.MouseLeave:Connect(function()
    makeTween(redeemButton, {BackgroundColor3 = Theme.Primary}, 0.15):Play()
    makeTween(redeemButton, {Size = UDim2.new(0, 140, 0, 46)}, 0.15):Play()
end)

-- Tombol Tutup (X)
closeBtn.MouseButton1Click:Connect(function()
    closePanel()
end)

-- Hover effect tombol X
closeBtn.MouseEnter:Connect(function()
    makeTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}, 0.15):Play()
end)
closeBtn.MouseLeave:Connect(function()
    makeTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(237, 66, 69)}, 0.15):Play()
end)

-- Tombol Submit
submitBtn.MouseButton1Click:Connect(function()
    submitCode()
end)

-- Hover effect submit
submitBtn.MouseEnter:Connect(function()
    if not isSubmitting then
        makeTween(submitBtn, {BackgroundColor3 = Theme.PrimaryDark}, 0.15):Play()
    end
end)
submitBtn.MouseLeave:Connect(function()
    if not isSubmitting then
        makeTween(submitBtn, {BackgroundColor3 = Theme.Primary}, 0.15):Play()
    end
end)

-- Submit juga saat tekan Enter di TextBox
codeInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitCode()
    end
end)

-- Tutup panel saat klik di luar (area gelap)
local overlay = Instance.new("TextButton")
overlay.Name            = "Overlay"
overlay.Size            = UDim2.new(1, 0, 1, 0)
overlay.BackgroundTransparency = 1
overlay.Text            = ""
overlay.ZIndex          = 15
overlay.Parent          = screenGui
overlay.Visible         = false

-- Toggle overlay saat panel buka/tutup (agar bisa klik di luar)
-- Untuk kesederhanaan, pakai shortcut keyboard ESC saja
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Escape and isOpen then
        closePanel()
    end
end)

print("[RedeemUI] ✅ LocalScript & UI berhasil dimuat!")
