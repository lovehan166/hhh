local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- ==================== 原生通知（不依赖UI库） ====================
local function notify(title, text, dur)
        pcall(function()
                StarterGui:SetCore("SendNotification", {
                        Title = title,
                        Text = text,
                        Duration = dur or 5,
                })
        end)
end

-- ==================== 多源加载 WindUI（Boreal优先，2026-10实测镜像） ====================
notify("JBS 鸡巴骚", "正在加载UI库...", 3)

local WindUI
local SOURCES = {
        -- 你的Boreal库（仓库实际文件名是 WindUI-Shiny.lua，走国内可达镜像）
        { name = "Boreal", url = "https://ghfast.top/https://raw.githubusercontent.com/jonathabejose-alt/Wind-UI-Boreal/main/WindUI-Shiny.lua" },
        { name = "Boreal备用1", url = "https://gh-proxy.com/https://raw.githubusercontent.com/jonathabejose-alt/Wind-UI-Boreal/main/WindUI-Shiny.lua" },
        { name = "Boreal备用2", url = "https://ghproxy.net/https://raw.githubusercontent.com/jonathabejose-alt/Wind-UI-Boreal/main/WindUI-Shiny.lua" },
        -- 标准WindUI备用（Footagesus release v1.6.65）
        { name = "标准版1", url = "https://ghproxy.net/https://github.com/Footagesus/WindUI/releases/latest/download/main.lua" },
        { name = "标准版2", url = "https://gh-proxy.com/https://github.com/Footagesus/WindUI/releases/latest/download/main.lua" },
        { name = "标准版3", url = "https://ghfast.top/https://github.com/Footagesus/WindUI/releases/latest/download/main.lua" },
        -- 直连兜底（有代理/直连网络时走这条）
        { name = "直连", url = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua" },
}
for _, src in ipairs(SOURCES) do
        local ok, result = pcall(function()
                local code = game:HttpGet(src.url)
                assert(type(code) == "string" and #code > 500, "下载内容为空")
                return loadstring(code)()
        end)
        if ok and type(result) == "table" and result.CreateWindow then
                WindUI = result
                notify("JBS 鸡巴骚", "UI库加载成功(" .. src.name .. ")", 3)
                break
        else
                print("[JBS] UI源 " .. src.name .. " 失败，尝试下一个...")
        end
end
if not WindUI then
        notify("JBS 鸡巴骚", "UI库全部加载失败(已尝试"..#SOURCES.."个镜像源)，请检查网络或更换节点", 8)
        return
end

-- ==================== 主保护 ====================
local okMain, errMain = pcall(function()

-- ==================== 游戏对象（带超时） ====================
local rEvents = ReplicatedStorage:WaitForChild("rEvents", 15)
local rebirthRemote = rEvents and rEvents:WaitForChild("rebirthRemote", 10) or nil
local muscleEvent = player:WaitForChild("muscleEvent", 10)
local leaderstats = player:WaitForChild("leaderstats", 10)
local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") or nil
local strengthStat = leaderstats and leaderstats:FindFirstChild("Strength") or nil

-- 宠物商店对象：rEvents.cPetShopRemote + shared.runtime.cPetShopFolder
local cPetShopRemote = rEvents and rEvents:FindFirstChild("cPetShopRemote", 3)
local sharedFolder = ReplicatedStorage:FindFirstChild("shared", 5)
local runtimeFolder = sharedFolder and sharedFolder:FindFirstChild("runtime", 5)
local cPetShopFolder = runtimeFolder and runtimeFolder:FindFirstChild("cPetShopFolder", 5)

task.spawn(function()
        task.wait(0.5)
        local missing = {}
        if not rEvents then table.insert(missing, "rEvents") end
        if not rebirthRemote then table.insert(missing, "rebirthRemote") end
        if not muscleEvent then table.insert(missing, "muscleEvent") end
        if not cPetShopRemote or not cPetShopFolder then table.insert(missing, "宠物商店") end
        if #missing > 0 then
                WindUI:Notify({
                        Title = "部分功能不可用",
                        Content = "未找到: " .. table.concat(missing, ", "),
                        Duration = 8,
                })
        end
end)

-- ==================== 状态 ====================
_G.auto_train = false    -- 自动锻炼
_G.auto_rebirth = false  -- 自动重生
_G.auto_wheel = false    -- 自动轮盘
_G.auto_petbuy = false   -- 自动买宠物
_G.auto_packrebirth = false -- 换包重生
_G.auto_eategg = false    -- 自动吃蛋
_G.auto_fasttrain = false  -- 快速锻炼(极速自适应)
_G.auto_boss = false     -- 自动打Boss
local rbTarget = 0       -- 重生目标次数(0=无限)
local giftAmount = 0     -- 送蛋数量(0=全部)

local trainThread, rebirthThread, wheelThread, petbuyThread
local packrebirthThread
local eateggThread
local fasttrainThread
local bossPunchThread, bossScanThread, bossChestThread
local bossHoverConn

local function stop(t)
        if t then
                pcall(function() task.cancel(t) end)
        end
end

-- ==================== 反挂机（双保险） ====================
player.Idled:Connect(function()
        -- 方式1：按键模拟(部分执行器上更稳)
        pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
        end)
        -- 方式2：鼠标模拟
        pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
end)

-- ==================== 窗口 ====================
local Window = WindUI:CreateWindow({
        Title = "JBS 鸡巴骚",
        Author = "v3.1",
        Folder = "JBS_V3",
        Icon = "sparkles",
        IconThemed = true,
        Theme = "Midnight",
        Size = UDim2.fromOffset(560, 400),
        Transparent = false,
        Acrylic = false,
        SideBarWidth = 200,
        ScrollBarEnabled = true,
        HideSearchBar = false,
        Resizable = true,
})

local MainTab = Window:Tab({ Title = "主要", Icon = "zap", ShowTabTitle = true })
local TeleportTab = Window:Tab({ Title = "传送", Icon = "map-pin", ShowTabTitle = true })
local PetTab = Window:Tab({ Title = "宠物", Icon = "cat", ShowTabTitle = true })
local BossTab = Window:Tab({ Title = "Boss", Icon = "skull", ShowTabTitle = true })
local PackTab = Window:Tab({ Title = "换包重生", Icon = "refresh", ShowTabTitle = true })

-- ==================== 功能：自动锻炼 ====================
local function autoTrainLoop()
        while _G.auto_train do
                pcall(function()
                        muscleEvent:FireServer("rep")
                end)
                task.wait(0.1)
        end
end

-- ==================== 功能：自动重生（可设目标次数） ====================
local function autoRebirthLoop()
        while _G.auto_rebirth do
                pcall(function()
                        -- 达到目标次数自动停止
                        if rbTarget > 0 and rebirths and rebirths.Value >= rbTarget then
                                _G.auto_rebirth = false
                                WindUI:Notify({
                                        Title = "重生完成",
                                        Content = "已达到目标次数 " .. rbTarget .. "，自动重生已停止",
                                        Duration = 4,
                                })
                                return
                        end
                        if rebirthRemote then
                                if rebirthRemote:IsA("RemoteFunction") then
                                        rebirthRemote:InvokeServer("rebirthRequest")
                                else
                                        rebirthRemote:FireServer("rebirthRequest")
                                end
                        end
                end)
                task.wait(0.5)
        end
end

-- ==================== 功能：自动轮盘（幸运抽奖） ====================
local function autoWheelLoop()
        while _G.auto_wheel do
                pcall(function()
                        local remote = rEvents and rEvents:FindFirstChild("openFortuneWheelRemote")
                        local shared = ReplicatedStorage:FindFirstChild("shared")
                        local catalogs = shared and shared:FindFirstChild("catalogs")
                        local wheelChances = catalogs and catalogs:FindFirstChild("fortuneWheelChances")
                        local wheel = wheelChances and wheelChances:FindFirstChild("Fortune Wheel")
                        if remote and wheel then
                                if remote:IsA("RemoteFunction") then
                                        remote:InvokeServer("openFortuneWheel", wheel)
                                else
                                        remote:FireServer("openFortuneWheel", wheel)
                                end
                        end
                end)
                task.wait(1)
        end
end

-- ==================== 功能：买宠物 ====================
-- 购买：cPetShopFolder:FindFirstChild(宠物名) -> cPetShopRemote:InvokeServer(宠物对象)
-- 反编译把参数丢成了FindFirstChild(nil)，此处用下拉选择的名字重建

-- 内置宠物/光环列表（动态读取失败时的兜底）
local FALLBACK_PETS = {
        "不稳定幻影", "以太仙灵小兔", "伏特爪", "冰波传奇企鹅", "反应堆兽",
        "地狱火", "地狱火龙", "大超新星", "幻影创世龙", "星界电光",
        "暗星猎人", "核心小狗", "橙色刺猬", "橙色飞马", "永恒巨型攻击",
        "永恒打击利维坦", "熵爆炸", "电光", "白色凤凰", "白色飞马",
        "等离子掠夺者", "紫色光环", "紫色新环", "紫色猎鹰", "紫色龙",
        "红色光环", "红色小猫", "红色火龙", "红色释火者", "终极超新星飞马",
        "绿色光环", "绿色蝴蝶", "绿色释火者", "肌肉之王", "肌肉老师",
        "能量闪电", "蓝色光环", "蓝色凤凰", "顶峰霸主", "魔法蝴蝶",
        "黄色光环", "黄色蝴蝶", "黄金维金人", "黑暗德古拉", "黑暗电光",
        "黑暗蝎尾怪传奇", "黑暗闪电", "黑暗风暴", "黑暗魔像",
}

-- 动态获取商店宠物列表（优先游戏内实时列表，失败回退内置列表）
local function getPetShopList()
        local names = {}
        pcall(function()
                local shared = ReplicatedStorage:FindFirstChild("shared")
                local runtime = shared and shared:FindFirstChild("runtime")
                local folder = runtime and runtime:FindFirstChild("cPetShopFolder")
                if folder then
                        for _, item in ipairs(folder:GetChildren()) do
                                table.insert(names, item.Name)
                        end
                end
        end)
        if #names == 0 then
                names = FALLBACK_PETS
        end
        table.sort(names)
        return names
end

-- 购买一只宠物，返回 成功标志, 提示信息
local function buyPet(name)
        if not cPetShopRemote or not cPetShopFolder then
                return false, "未找到宠物商店对象(游戏可能未加载完)"
        end
        if not name or name == "" then
                return false, "请先选择宠物"
        end
        local pet = cPetShopFolder:FindFirstChild(name)
        if not pet then
                return false, "商店里没有: " .. name
        end
        if cPetShopRemote:IsA("RemoteFunction") then
                cPetShopRemote:InvokeServer(pet)
        else
                cPetShopRemote:FireServer(pet)
        end
        return true, "已购买: " .. name
end

-- 自动购买循环（每0.5秒一次）
local selectedPet = ""
local function autoPetBuyLoop()
        while _G.auto_petbuy do
                pcall(function()
                        if selectedPet ~= "" then
                                buyPet(selectedPet)
                        end
                end)
                task.wait(0.5)
        end
end

-- ==================== 功能：自动打Boss（多Boss轮换版） ====================
-- 机制：自动扫描Boss1~5哪只存活 -> 悬停头顶俯视连拳(每帧锁位)
--       + 出拳冷却破解 + 本地出拳动画 + 宝箱自动开启 + 无Boss时待机点等刷新
local BOSS_NAMES = { "Boss1", "Boss2", "Boss3", "Boss4", "Boss5" }
local BOSS_IDLE_POS = Vector3.new(1, 44, -1251)
local bossCurrent = "Boss1"
local bossHeight = 70

-- 出拳动画资源(左手/右手)
local PUNCH_ANIMS = {
        left  = "rbxassetid://3638729053",
        right = "rbxassetid://3638767427",
}

-- 找Boss竞技场指定Boss的对象
local function findBossModel(bossName)
        local events = workspace:FindFirstChild("Events")
        local arena = events and events:FindFirstChild("BossArena")
        local holder = arena and arena:FindFirstChild(bossName or bossCurrent)
        return holder and holder:FindFirstChild("Boss")
end

-- Boss是否存活(Model看血量 / Part看透明度)
local function isBossAlive(bossName)
        local boss = findBossModel(bossName)
        if not boss then
                return false
        end
        if boss:IsA("Model") then
                local hum = boss:FindFirstChildOfClass("Humanoid")
                return hum ~= nil and hum.Health > 0
        end
        return boss:IsA("BasePart") and boss.Transparency < 1
end

-- Boss当前位置
local function getBossPos()
        local boss = findBossModel()
        if not boss then
                return nil
        end
        if boss:IsA("Model") then
                return boss:GetPivot().Position
        end
        return boss.Position
end

-- 销毁全图传送门(防止打Boss时被吸走)
local function destroyPortals()
        pcall(function()
                for _, obj in ipairs(game:GetDescendants()) do
                        if obj.Name == "RobloxForwardPortals" then
                                obj:Destroy()
                        end
                end
        end)
end

-- 悬停：每帧锁定Boss头顶 + 清空速度 + 俯视朝向
local function startBossHover()
        bossHoverConn = RunService.RenderStepped:Connect(function()
                if not _G.auto_boss then
                        return
                end
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then
                        return
                end
                local bossPos = getBossPos()
                if not bossPos then
                        return
                end
                local hoverPos = bossPos + Vector3.new(0, bossHeight, 0)
                local flat = Vector3.new(bossPos.X - hoverPos.X, 0, bossPos.Z - hoverPos.Z)
                if flat.Magnitude < 0.1 then
                        flat = Vector3.new(0, 0, -1)
                end
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.lookAt(hoverPos, hoverPos + (flat.Unit + Vector3.new(0, -1, 0)).Unit)
        end)
end

-- 出拳线程：左右交替 + 每4轮破解冷却 + 动画同步
local function autoBossPunchLoop()
        local useLeft = true
        local trackLeft, trackRight = nil, nil
        local counter = 0
        while _G.auto_boss do
                if not getBossPos() then
                        task.wait(0.5)
                else
                        counter = counter + 1
                        -- 每4次破解一次出拳冷却
                        if counter % 4 == 0 then
                                pcall(function()
                                        local backpack = player:FindFirstChild("Backpack")
                                        local punchTool = backpack and backpack:FindFirstChild("Punch")
                                        local cooldown = punchTool and punchTool:FindFirstChildOfClass("NumberValue")
                                        if cooldown then
                                                cooldown.Value = 0.01
                                        end
                                end)
                        end
                        pcall(function()
                                local char = player.Character
                                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                                if not humanoid then
                                        return
                                end
                                -- 装备拳套
                                local backpack = player:FindFirstChild("Backpack")
                                local punchTool = (char and char:FindFirstChild("Punch"))
                                        or (backpack and backpack:FindFirstChild("Punch"))
                                if punchTool and punchTool.Parent ~= char then
                                        humanoid:EquipTool(punchTool)
                                end
                                -- 出拳(优先rEvents的muscleEvent，回退玩家对象下的)
                                if muscleEvent then
                                        muscleEvent:FireServer("punch", useLeft and "leftHand" or "rightHand")
                                else
                                        local pm = player:FindFirstChild("muscleEvent")
                                        if pm then
                                                pm:FireServer("punch", useLeft and "leftHand" or "rightHand")
                                        end
                                end
                                -- 本地出拳动画(与出拳节奏同步)
                                local animator = humanoid:FindFirstChildOfClass("Animator")
                                        or Instance.new("Animator", humanoid)
                                local track = useLeft and trackLeft or trackRight
                                if not track then
                                        local anim = Instance.new("Animation")
                                        anim.AnimationId = useLeft and PUNCH_ANIMS.left or PUNCH_ANIMS.right
                                        track = animator:LoadAnimation(anim)
                                        if useLeft then
                                                trackLeft = track
                                        else
                                                trackRight = track
                                        end
                                end
                                if track then
                                        track:Stop(0)
                                        track:Play(0.1)
                                end
                                useLeft = not useLeft
                        end)
                end
                task.wait(0.05)
        end
end

-- 监控线程：每2秒扫描存活的Boss，全灭时传送到待机点等刷新
local function autoBossScanLoop()
        local announcedDead = false
        while _G.auto_boss do
                task.wait(2)
                if _G.auto_boss then
                        local found = false
                        for _, name in ipairs(BOSS_NAMES) do
                                if isBossAlive(name) then
                                        found = true
                                        announcedDead = false
                                        if name ~= bossCurrent then
                                                bossCurrent = name
                                        end
                                        break
                                end
                        end
                        if not found and not announcedDead then
                                announcedDead = true
                                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                        hrp.CFrame = CFrame.new(BOSS_IDLE_POS)
                                end
                        end
                end
        end
end

-- 开箱线程：Boss宝箱(提示键/点击器/触碰 三管齐下)
local function autoBossChestLoop()
        while _G.auto_boss do
                task.wait(0.4)
                if _G.auto_boss then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local chest = workspace:FindFirstChild("BossChest")
                        if hrp and chest then
                                for _, obj in ipairs(chest:GetDescendants()) do
                                        pcall(function()
                                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                                        fireproximityprompt(obj)
                                                elseif obj:IsA("ClickDetector") then
                                                        fireclickdetector(obj)
                                                elseif obj:IsA("BasePart") and obj.CanTouch and obj.Transparency < 1 then
                                                        firetouchinterest(obj, hrp, 0)
                                                        task.wait(0.05)
                                                        firetouchinterest(obj, hrp, 1)
                                                end
                                        end)
                                end
                        end
                end
        end
end

-- ==================== 功能：换包重生 ====================
-- 练力量时穿练速装，重生前换重生倍率装，轮回不停
local PETS = {
        ["Omega Overlord"]      = { repSpeed = 20, strength = 0,  durability = 0,  rebirth = 0 },
        ["Swift Samurai"]       = { repSpeed = 15, strength = 0,  durability = 0,  rebirth = 0 },
        ["Powercore Hound"]     = { repSpeed = 0,  strength = 25, durability = 15, rebirth = 0 },
        ["Titanium Hydra"]      = { repSpeed = 0,  strength = 0,  durability = 0,  rebirth = 2 },
        ["Tribal Overlord"]     = { repSpeed = 0,  strength = 0,  durability = 0,  rebirth = 2 },
        ["Inferno Unicorn"]     = { repSpeed = 0,  strength = 25, durability = 25, rebirth = 0 },
        ["Common Boss Pet"]     = { repSpeed = 5,  strength = 0,  durability = 0,  rebirth = 0 },
        ["Rare Boss Pet"]       = { repSpeed = 7,  strength = 0,  durability = 0,  rebirth = 0 },
        ["Epic Boss Pet"]       = { repSpeed = 10, strength = 0,  durability = 0,  rebirth = 0 },
        ["Rainbow Boss Pet"]    = { repSpeed = 10, strength = 7,  durability = 0,  rebirth = 0 },
        ["Legendary Boss Pet"]  = { repSpeed = 10, strength = 10, durability = 0,  rebirth = 0 },
        ["Mythic Boss Pet"]     = { repSpeed = 10, strength = 20, durability = 0,  rebirth = 0 },
        ["Inferno Drake"]       = { repSpeed = 40, strength = 0,  durability = 0,  rebirth = 0 },
}
local MAX_PET_SLOTS = 12    -- 宠物栏上限
local TARGET_REP_SPEED = 100 -- 练速目标
local trainRate = 1200      -- 自适应锻炼速率(极速版600~2400，起步即满速)

-- 卸下全部宠物
local function unequipAllPets()
        local petsFolder = player:FindFirstChild("petsFolder")
        if not petsFolder then return end
        for _, folder in ipairs(petsFolder:GetChildren()) do
                if folder:IsA("Folder") then
                        for _, pet in ipairs(folder:GetChildren()) do
                                local equipRemote = rEvents and rEvents:FindFirstChild("equipPetEvent")
                                if equipRemote then
                                        equipRemote:FireServer("unequipPet", pet)
                                end
                        end
                end
        end
        task.wait(0.1)
end

-- 装备单个宠物
local function equipOnePet(pet)
        local equipRemote = rEvents and rEvents:FindFirstChild("equipPetEvent")
        if equipRemote then
                equipRemote:FireServer("equipPet", pet)
        end
end

-- 扫描仓库里所有在数值表里的宠物
local function getOwnedPets()
        local owned = {}
        local petsFolder = player:FindFirstChild("petsFolder")
        if not petsFolder then return owned end
        for _, folder in ipairs(petsFolder:GetChildren()) do
                if folder:IsA("Folder") then
                        for _, pet in ipairs(folder:GetChildren()) do
                                local cfg = PETS[pet.Name]
                                if cfg then
                                        table.insert(owned, {
                                                instance = pet,
                                                name = pet.Name,
                                                repSpeed = cfg.repSpeed or 0,
                                                strength = cfg.strength or 0,
                                                durability = cfg.durability or 0,
                                                rebirth = cfg.rebirth or 0,
                                        })
                                end
                        end
                end
        end
        return owned
end

-- 练速装：先凑repSpeed到100%，剩余格子补力量/耐力
local function equipFarmingPets()
        unequipAllPets()
        local pets = getOwnedPets()
        local equipped, count, repSpeed = {}, 0, 0
        table.sort(pets, function(a, b) return a.repSpeed > b.repSpeed end)
        for _, pet in ipairs(pets) do
                if count >= MAX_PET_SLOTS or repSpeed >= TARGET_REP_SPEED then break end
                if pet.repSpeed > 0 then
                        equipOnePet(pet.instance)
                        equipped[pet.instance] = true
                        count = count + 1
                        repSpeed = repSpeed + pet.repSpeed
                end
        end
        local rest = {}
        for _, pet in ipairs(pets) do
                if not equipped[pet.instance] then table.insert(rest, pet) end
        end
        table.sort(rest, function(a, b)
                return (a.strength + a.durability) > (b.strength + b.durability)
        end)
        for _, pet in ipairs(rest) do
                if count >= MAX_PET_SLOTS then break end
                if pet.strength > 0 or pet.durability > 0 then
                        equipOnePet(pet.instance)
                        equipped[pet.instance] = true
                        count = count + 1
                end
        end
        return repSpeed, count
end

-- 重生装：按重生倍率降序装满
local function equipRebirthPets()
        unequipAllPets()
        local pets = getOwnedPets()
        table.sort(pets, function(a, b) return a.rebirth > b.rebirth end)
        local count, totalMultiplier = 0, 0
        for _, pet in ipairs(pets) do
                if count >= MAX_PET_SLOTS then break end
                if pet.rebirth > 0 then
                        equipOnePet(pet.instance)
                        count = count + 1
                        totalMultiplier = totalMultiplier + pet.rebirth
                end
        end
        return totalMultiplier, count
end

-- 一次完整重生：练满 → 换重生装 → 确认+1
local function performPackRebirth()
        local strengthTarget = 5000 + rebirths.Value * 2550
        -- 自适应练力量：力量在涨→速率+20提至1200；连停3轮→速率-100降回200
        local lastStr = strengthStat.Value
        local stallCount = 0
        while strengthStat.Value < strengthTarget do
                pcall(function()
                        local burst = math.clamp(math.floor(trainRate / 10), 5, 50)
                        for _ = 1, burst do
                                muscleEvent:FireServer("rep")
                        end
                end)
                task.wait(0.01)
                local cur = strengthStat.Value
                if cur > lastStr then
                        stallCount = 0
                        trainRate = math.min(2400, trainRate + 40)
                else
                        stallCount = stallCount + 1
                        if stallCount >= 3 then
                                trainRate = math.max(600, trainRate - 80)
                                stallCount = 0
                        end
                end
                lastStr = cur
        end
        equipRebirthPets()
        task.wait(0.25)
        local before = rebirths.Value
        repeat
                if rebirthRemote:IsA("RemoteFunction") then
                        rebirthRemote:InvokeServer("rebirthRequest")
                else
                        rebirthRemote:FireServer("rebirthRequest")
                end
                task.wait(0.05)
        until rebirths.Value > before
end

-- 工作循环
local function autoPackRebirthLoop()
        while _G.auto_packrebirth do
                equipFarmingPets()
                performPackRebirth()
                task.wait(0.5)
        end
end

-- ==================== 功能：快速锻炼（自适应速率） ====================
local function adaptiveTrainLoop()
        local lastStr = (strengthStat and strengthStat.Value) or 0
        local stallCount = 0
        while _G.auto_fasttrain do
                pcall(function()
                        local burst = math.clamp(math.floor(trainRate / 10), 5, 50)
                        for _ = 1, burst do
                                muscleEvent:FireServer("rep")
                        end
                end)
                if strengthStat then
                        local cur = strengthStat.Value
                        if cur > lastStr then
                                stallCount = 0
                                trainRate = math.min(2400, trainRate + 40)
                        else
                                stallCount = stallCount + 1
                                if stallCount >= 3 then
                                        trainRate = math.max(600, trainRate - 80)
                                        stallCount = 0
                                end
                        end
                        lastStr = cur
                end
                task.wait(0.04)
        end
end

-- ==================== 功能：吃蛋 / 送蛋 ====================
-- 找蛋白蛋(角色或背包)
local function findProteinEgg()
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        return (char and char:FindFirstChild("Protein Egg"))
                or (backpack and backpack:FindFirstChild("Protein Egg"))
end

-- 吃一发蛋(双倍力量buff)
local function eatOneEgg()
        local egg = findProteinEgg()
        if egg then
                muscleEvent:FireServer("proteinEgg", egg)
                return true
        end
        return false
end

-- 自动吃蛋循环: 每0.5秒扫一次，找到就10连吃
local function autoEatEggLoop()
        while _G.auto_eategg do
                pcall(function()
                        if findProteinEgg() then
                                for _ = 1, 10 do
                                        eatOneEgg()
                                end
                        end
                end)
                task.wait(0.5)
        end
end

-- 送蛋: 把仓库里的蛋送给目标玩家，返回实送数量
local function giftEggsTo(targetPlayer, amount)
        local sent = 0
        local giftRemote = rEvents and rEvents:FindFirstChild("giftRemote")
        local folder = player:FindFirstChild("consumablesFolder")
        if not (giftRemote and folder and targetPlayer) then
                return sent
        end
        for _ = 1, amount do
                local egg = folder:FindFirstChild("Protein Egg")
                if not egg then break end
                local ok = pcall(function()
                        giftRemote:InvokeServer("giftRequest", targetPlayer, egg)
                end)
                if ok then
                        sent = sent + 1
                end
                task.wait(0.1)
        end
        return sent
end

-- 换包重生页玩家列表(送蛋下拉用)
local function getPackPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                        table.insert(names, p.Name)
                end
        end
        return names
end

-- ==================== 主要页 ====================
MainTab:Input({
        Title = "目标次数",
        Placeholder = "重生目标，0为无限",
        Value = "",
        ClearTextOnFocus = false,
        Callback = function(v)
                rbTarget = tonumber(v) or 0
        end
})

MainTab:Toggle({
        Title = "自动重生",
        Value = false,
        Callback = function(state)
                _G.auto_rebirth = state
                stop(rebirthThread)
                if state then
                        rebirthThread = task.spawn(autoRebirthLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动重生已开启" .. (rbTarget > 0 and ("，目标: " .. rbTarget .. "次") or "，无限"), Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动重生已关闭", Duration = 2 })
                end
        end
})

MainTab:Divider()

MainTab:Toggle({
        Title = "自动锻炼",
        Value = false,
        Callback = function(state)
                _G.auto_train = state
                stop(trainThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_train = false
                                return
                        end
                        trainThread = task.spawn(autoTrainLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动锻炼已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动锻炼已关闭", Duration = 2 })
                end
        end
})

MainTab:Divider()

-- ==================== 自动轮盘 ====================
MainTab:Toggle({
        Title = "自动轮盘",
        Value = false,
        Callback = function(state)
                _G.auto_wheel = state
                stop(wheelThread)
                if state then
                        wheelThread = task.spawn(autoWheelLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动轮盘已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动轮盘已关闭", Duration = 2 })
                end
        end
})

-- ==================== 传送区域 ====================
local TELEPORTS = {
        { name = "大厅", pos = Vector3.new(-0.75, 90.61, 242.78) },
        { name = "小岛", pos = Vector3.new(-32.14, 8.51, 1904.41) },
        { name = "冰霜健身房", pos = Vector3.new(-2623.41, 6.99, -409.34) },
        { name = "神话健身房", pos = Vector3.new(2250.39, 6.99, 1072.77) },
        { name = "永恒健身房", pos = Vector3.new(-6758.39, 6.99, -1284.45) },
        { name = "传奇健身房", pos = Vector3.new(4603.40, 990.99, -3897.44) },
        { name = "肌肉之王健身房", pos = Vector3.new(-8625.40, 16.99, -5730.41) },
        { name = "丛林健身房", pos = Vector3.new(-8685.01, 5.99, 2392.06) },
        { name = "工业健身房", pos = Vector3.new(-5496.68, 59.04, 4927.74) },
        { name = "超载健身房", pos = Vector3.new(-3045.30, 165.41, 4990.69) },
        { name = "无转盘岛", pos = Vector3.new(1952.09, 1, 6179.98) },
        { name = "熔岩争斗", pos = Vector3.new(4472.53, 118.90, -8848.54) },
        { name = "沙漠争斗", pos = Vector3.new(973.62, 15.92, -7277.01) },
        { name = "海滩争斗", pos = Vector3.new(-1880.89, 15.87, -6137.75) },
}

local function teleportTo(pos)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                return true
        end
        return false
end

for _, tp in ipairs(TELEPORTS) do
        TeleportTab:Button({
                Title = tp.name,
                Callback = function()
                        if teleportTo(tp.pos) then
                                WindUI:Notify({ Title = "传送", Content = "已传送到: " .. tp.name, Duration = 2 })
                        else
                                WindUI:Notify({ Title = "传送失败", Content = "未找到角色", Duration = 2 })
                        end
                end
        })
end

-- ==================== 宠物页 ====================
PetTab:Section({ Title = "宠物商店购买" })

local PetDropdown = PetTab:Dropdown({
        Title = "选择宠物/光环",
        Values = getPetShopList(),
        AllowNone = true,
        Callback = function(v)
                selectedPet = v or ""
        end,
})

PetTab:Button({
        Title = "刷新宠物列表",
        Callback = function()
                local list = getPetShopList()
                PetDropdown:Refresh(list, true)
                WindUI:Notify({ Title = "宠物商店", Content = "已刷新，共" .. #list .. "项", Duration = 2 })
        end,
})

PetTab:Button({
        Title = "购买一次",
        Color = Color3.fromHex("#00BFFF"),
        Callback = function()
                local ok, msg = buyPet(selectedPet)
                if ok then
                        WindUI:Notify({ Title = "宠物商店", Content = msg, Duration = 3 })
                else
                        WindUI:Notify({ Title = "宠物商店", Content = msg, Duration = 4 })
                end
        end
})

PetTab:Toggle({
        Title = "自动购买",
        Value = false,
        Callback = function(state)
                _G.auto_petbuy = state
                stop(petbuyThread)
                if state then
                        if selectedPet == "" then
                                WindUI:Notify({ Title = "宠物商店", Content = "请先选择宠物", Duration = 3 })
                                _G.auto_petbuy = false
                                return
                        end
                        petbuyThread = task.spawn(autoPetBuyLoop)
                        WindUI:Notify({ Title = "宠物商店", Content = "自动购买已开启: " .. selectedPet, Duration = 3 })
                else
                        WindUI:Notify({ Title = "宠物商店", Content = "自动购买已关闭", Duration = 2 })
                end
        end
})

-- ==================== Boss页 ====================
BossTab:Section({ Title = "多Boss轮换" })

BossTab:Slider({
        Title = "悬停高度",
        Value = { Default = 70, Min = 0, Max = 100, Precision = 0 },
        Callback = function(value)
                bossHeight = tonumber(value) or 70
        end,
})

BossTab:Toggle({
        Title = "自动打Boss",
        Value = false,
        Color = Color3.fromHex("#FF4040"),
        Callback = function(state)
                _G.auto_boss = state
                stop(bossPunchThread)
                stop(bossScanThread)
                stop(bossChestThread)
                if bossHoverConn then
                        pcall(function() bossHoverConn:Disconnect() end)
                        bossHoverConn = nil
                end
                if state then
                        if not (muscleEvent or player:FindFirstChild("muscleEvent")) then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_boss = false
                                return
                        end
                        destroyPortals()
                        startBossHover()
                        bossPunchThread = task.spawn(autoBossPunchLoop)
                        bossScanThread = task.spawn(autoBossScanLoop)
                        bossChestThread = task.spawn(autoBossChestLoop)
                        WindUI:Notify({ Title = "Boss", Content = "自动打Boss已开启", Duration = 3 })
                else
                        WindUI:Notify({ Title = "Boss", Content = "已关闭", Duration = 2 })
                end
        end,
})

-- ==================== 换包重生页 ====================
PackTab:Section({ Title = "换包重生" })

PackTab:Toggle({
        Title = "换包重生",
        Value = false,
        Color = Color3.fromHex("#9B59B6"),
        Callback = function(state)
                _G.auto_packrebirth = state
                stop(packrebirthThread)
                if state then
                        if not (muscleEvent and rebirthRemote and rebirths and strengthStat) then
                                WindUI:Notify({ Title = "提示", Content = "未找到游戏事件，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_packrebirth = false
                                return
                        end
                        packrebirthThread = task.spawn(autoPackRebirthLoop)
                        WindUI:Notify({ Title = "换包重生", Content = "已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "换包重生", Content = "已关闭", Duration = 2 })
                end
        end,
})

PackTab:Divider()

PackTab:Toggle({
        Title = "快速锻炼",
        Value = false,
        Color = Color3.fromHex("#00BFFF"),
        Callback = function(state)
                _G.auto_fasttrain = state
                stop(fasttrainThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_fasttrain = false
                                return
                        end
                        trainRate = 1200
                        fasttrainThread = task.spawn(adaptiveTrainLoop)
                        WindUI:Notify({ Title = "已开启", Content = "快速锻炼已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "快速锻炼已关闭", Duration = 2 })
                end
        end,
})

PackTab:Divider()

PackTab:Section({ Title = "蛋白蛋" })

PackTab:Toggle({
        Title = "自动吃蛋",
        Value = false,
        Color = Color3.fromHex("#F39C12"),
        Callback = function(state)
                _G.auto_eategg = state
                stop(eateggThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_eategg = false
                                return
                        end
                        eateggThread = task.spawn(autoEatEggLoop)
                        WindUI:Notify({ Title = "自动吃蛋", Content = "已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "自动吃蛋", Content = "已关闭", Duration = 2 })
                end
        end,
})

local selectedEggTarget = ""
local EggPlayerDropdown = PackTab:Dropdown({
        Title = "送蛋目标",
        Values = getPackPlayerNames(),
        AllowNone = true,
        Callback = function(v)
                selectedEggTarget = v or ""
        end,
})

PackTab:Input({
        Title = "送蛋数量",
        Placeholder = "0为全部",
        Value = "",
        ClearTextOnFocus = false,
        Callback = function(v)
                giftAmount = tonumber(v) or 0
        end,
})

PackTab:Button({
        Title = "送蛋",
        Color = Color3.fromHex("#2ECC71"),
        Callback = function()
                local target = Players:FindFirstChild(selectedEggTarget)
                if selectedEggTarget == "" or not target then
                        WindUI:Notify({ Title = "送蛋", Content = "请先选择玩家", Duration = 3 })
                        return
                end
                local folder = player:FindFirstChild("consumablesFolder")
                local have = folder and #folder:GetChildren() or 0
                if have == 0 then
                        WindUI:Notify({ Title = "送蛋", Content = "仓库里没有蛋", Duration = 3 })
                        return
                end
                local amount = giftAmount > 0 and giftAmount or 9999
                task.spawn(function()
                        local sent = giftEggsTo(target, amount)
                        WindUI:Notify({ Title = "送蛋", Content = "已送给 " .. selectedEggTarget .. " " .. sent .. " 个蛋", Duration = 3 })
                        EggPlayerDropdown:Refresh(getPackPlayerNames(), true)
                end)
        end,
})

-- ==================== 启动 ====================
task.wait(0.3)
WindUI:Notify({
        Title = "脚本加载完成",
        Content = (muscleEvent and rebirthRemote) and "欢迎使用JBS 鸡巴骚 v3.1" or "欢迎使用JBS 鸡巴骚 v3.1，部分功能不可用",
        Duration = 3,
})

end)
if not okMain then
        notify("JBS 鸡巴骚", "运行出错: " .. tostring(errMain), 10)
        warn("[JBS] 运行错误: ", errMain)
end
