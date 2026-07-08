local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local STEP_SOUNDS = {
    "rbxassetid://139725088886686", -- pl_step1
    "rbxassetid://71106350575274",  -- pl_step2
    "rbxassetid://121456063184654", -- pl_step3
    "rbxassetid://83112931455684",  -- pl_step4
}
local JUMP_SOUND = "rbxassetid://139725088886686" -- отдельного звука прыжка нет

local STEP_VOLUME = 0.5
local JUMP_VOLUME = 0.6

-- длина одного шага в студах. Чем меньше — тем чаще шаги на той же скорости.
local STRIDE = 4.2
local MIN_INTERVAL = 0.12   -- быстрее этого шаги не пойдут (защита от спама)
local MAX_INTERVAL = 0.6    -- медленнее этого — тоже стоп

-- имена звуков, которые считаем "звуками движения" и глушим
local MOVEMENT_SOUND_NAMES = {
    Running = true, Jumping = true, Landing = true,
    Climbing = true, Swimming = true, FreeFalling = true, GettingUp = true,
}
-- ключевые слова в имени кастомного звука шага
local function looksLikeStep(name)
    name = string.lower(name)
    return string.find(name, "step") or string.find(name, "foot")
        or string.find(name, "walk") or string.find(name, "run")
end

local function playSound(parent, id, volume)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume
    s.Parent = parent
    s:Play()
    Debris:AddItem(s, 5)
end

local lastIndex = 0
local function randomStep()
    local idx = math.random(1, #STEP_SOUNDS)
    while #STEP_SOUNDS > 1 and idx == lastIndex do
        idx = math.random(1, #STEP_SOUNDS)
    end
    lastIndex = idx
    return STEP_SOUNDS[idx]
end

local function setup(character)
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    -- === ГЛУШИЛКА: заглушаем любой звук движения (стандартный/кастомный) ===
    local function killMovementSound(inst)
        if inst:IsA("Sound") and (MOVEMENT_SOUND_NAMES[inst.Name] or looksLikeStep(inst.Name)) then
            inst.Volume = 0
            -- если игра пытается вернуть громкость — держим на нуле
            inst:GetPropertyChangedSignal("Volume"):Connect(function()
                if inst.Volume > 0 then inst.Volume = 0 end
            end)
        end
    end
    for _, d in ipairs(character:GetDescendants()) do killMovementSound(d) end
    character.DescendantAdded:Connect(killMovementSound)

    -- === ПРЫЖОК ===
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            playSound(root, JUMP_SOUND, JUMP_VOLUME)
        end
    end)

    -- === ШАГИ: частота пропорциональна скорости ===
    local stepTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        if not character.Parent or humanoid.Health <= 0 then return end
        local state = humanoid:GetState()
        local grounded = state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics

        -- горизонтальная скорость (без учёта падения/прыжка)
        local v = root.AssemblyLinearVelocity
        local speed = Vector3.new(v.X, 0, v.Z).Magnitude

        if grounded and speed > 1.5 then
            stepTimer = stepTimer - dt
            if stepTimer <= 0 then
                -- интервал = длина шага / скорость -> быстрее бежишь, чаще шаги
                stepTimer = math.clamp(STRIDE / speed, MIN_INTERVAL, MAX_INTERVAL)
                playSound(root, randomStep(), STEP_VOLUME)
            end
        else
            stepTimer = 0
        end
    end)
end

if player.Character then setup(player.Character) end
player.CharacterAdded:Connect(setup)
