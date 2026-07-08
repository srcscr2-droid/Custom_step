local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local IDS = {
    "rbxassetid://139725088886686",
    "rbxassetid://71106350575274",
    "rbxassetid://121456063184654",
    "rbxassetid://83112931455684",
}

warn("[STEP-DEBUG] script started")

-- 1) пробуем предзагрузить и проверить, грузятся ли ассеты
for _, id in ipairs(IDS) do
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Parent = SoundService
    local ok, err = pcall(function()
        ContentProvider:PreloadAsync({s})
    end)
    -- ждём немного и смотрим свойства
    task.wait(0.2)
    warn(string.format("[STEP-DEBUG] %s | IsLoaded=%s | Length=%s | pcall_ok=%s | err=%s",
        id, tostring(s.IsLoaded), tostring(s.TimeLength), tostring(ok), tostring(err)))
end

-- 2) принудительно проигрываем первый звук, чтобы услышать, работает ли ассет вообще
local test = Instance.new("Sound")
test.SoundId = IDS[1]
test.Volume = 1
test.Parent = SoundService
test:Play()
warn("[STEP-DEBUG] played test sound "..IDS[1].." — слышишь его?")

-- 3) показываем, какие звуки движения есть на персонаже
local function dumpCharacter(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then warn("[STEP-DEBUG] no HumanoidRootPart") return end
    warn("[STEP-DEBUG] sounds under HumanoidRootPart:")
    for _, d in ipairs(root:GetChildren()) do
        if d:IsA("Sound") then
            warn(string.format("   - %s | id=%s | vol=%s", d.Name, tostring(d.SoundId), tostring(d.Volume)))
        end
    end
end

if player.Character then dumpCharacter(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(1) dumpCharacter(c) end)
