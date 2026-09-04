local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local VoiceChatService = game:GetService("VoiceChatService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- Função para requisições HTTP do lado do cliente (APIs de terceiros / Executores)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function fetchUserDescriptionThirdParty(userId)
	if not httpRequest then
		return "HTTP Request não suportado"
	end

	local url = string.format("https://users.roproxy.com/v1/users/%d", userId)
	local success, response = pcall(function()
		return httpRequest({
			Url = url,
			Method = "GET"
		})
	end)

	if success and response and response.Body then
		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)

		if decodeSuccess and data and data.description then
			if data.description == "" then
				return "Sem descrição."
			end
			return data.description
		end
	end

	return "Erro ao carregar descrição."
end

local function fetchFriendsAndFollowers(userId)
	local followersCount = 0
	local friendsCount = 0

	if httpRequest then
		-- Seguidores
		pcall(function()
			local res = httpRequest({
				Url = string.format("https://friends.roproxy.com/v1/users/%d/followers/count", userId),
				Method = "GET"
			})
			if res and res.Body then
				local data = HttpService:JSONDecode(res.Body)
				if data and data.count then
					followersCount = data.count
				end
			end
		end)

		-- Amigos
		pcall(function()
			local res = httpRequest({
				Url = string.format("https://friends.roproxy.com/v1/users/%d/friends/count", userId),
				Method = "GET"
			})
			if res and res.Body then
				local data = HttpService:JSONDecode(res.Body)
				if data and data.count then
					friendsCount = data.count
				end
			end
		end)
	end

	return followersCount, friendsCount
end

task.spawn(function()
	repeat
		local success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		task.wait(0.2)
	until success
end)

if CoreGui:FindFirstChild("MinimalistLeaderboardGui") then
	CoreGui.MinimalistLeaderboardGui:Destroy()
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MAX_STATS = isMobile and 3 or 5

local CONFIG_FILE = "LeaderboardSettings.json"
local defaultSettings = { Language = "en", Theme = "dark", DisrespectfulUsers = {} }

local function loadSettings()
	if readfile and isfile and isfile(CONFIG_FILE) then
		local success, result = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if success and type(result) == "table" then
			if not result.DisrespectfulUsers then result.DisrespectfulUsers = {} end
			return result
		end
	end
	return defaultSettings
end

local settingsData = loadSettings()
local function saveSettings()
	if writefile then pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(settingsData)) end) end
end

local Themes = {
	dark = {BG = Color3.fromRGB(18, 19, 21), CARD = Color3.fromRGB(28, 29, 32), STROKE = Color3.fromRGB(45, 47, 52), TEXT = Color3.fromRGB(255, 255, 255), SUBTEXT = Color3.fromRGB(160, 163, 170), SPINNER = Color3.fromRGB(0, 112, 255)},
	dark_red = {BG = Color3.fromRGB(25, 12, 14), CARD = Color3.fromRGB(38, 18, 20), STROKE = Color3.fromRGB(60, 25, 30), TEXT = Color3.fromRGB(255, 255, 255), SUBTEXT = Color3.fromRGB(180, 140, 145), SPINNER = Color3.fromRGB(245, 52, 60)},
	dark_blue = {BG = Color3.fromRGB(12, 18, 28), CARD = Color3.fromRGB(18, 26, 40), STROKE = Color3.fromRGB(30, 45, 68), TEXT = Color3.fromRGB(255, 255, 255), SUBTEXT = Color3.fromRGB(140, 160, 185), SPINNER = Color3.fromRGB(0, 140, 255)},
	dark_green = {BG = Color3.fromRGB(12, 24, 16), CARD = Color3.fromRGB(18, 35, 24), STROKE = Color3.fromRGB(30, 58, 38), TEXT = Color3.fromRGB(255, 255, 255), SUBTEXT = Color3.fromRGB(140, 180, 155), SPINNER = Color3.fromRGB(40, 200, 100)},
	dark_purple = {BG = Color3.fromRGB(20, 12, 28), CARD = Color3.fromRGB(30, 18, 42), STROKE = Color3.fromRGB(50, 30, 70), TEXT = Color3.fromRGB(255, 255, 255), SUBTEXT = Color3.fromRGB(165, 140, 185), SPINNER = Color3.fromRGB(160, 60, 240)},
	light = {BG = Color3.fromRGB(240, 240, 242), CARD = Color3.fromRGB(255, 255, 255), STROKE = Color3.fromRGB(210, 212, 218), TEXT = Color3.fromRGB(20, 20, 20), SUBTEXT = Color3.fromRGB(100, 102, 110), SPINNER = Color3.fromRGB(0, 112, 255)}
}

local Translations = {
	en = {Title = "Players", AddFriend = "Add Friend", UnAddFriend = "UnAdd Friend", Block = "Block", ViewAvatar = "View avatar", Close = "Close", Settings = "Settings", Created = "Created: ", Theme = "Theme", Lang = "Language", Confirm = "Confirm", VoiceActive = "🔊 Voice Active", VoiceInactive = "Last active: ", Disrespectful = "Disrespectful User", RemoveDisrespectful = "Remove disrespectful behavior", BlockText = "Are you sure you want to block this user?", UnAddText = "Are you sure you want to UnAdd this person?", LessThanMin = "Less than a minute", MinSecFormat = "%d minute and %d seconds ago", HourMinFormat = "%d hours and %d minutes ago", Followers = "Followers: ", Friends = "Friends: "},
	pt = {Title = "Jogadores", AddFriend = "Adicionar Amigo", UnAddFriend = "Remover Amigo", Block = "Bloquear", ViewAvatar = "Ver Avatar", Close = "Fechar", Settings = "Configurações", Created = "Criado em: ", Theme = "Tema", Lang = "Idioma", Confirm = "Confirmar", VoiceActive = "🔊 Voz Ativa", VoiceInactive = "Última vez ativo: ", Disrespectful = "Usuário Desrespeitoso", RemoveDisrespectful = "Remover comportamento desrespeitoso", BlockText = "Tem certeza de que deseja bloquear este usuário?", UnAddText = "Tem certeza de que deseja remover este amigo?", LessThanMin = "Menos de um Minuto", MinSecFormat = "Há %d minuto e %d segundos", HourMinFormat = "Há %d horas e %d minutos", Followers = "Seguidores: ", Friends = "Amigos: "},
	es = {Title = "Jugadores", AddFriend = "Añadir Amigo", UnAddFriend = "Eliminar Amigo", Block = "Bloquear", ViewAvatar = "Ver Avatar", Close = "Cerrar", Settings = "Ajustes", Created = "Creado: ", Theme = "Tema", Lang = "Idioma", Confirm = "Confirmar", VoiceActive = "🔊 Voice Activa", VoiceInactive = "Última vez activo: ", Disrespectful = "Usuario Desrespetuoso", RemoveDisrespectful = "Eliminar comportamiento desrespetuoso", BlockText = "¿Estás seguro de que quieres bloquear a este usuario?", UnAddText = "¿Estás seguro de que quieres eliminar a este amigo?", LessThanMin = "Menos de un Minuto", MinSecFormat = "Hace %d minuto y %d segundos", HourMinFormat = "Hace %d horas y %d minutos", Followers = "Seguidores: ", Friends = "Amigos: "}
}

local currentTheme = Themes[settingsData.Theme] or Themes.dark
local currentLang = Translations[settingsData.Language] or Translations.en

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimalistLeaderboardGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleArrowBtn"
toggleBtn.Size = isMobile and UDim2.new(0, 40, 0, 40) or UDim2.new(0, 36, 0, 36)
toggleBtn.Position = UDim2.new(1, -48, 0, 10)
toggleBtn.BackgroundColor3 = currentTheme.BG
toggleBtn.Text = "➔"
toggleBtn.TextColor3 = currentTheme.TEXT
toggleBtn.TextSize = isMobile and 16 or 14
toggleBtn.Font = Enum.Font.BuilderSansBold
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = currentTheme.STROKE
toggleStroke.Thickness = 1
toggleStroke.Parent = toggleBtn

local leaderboardFrame = Instance.new("CanvasGroup")
leaderboardFrame.Name = "LeaderboardContainer"
leaderboardFrame.Size = isMobile and UDim2.new(0, 320, 0, 320) or UDim2.new(0, 420, 0, 350)
leaderboardFrame.Position = UDim2.new(1, 10, 0, 52)
leaderboardFrame.BackgroundColor3 = currentTheme.BG
leaderboardFrame.GroupTransparency = 1
leaderboardFrame.Visible = false
leaderboardFrame.Parent = screenGui

local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 10)
lbCorner.Parent = leaderboardFrame

local lbStroke = Instance.new("UIStroke")
lbStroke.Color = currentTheme.STROKE
lbStroke.Thickness = 1
lbStroke.Parent = leaderboardFrame

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, -50, 0, 32)
lbTitle.Position = UDim2.new(0, 10, 0, 2)
lbTitle.BackgroundTransparency = 1
lbTitle.Text = currentLang.Title
lbTitle.TextColor3 = currentTheme.TEXT
lbTitle.TextSize = isMobile and 13 or 12
lbTitle.Font = Enum.Font.BuilderSansBold
lbTitle.TextXAlignment = Enum.TextXAlignment.Left
lbTitle.Parent = leaderboardFrame

local settingsIconBtn = Instance.new("TextButton")
settingsIconBtn.Size = UDim2.new(0, 28, 0, 28)
settingsIconBtn.Position = UDim2.new(1, -34, 0, 4)
settingsIconBtn.BackgroundTransparency = 1
settingsIconBtn.Text = "⚙️"
settingsIconBtn.TextSize = 14
settingsIconBtn.Parent = leaderboardFrame

local scrollingPlayers = Instance.new("ScrollingFrame")
scrollingPlayers.Size = UDim2.new(1, -12, 1, -40)
scrollingPlayers.Position = UDim2.new(0, 6, 0, 34)
scrollingPlayers.BackgroundTransparency = 1
scrollingPlayers.BorderSizePixel = 0
scrollingPlayers.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingPlayers.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingPlayers.ScrollBarThickness = 2
scrollingPlayers.ScrollBarImageColor3 = currentTheme.STROKE
scrollingPlayers.Parent = leaderboardFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollingPlayers

local loadingContainer = Instance.new("Frame")
loadingContainer.Name = "LoadingContainer"
loadingContainer.Size = UDim2.new(1, 0, 1, 0)
loadingContainer.BackgroundTransparency = 1
loadingContainer.Visible = false
loadingContainer.Parent = leaderboardFrame

local spinnerOuter = Instance.new("Frame")
spinnerOuter.Size = UDim2.new(0, 36, 0, 36)
spinnerOuter.Position = UDim2.new(0.5, -18, 0.5, -18)
spinnerOuter.BackgroundColor3 = currentTheme.SPINNER
spinnerOuter.BackgroundTransparency = 0.2
spinnerOuter.Parent = loadingContainer

local spinnerCorner = Instance.new("UICorner")
spinnerCorner.CornerRadius = UDim.new(1, 0)
spinnerCorner.Parent = spinnerOuter

local spinnerInner = Instance.new("Frame")
spinnerInner.Size = UDim2.new(0, 26, 0, 26)
spinnerInner.Position = UDim2.new(0.5, -13, 0.5, -13)
spinnerInner.BackgroundColor3 = currentTheme.BG
spinnerInner.Parent = spinnerOuter

local spinnerInnerCorner = Instance.new("UICorner")
spinnerInnerCorner.CornerRadius = UDim.new(1, 0)
spinnerInnerCorner.Parent = spinnerInner

local spinnerNotch = Instance.new("Frame")
spinnerNotch.Size = UDim2.new(0, 10, 0, 10)
spinnerNotch.Position = UDim2.new(0.5, -5, 0, -2)
spinnerNotch.BackgroundColor3 = currentTheme.BG
spinnerNotch.BorderSizePixel = 0
spinnerNotch.Parent = spinnerOuter

local spinnerTween = nil

local function showLoadingCircle()
	loadingContainer.Visible = true
	scrollingPlayers.Visible = false
	if spinnerTween then spinnerTween:Cancel() end
	spinnerOuter.Rotation = 0
	spinnerTween = TweenService:Create(spinnerOuter, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		Rotation = 360
	})
	spinnerTween:Play()
end

local function hideLoadingCircle()
	if spinnerTween then 
		spinnerTween:Cancel()
		spinnerTween = nil 
	end
	loadingContainer.Visible = false
	scrollingPlayers.Visible = true
end

local function createSpinner(parentFrame)
	local outer = Instance.new("Frame")
	outer.Size = UDim2.new(0, 32, 0, 32)
	outer.Position = UDim2.new(0.5, -16, 0.5, -16)
	outer.BackgroundColor3 = currentTheme.SPINNER
	outer.BackgroundTransparency = 0.2
	outer.ZIndex = 10
	outer.Parent = parentFrame

	local c1 = Instance.new("UICorner")
	c1.CornerRadius = UDim.new(1, 0)
	c1.Parent = outer

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(0, 22, 0, 22)
	inner.Position = UDim2.new(0.5, -11, 0.5, -11)
	inner.BackgroundColor3 = currentTheme.CARD
	inner.ZIndex = 11
	inner.Parent = outer

	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(1, 0)
	c2.Parent = inner

	local notch = Instance.new("Frame")
	notch.Size = UDim2.new(0, 8, 0, 8)
	notch.Position = UDim2.new(0.5, -4, 0, -2)
	notch.BackgroundColor3 = currentTheme.CARD
	notch.BorderSizePixel = 0
	notch.ZIndex = 12
	notch.Parent = outer

	local tween = TweenService:Create(outer, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		Rotation = 360
	})
	
	return outer, tween
end

-- Janela Profile
local profileModal = Instance.new("CanvasGroup")
profileModal.Name = "ProfileModal"
profileModal.Size = isMobile and UDim2.new(0, 280, 0, 380) or UDim2.new(0, 300, 0, 405)
profileModal.Position = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
profileModal.BackgroundColor3 = currentTheme.BG
profileModal.GroupTransparency = 1
profileModal.Visible = false
profileModal.Parent = screenGui

local pmCorner = Instance.new("UICorner")
pmCorner.CornerRadius = UDim.new(0, 12)
pmCorner.Parent = profileModal

local pmStroke = Instance.new("UIStroke")
pmStroke.Color = currentTheme.STROKE
pmStroke.Thickness = 1
pmStroke.Parent = profileModal

local profileContentGroup = Instance.new("CanvasGroup")
profileContentGroup.Name = "ProfileContentGroup"
profileContentGroup.Size = UDim2.new(1, 0, 1, 0)
profileContentGroup.BackgroundTransparency = 1
profileContentGroup.GroupTransparency = 0
profileContentGroup.Parent = profileModal

local avatarContainer = Instance.new("Frame")
avatarContainer.Name = "AvatarContainer"
avatarContainer.Size = isMobile and UDim2.new(0, 85, 0, 85) or UDim2.new(0, 95, 0, 95)
avatarContainer.Position = UDim2.new(0, 12, 0, 12)
avatarContainer.BackgroundColor3 = currentTheme.CARD
avatarContainer.Parent = profileContentGroup

local pfbCorner = Instance.new("UICorner")
pfbCorner.CornerRadius = UDim.new(0, 8)
pfbCorner.Parent = avatarContainer

local profileFullBody = Instance.new("ImageLabel")
profileFullBody.Name = "Avatar2D"
profileFullBody.Size = UDim2.new(1, 0, 1, 0)
profileFullBody.BackgroundTransparency = 1
profileFullBody.Parent = avatarContainer

local pfbCorner2 = Instance.new("UICorner")
pfbCorner2.CornerRadius = UDim.new(0, 8)
pfbCorner2.Parent = profileFullBody

local viewport3D = Instance.new("ViewportFrame")
viewport3D.Name = "Avatar3D"
viewport3D.Size = UDim2.new(1, 0, 1, 0)
viewport3D.BackgroundTransparency = 1
viewport3D.Visible = false
viewport3D.Parent = avatarContainer

local vpCorner = Instance.new("UICorner")
vpCorner.CornerRadius = UDim.new(0, 8)
vpCorner.Parent = viewport3D

local avatarSpinnerOuter, avatarSpinnerTween = createSpinner(avatarContainer)
avatarSpinnerOuter.Visible = false

local modalSpinnerOuter, modalSpinnerTween = createSpinner(profileModal)
modalSpinnerOuter.Visible = false

local toggleDimensionBtn = Instance.new("TextButton")
toggleDimensionBtn.Name = "ToggleDimensionBtn"
toggleDimensionBtn.Size = UDim2.new(0, 32, 0, 20)
toggleDimensionBtn.Position = UDim2.new(1, -36, 1, -24)
toggleDimensionBtn.BackgroundColor3 = Color3.fromRGB(0, 112, 255)
toggleDimensionBtn.Text = "2D"
toggleDimensionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDimensionBtn.TextSize = 10
toggleDimensionBtn.Font = Enum.Font.BuilderSansBold
toggleDimensionBtn.ZIndex = 5
toggleDimensionBtn.Parent = avatarContainer

local tdCorner = Instance.new("UICorner")
tdCorner.CornerRadius = UDim.new(0, 4)
tdCorner.Parent = toggleDimensionBtn

local displayNameContainer = Instance.new("Frame")
displayNameContainer.Name = "DisplayNameContainer"
displayNameContainer.Size = UDim2.new(1, -115, 0, 20)
displayNameContainer.Position = UDim2.new(0, 105, 0, 12)
displayNameContainer.BackgroundTransparency = 1
displayNameContainer.Parent = profileContentGroup

local displayLayout = Instance.new("UIListLayout")
displayLayout.FillDirection = Enum.FillDirection.Horizontal
displayLayout.VerticalAlignment = Enum.VerticalAlignment.Center
displayLayout.SortOrder = Enum.SortOrder.LayoutOrder
displayLayout.Padding = UDim.new(0, 4)
displayLayout.Parent = displayNameContainer

local displayLabel = Instance.new("TextLabel")
displayLabel.Name = "DisplayLabel"
displayLabel.Size = UDim2.new(0, 0, 1, 0)
displayLabel.AutomaticSize = Enum.AutomaticSize.X
displayLabel.BackgroundTransparency = 1
displayLabel.TextColor3 = currentTheme.TEXT
displayLabel.TextSize = isMobile and 13 or 12
displayLabel.Font = Enum.Font.BuilderSansBold
displayLabel.TextXAlignment = Enum.TextXAlignment.Left
displayLabel.TextTruncate = Enum.TextTruncate.AtEnd
displayLabel.LayoutOrder = 1
displayLabel.Parent = displayNameContainer

local profileVerifiedIcon = Instance.new("ImageLabel")
profileVerifiedIcon.Name = "VerifiedBadge"
profileVerifiedIcon.Size = UDim2.new(0, 14, 0, 14)
profileVerifiedIcon.BackgroundTransparency = 1
profileVerifiedIcon.Image = "rbxassetid://11478378840"
profileVerifiedIcon.Visible = false
profileVerifiedIcon.LayoutOrder = 2
profileVerifiedIcon.Parent = displayNameContainer

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(1, -115, 0, 16)
usernameLabel.Position = UDim2.new(0, 105, 0, 30)
usernameLabel.BackgroundTransparency = 1
usernameLabel.TextColor3 = currentTheme.SUBTEXT
usernameLabel.TextSize = 11
usernameLabel.Font = Enum.Font.BuilderSans
usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
usernameLabel.Parent = profileContentGroup

local accountCreatedLabel = Instance.new("TextLabel")
accountCreatedLabel.Size = UDim2.new(1, -115, 0, 16)
accountCreatedLabel.Position = UDim2.new(0, 105, 0, 46)
accountCreatedLabel.BackgroundTransparency = 1
accountCreatedLabel.TextColor3 = currentTheme.SUBTEXT
accountCreatedLabel.TextSize = 10
accountCreatedLabel.Font = Enum.Font.BuilderSans
accountCreatedLabel.TextXAlignment = Enum.TextXAlignment.Left
accountCreatedLabel.Parent = profileContentGroup

local followersLabel = Instance.new("TextLabel")
followersLabel.Size = UDim2.new(1, -115, 0, 16)
followersLabel.Position = UDim2.new(0, 105, 0, 62)
followersLabel.BackgroundTransparency = 1
followersLabel.TextColor3 = currentTheme.SUBTEXT
followersLabel.TextSize = 10
followersLabel.Font = Enum.Font.BuilderSans
followersLabel.TextXAlignment = Enum.TextXAlignment.Left
followersLabel.Parent = profileContentGroup

local friendsLabel = Instance.new("TextLabel")
friendsLabel.Size = UDim2.new(1, -115, 0, 16)
friendsLabel.Position = UDim2.new(0, 105, 0, 78)
friendsLabel.BackgroundTransparency = 1
friendsLabel.TextColor3 = currentTheme.SUBTEXT
friendsLabel.TextSize = 10
friendsLabel.Font = Enum.Font.BuilderSans
friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
friendsLabel.Parent = profileContentGroup

local voiceStatusLabel = Instance.new("TextLabel")
voiceStatusLabel.Size = UDim2.new(1, -115, 0, 16)
voiceStatusLabel.Position = UDim2.new(0, 105, 0, 94)
voiceStatusLabel.BackgroundTransparency = 1
voiceStatusLabel.TextColor3 = currentTheme.SUBTEXT
voiceStatusLabel.TextSize = 10
voiceStatusLabel.Font = Enum.Font.BuilderSansMedium
voiceStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
voiceStatusLabel.Parent = profileContentGroup

-- API de Descrição do Usuário (até 2 linhas com limite truncado)
local userDescriptionLabel = Instance.new("TextLabel")
userDescriptionLabel.Name = "UserDescriptionLabel"
userDescriptionLabel.Size = UDim2.new(1, -24, 0, 28)
userDescriptionLabel.Position = UDim2.new(0, 12, 0, 116)
userDescriptionLabel.BackgroundTransparency = 1
userDescriptionLabel.TextColor3 = currentTheme.SUBTEXT
userDescriptionLabel.TextSize = 10
userDescriptionLabel.Font = Enum.Font.BuilderSans
userDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
userDescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
userDescriptionLabel.TextWrapped = true
userDescriptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
userDescriptionLabel.Text = "..."
userDescriptionLabel.Parent = profileContentGroup

local buttonsContainer = Instance.new("Frame")
buttonsContainer.Size = UDim2.new(1, -24, 0, 185)
buttonsContainer.Position = UDim2.new(0, 12, 0, 150)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.Parent = profileContentGroup

local btnLayout = Instance.new("UIListLayout")
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Padding = UDim.new(0, 5)
btnLayout.Parent = buttonsContainer

local function createProfileButton(text, isRed)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, isMobile and 30 or 28)
	btn.BackgroundColor3 = isRed and Color3.fromRGB(245, 52, 60) or Color3.fromRGB(0, 112, 255)
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.BuilderSansBold
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	btn.Parent = buttonsContainer
	return btn
end

local blockBtn = createProfileButton(currentLang.Block, true)
local avatarBtn = createProfileButton(currentLang.ViewAvatar, false)
local friendBtn = createProfileButton(currentLang.AddFriend, false)
local disrespectfulBtn = createProfileButton(currentLang.Disrespectful, true)

local closeProfileBtn = Instance.new("TextButton")
closeProfileBtn.Size = UDim2.new(1, -24, 0, isMobile and 30 or 28)
closeProfileBtn.Position = UDim2.new(0, 12, 1, -36)
closeProfileBtn.BackgroundColor3 = currentTheme.CARD
closeProfileBtn.Text = currentLang.Close
closeProfileBtn.TextColor3 = currentTheme.TEXT
closeProfileBtn.TextSize = 11
closeProfileBtn.Font = Enum.Font.BuilderSansBold
closeProfileBtn.Parent = profileContentGroup

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 6)
cpCorner.Parent = closeProfileBtn

local confirmModal = Instance.new("CanvasGroup")
confirmModal.Name = "ConfirmModal"
confirmModal.Size = isMobile and UDim2.new(0, 270, 0, 160) or UDim2.new(0, 310, 0, 170)
confirmModal.Position = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
confirmModal.BackgroundColor3 = currentTheme.BG
confirmModal.GroupTransparency = 1
confirmModal.Visible = false
confirmModal.Parent = screenGui

local cmCorner = Instance.new("UICorner")
cmCorner.CornerRadius = UDim.new(0, 10)
cmCorner.Parent = confirmModal

local cmStroke = Instance.new("UIStroke")
cmStroke.Color = currentTheme.STROKE
cmStroke.Thickness = 1
cmStroke.Parent = confirmModal

local cmText = Instance.new("TextLabel")
cmText.Size = UDim2.new(1, -24, 0, 75)
cmText.Position = UDim2.new(0, 12, 0, 12)
cmText.BackgroundTransparency = 1
cmText.TextColor3 = currentTheme.TEXT
cmText.TextSize = 10
cmText.Font = Enum.Font.BuilderSans
cmText.TextWrapped = true
cmText.TextXAlignment = Enum.TextXAlignment.Left
cmText.TextYAlignment = Enum.TextYAlignment.Top
cmText.Parent = confirmModal

local cmBtnContainer = Instance.new("Frame")
cmBtnContainer.Size = UDim2.new(1, -24, 0, 32)
cmBtnContainer.Position = UDim2.new(0, 12, 1, -40)
cmBtnContainer.BackgroundTransparency = 1
cmBtnContainer.Parent = confirmModal

local cmLayout = Instance.new("UIListLayout")
cmLayout.FillDirection = Enum.FillDirection.Horizontal
cmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
cmLayout.SortOrder = Enum.SortOrder.LayoutOrder
cmLayout.Padding = UDim.new(0, 6)
cmLayout.Parent = cmBtnContainer

local function createConfirmButton(text, isRed, width)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width or 80, 1, 0)
	btn.BackgroundColor3 = isRed and Color3.fromRGB(245, 52, 60) or currentTheme.CARD
	btn.Text = text
	btn.TextColor3 = currentTheme.TEXT
	btn.TextSize = 10
	btn.Font = Enum.Font.BuilderSansBold
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	btn.Parent = cmBtnContainer
	return btn
end

local cmCancelBtn = createConfirmButton(currentLang.Close, false, 75)
local cmActionBtn = createConfirmButton(currentLang.Confirm, true, 85)

local settingsModal = Instance.new("CanvasGroup")
settingsModal.Name = "SettingsModal"
settingsModal.Size = isMobile and UDim2.new(0, 260, 0, 220) or UDim2.new(0, 280, 0, 240)
settingsModal.Position = isMobile and UDim2.new(0.5, -130, 0.5, -110) or UDim2.new(0.5, -140, 0.5, -120)
settingsModal.BackgroundColor3 = currentTheme.BG
settingsModal.GroupTransparency = 1
settingsModal.Visible = false
settingsModal.Parent = screenGui

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 10)
setCorner.Parent = settingsModal

local setStroke = Instance.new("UIStroke")
setStroke.Color = currentTheme.STROKE
setStroke.Thickness = 1
setStroke.Parent = settingsModal

local setLabel = Instance.new("TextLabel")
setLabel.Size = UDim2.new(1, -24, 0, 30)
setLabel.Position = UDim2.new(0, 12, 0, 8)
setLabel.BackgroundTransparency = 1
setLabel.Text = currentLang.Settings
setLabel.TextColor3 = currentTheme.TEXT
setLabel.TextSize = 12
setLabel.Font = Enum.Font.BuilderSansBold
setLabel.TextXAlignment = Enum.TextXAlignment.Left
setLabel.Parent = settingsModal

local themeSelectBtn = Instance.new("TextButton")
themeSelectBtn.Size = UDim2.new(1, -24, 0, 32)
themeSelectBtn.Position = UDim2.new(0, 12, 0, 48)
themeSelectBtn.BackgroundColor3 = currentTheme.CARD
themeSelectBtn.Text = currentLang.Theme .. ": " .. settingsData.Theme
themeSelectBtn.TextColor3 = currentTheme.TEXT
themeSelectBtn.TextSize = 11
themeSelectBtn.Font = Enum.Font.BuilderSansMedium
themeSelectBtn.Parent = settingsModal

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 6)
tCorner.Parent = themeSelectBtn

local langSelectBtn = Instance.new("TextButton")
langSelectBtn.Size = UDim2.new(1, -24, 0, 32)
langSelectBtn.Position = UDim2.new(0, 12, 0, 88)
langSelectBtn.BackgroundColor3 = currentTheme.CARD
langSelectBtn.Text = currentLang.Lang .. ": " .. string.upper(settingsData.Language)
langSelectBtn.TextColor3 = currentTheme.TEXT
langSelectBtn.TextSize = 11
langSelectBtn.Font = Enum.Font.BuilderSansMedium
langSelectBtn.Parent = settingsModal

local lCorner = Instance.new("UICorner")
lCorner.CornerRadius = UDim.new(0, 6)
lCorner.Parent = langSelectBtn

local closeSettingsBtn = Instance.new("TextButton")
closeSettingsBtn.Size = UDim2.new(1, -24, 0, 32)
closeSettingsBtn.Position = UDim2.new(0, 12, 1, -40)
closeSettingsBtn.BackgroundColor3 = currentTheme.CARD
closeSettingsBtn.Text = currentLang.Close
closeSettingsBtn.TextColor3 = currentTheme.TEXT
closeSettingsBtn.TextSize = 11
closeSettingsBtn.Font = Enum.Font.BuilderSansBold
closeSettingsBtn.Parent = settingsModal

local csCorner = Instance.new("UICorner")
csCorner.CornerRadius = UDim.new(0, 6)
csCorner.Parent = closeSettingsBtn

local themeKeys = {"dark", "dark_red", "dark_blue", "dark_green", "dark_purple", "light"}
local langKeys = {"en", "pt", "es"}

local popInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animateOpen(frame, targetPos)
	frame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 20)
	frame.GroupTransparency = 1
	frame.Visible = true
	TweenService:Create(frame, popInfo, {
		Position = targetPos,
		GroupTransparency = 0
	}):Play()
end

local function animateClose(frame, targetPos, callback)
	local exitPos = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 20)
	local tw = TweenService:Create(frame, popInfo, {
		Position = exitPos,
		GroupTransparency = 1
	})
	tw:Play()
	tw.Completed:Connect(function()
		frame.Visible = false
		if callback then callback() end
	end)
end

-- Lógica de Controle do Avatar 3D
local renderConnection = nil
local currentModel3D = nil
local is3DMode = false
local selectedTargetPlayer = nil

local function cleanup3D()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	viewport3D:ClearAllChildren()
	currentModel3D = nil
end

local function load3DAvatar(userId)
	cleanup3D()
	
	avatarSpinnerOuter.Visible = true
	avatarSpinnerTween:Play()
	
	task.spawn(function()
		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = viewport3D
		
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		viewport3D.CurrentCamera = camera
		camera.Parent = viewport3D

		local success, model = pcall(function()
			local description = Players:GetHumanoidDescriptionFromUserId(userId)
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)

		avatarSpinnerTween:Cancel()
		avatarSpinnerOuter.Visible = false

		if success and model then
			model.Parent = worldModel
			currentModel3D = model

			for _, v in ipairs(model:GetDescendants()) do
				if v:IsA("Animator") or v:IsA("AnimationPlayer") or v:IsA("Script") or v:IsA("LocalScript") then
					v:Destroy()
				end
			end

			local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
			
			if primaryPart then
				local center, size = model:GetBoundingBox()
				primaryPart.CFrame = CFrame.new(0, 0, 0)
				
				local distance = math.max(size.X, size.Y, size.Z) * 1.3 + 5
				local cameraPos = Vector3.new(0, size.Y * 0.1, distance)
				camera.CFrame = CFrame.lookAt(cameraPos, Vector3.new(0, 0, 0))

				local angle = 0
				renderConnection = RunService.RenderStepped:Connect(function(dt)
					angle = angle + dt * 0.8
					if model and model.PrimaryPart then
						model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0))
					end
				end)
			end

			if is3DMode then
				profileFullBody.Visible = false
				viewport3D.Visible = true
			end
		end
	end)
end

toggleDimensionBtn.MouseButton1Click:Connect(function()
	is3DMode = not is3DMode
	if is3DMode then
		toggleDimensionBtn.Text = "3D"
		if selectedTargetPlayer then
			if not currentModel3D then
				load3DAvatar(selectedTargetPlayer.UserId)
			else
				profileFullBody.Visible = false
				viewport3D.Visible = true
			end
		end
	else
		toggleDimensionBtn.Text = "2D"
		viewport3D.Visible = false
		profileFullBody.Visible = true
	end
end)

local updatePlayerList
local requestUpdate
local updatePlayerRowOnly

local function applyThemeAndLang()
	currentTheme = Themes[settingsData.Theme]
	currentLang = Translations[settingsData.Language]
	
	toggleBtn.BackgroundColor3 = currentTheme.BG
	toggleBtn.TextColor3 = currentTheme.TEXT
	toggleStroke.Color = currentTheme.STROKE
	
	leaderboardFrame.BackgroundColor3 = currentTheme.BG
	lbStroke.Color = currentTheme.STROKE
	lbTitle.Text = currentLang.Title
	lbTitle.TextColor3 = currentTheme.TEXT
	scrollingPlayers.ScrollBarImageColor3 = currentTheme.STROKE
	
	spinnerOuter.BackgroundColor3 = currentTheme.SPINNER
	spinnerInner.BackgroundColor3 = currentTheme.BG
	spinnerNotch.BackgroundColor3 = currentTheme.BG
	
	profileModal.BackgroundColor3 = currentTheme.BG
	pmStroke.Color = currentTheme.STROKE
	avatarContainer.BackgroundColor3 = currentTheme.CARD
	displayLabel.TextColor3 = currentTheme.TEXT
	usernameLabel.TextColor3 = currentTheme.SUBTEXT
	accountCreatedLabel.TextColor3 = currentTheme.SUBTEXT
	followersLabel.TextColor3 = currentTheme.SUBTEXT
	friendsLabel.TextColor3 = currentTheme.SUBTEXT
	voiceStatusLabel.TextColor3 = currentTheme.SUBTEXT
	userDescriptionLabel.TextColor3 = currentTheme.SUBTEXT
	closeProfileBtn.BackgroundColor3 = currentTheme.CARD
	closeProfileBtn.TextColor3 = currentTheme.TEXT
	closeProfileBtn.Text = currentLang.Close
	
	confirmModal.BackgroundColor3 = currentTheme.BG
	cmStroke.Color = currentTheme.STROKE
	cmText.TextColor3 = currentTheme.TEXT
	cmCancelBtn.BackgroundColor3 = currentTheme.CARD
	cmCancelBtn.TextColor3 = currentTheme.TEXT
	cmCancelBtn.Text = currentLang.Close
	
	settingsModal.BackgroundColor3 = currentTheme.BG
	setStroke.Color = currentTheme.STROKE
	setLabel.TextColor3 = currentTheme.TEXT
	themeSelectBtn.BackgroundColor3 = currentTheme.CARD
	themeSelectBtn.TextColor3 = currentTheme.TEXT
	themeSelectBtn.Text = currentLang.Theme .. ": " .. settingsData.Theme
	langSelectBtn.BackgroundColor3 = currentTheme.CARD
	langSelectBtn.TextColor3 = currentTheme.TEXT
	langSelectBtn.Text = currentLang.Lang .. ": " .. string.upper(settingsData.Language)
	closeSettingsBtn.BackgroundColor3 = currentTheme.CARD
	closeSettingsBtn.TextColor3 = currentTheme.TEXT
	closeSettingsBtn.Text = currentLang.Close
	
	blockBtn.Text = currentLang.Block
	avatarBtn.Text = currentLang.ViewAvatar
	friendBtn.Text = currentLang.AddFriend
	
	local isDisrespectful = selectedTargetPlayer and settingsData.DisrespectfulUsers[tostring(selectedTargetPlayer.UserId)]
	disrespectfulBtn.Text = isDisrespectful and currentLang.RemoveDisrespectful or currentLang.Disrespectful
	
	saveSettings()
end

themeSelectBtn.MouseButton1Click:Connect(function()
	local idx = table.find(themeKeys, settingsData.Theme) or 1
	idx = (idx % #themeKeys) + 1
	settingsData.Theme = themeKeys[idx]
	applyThemeAndLang()
end)

langSelectBtn.MouseButton1Click:Connect(function()
	local idx = table.find(langKeys, settingsData.Language) or 1
	idx = (idx % #langKeys) + 1
	settingsData.Language = langKeys[idx]
	applyThemeAndLang()
end)

settingsIconBtn.MouseButton1Click:Connect(function()
	local pos = isMobile and UDim2.new(0.5, -130, 0.5, -110) or UDim2.new(0.5, -140, 0.5, -120)
	if settingsModal.Visible then
		animateClose(settingsModal, pos)
	else
		animateOpen(settingsModal, pos)
	end
end)

closeSettingsBtn.MouseButton1Click:Connect(function()
	local pos = isMobile and UDim2.new(0.5, -130, 0.5, -110) or UDim2.new(0.5, -140, 0.5, -120)
	animateClose(settingsModal, pos)
end)

local isOpen = false

local function closeLeaderboard()
	isOpen = false
	toggleBtn.Text = "➔"
	TweenService:Create(toggleBtn, popInfo, {Position = UDim2.new(1, -48, 0, 10)}):Play()
	
	local targetLbPos = UDim2.new(1, 10, 0, 52)
	local tw = TweenService:Create(leaderboardFrame, popInfo, {Position = targetLbPos, GroupTransparency = 1})
	tw:Play()
	tw.Completed:Connect(function()
		if not isOpen then
			leaderboardFrame.Visible = false
		end
	end)
	
	if profileModal.Visible then
		local pos = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
		animateClose(profileModal, pos)
	end
	if confirmModal.Visible then
		local pos = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
		animateClose(confirmModal, pos)
	end
	if settingsModal.Visible then
		local pos = isMobile and UDim2.new(0.5, -130, 0.5, -110) or UDim2.new(0.5, -140, 0.5, -120)
		animateClose(settingsModal, pos)
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	if isOpen then
		toggleBtn.Text = "⬅"
		leaderboardFrame.Visible = true
		local offsetLb = isMobile and -330 or -430
		local offsetBtn = isMobile and -370 or -470
		TweenService:Create(toggleBtn, popInfo, {Position = UDim2.new(1, offsetBtn, 0, 10)}):Play()
		TweenService:Create(leaderboardFrame, popInfo, {Position = UDim2.new(1, offsetLb, 0, 52), GroupTransparency = 0}):Play()
	else
		closeLeaderboard()
	end
end)

GuiService.MenuOpened:Connect(function() screenGui.Enabled = false end)
GuiService.MenuClosed:Connect(function() screenGui.Enabled = true end)

local pendingAction = nil
local voiceStates = {}

local function getVoiceStateData(plr)
	local uid = plr.UserId
	if not voiceStates[uid] then
		voiceStates[uid] = { wasActive = false, lastDeactivateTime = 0, lastActiveTick = nil }
	end
	
	local state = voiceStates[uid]
	local isActive = false

	pcall(function()
		if VoiceChatService:IsPlayerSpeaking(plr) or VoiceChatService:IsPlayerPublishing(plr) then
			isActive = true
		end
	end)

	if not isActive then
		local audioInput = plr:FindFirstChildOfClass("AudioDeviceInput") 
			or (plr.Character and plr.Character:FindFirstChildOfClass("AudioDeviceInput"))
		if audioInput and audioInput.IsReady and not audioInput.Muted then
			isActive = true
		end
	end
	
	if isActive then
		state.wasActive = true
		state.lastActiveTick = tick()
	else
		if state.wasActive then
			state.wasActive = false
			state.lastDeactivateTime = tick()
		end
	end
	
	return isActive, state
end

local function formatTimeAgo(pastTick)
	if not pastTick then return "" end
	local diff = math.max(0, tick() - pastTick)
	
	if diff < 60 then
		return currentLang.LessThanMin
	elseif diff < 3600 then
		local mins = math.floor(diff / 60)
		local secs = math.floor(diff % 60)
		return string.format(currentLang.MinSecFormat, mins, secs)
	else
		local hours = math.floor(diff / 3600)
		local mins = math.floor((diff % 3600) / 60)
		return string.format(currentLang.HourMinFormat, hours, mins)
	end
end

local function getLeaderboardVoiceEmoji(plr)
	local isActive, state = getVoiceStateData(plr)
	
	if isActive then
		return "🔊"
	elseif (tick() - state.lastDeactivateTime) < 3.0 then
		return "🔇"
	end
	return ""
end

local function getPlayerBadges(plr)
	local badges = ""
	if settingsData.DisrespectfulUsers[tostring(plr.UserId)] then
		badges = badges .. "👩‍⚖️ "
	end
	if (game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId) or
	   (game.CreatorType == Enum.CreatorType.Group and plr:GetRankInGroup(game.CreatorId) == 255) then
		badges = badges .. "🔨 "
	end
	if localPlayer:IsFriendsWith(plr.UserId) then
		badges = badges .. "👥 "
	end
	local vEmoji = getLeaderboardVoiceEmoji(plr)
	if vEmoji ~= "" then
		badges = badges .. vEmoji .. " "
	end
	return badges
end

local function getFormattedAccountAge(plr)
	local days = plr.AccountAge
	local createdTimestamp = os.time() - (days * 86400)
	local d = os.date("*t", createdTimestamp)
	local yearShort = string.sub(tostring(d.year), -2)
	
	if settingsData.Language == "en" then
		return string.format("%02d/%02d/%s", d.month, d.day, yearShort)
	else
		return string.format("%02d/%02d/%s", d.day, d.month, yearShort)
	end
end

local function formatTeamName(name)
	if #name > 10 then
		return string.sub(name, 1, 10) .. "..."
	end
	return name
end

local function formatNumber(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(n)
end

local function getGameStatsList()
	for _, plr in ipairs(Players:GetPlayers()) do
		local leaderstats = plr:FindFirstChild("leaderstats")
		if leaderstats then
			local stats = {}
			for _, stat in ipairs(leaderstats:GetChildren()) do
				if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
					table.insert(stats, stat.Name)
					if #stats >= MAX_STATS then break end
				end
			end
			if #stats > 0 then return stats end
		end
	end
	return nil
end

local function getPlayerStatValue(plr, statName)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if leaderstats then
		local s = leaderstats:FindFirstChild(statName)
		if s and (s:IsA("IntValue") or s:IsA("NumberValue") or s:IsA("StringValue")) then
			return s.Value
		end
	end
	return 0
end

local function getPlayerPrimaryStat(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Moedas")
		if coins and (coins:IsA("IntValue") or coins:IsA("NumberValue")) then return coins.Value end
		for _, stat in ipairs(leaderstats:GetChildren()) do
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then return stat.Value end
		end
	end
	return 0
end

local isUpdatingList = false
local updatePending = false

updatePlayerRowOnly = function(plr)
	local row = scrollingPlayers:FindFirstChild("PlayerRow_" .. plr.UserId)
	if not row then return false end
	
	local activeStats = getGameStatsList()

	if activeStats then
		for i, statName in ipairs(activeStats) do
			local statTxt = row:FindFirstChild("Stat_" .. statName)
			if statTxt then
				local val = getPlayerStatValue(plr, statName)
				statTxt.Text = type(val) == "number" and formatNumber(val) or tostring(val)
			end
		end
	end

	local statusBadges = row:FindFirstChild("StatusBadges")
	if statusBadges then
		statusBadges.Text = getPlayerBadges(plr)
	end

	return true
end

updatePlayerList = function(showLoading)
	if isUpdatingList then 
		updatePending = true
		return 
	end
	isUpdatingList = true

	if showLoading then
		showLoadingCircle()
	end

	pcall(function()
		scrollingPlayers.AutomaticCanvasSize = Enum.AutomaticSize.None

		for _, child in ipairs(scrollingPlayers:GetChildren()) do
			if not child:IsA("UIListLayout") then 
				child:Destroy() 
			end
		end
		
		local allTeams = Teams:GetTeams()
		local playersByTeam = {}
		local neutralPlayers = {}
		local activeStats = getGameStatsList()
		local numStats = activeStats and #activeStats or 0
		
		local function sortPlayersByStats(list)
			table.sort(list, function(a, b)
				return getPlayerPrimaryStat(a) > getPlayerPrimaryStat(b)
			end)
		end

		if #allTeams > 0 then
			for _, team in ipairs(allTeams) do playersByTeam[team] = {} end
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Team and playersByTeam[plr.Team] then
					table.insert(playersByTeam[plr.Team], plr)
				else
					table.insert(neutralPlayers, plr)
				end
			end
		else
			neutralPlayers = Players:GetPlayers()
		end
		
		sortPlayersByStats(neutralPlayers)
		
		table.sort(allTeams, function(a, b)
			local countA = playersByTeam[a] and #playersByTeam[a] or 0
			local countB = playersByTeam[b] and #playersByTeam[b] or 0
			return countA > countB
		end)

		local tempRows = {}

		if #allTeams == 0 and activeStats then
			local headerFrame = Instance.new("Frame")
			headerFrame.Name = "HeaderFrame"
			headerFrame.Size = UDim2.new(1, 0, 0, 20)
			headerFrame.BackgroundTransparency = 1

			local statWidth = 42
			local badgesWidth = 45
			local nameWidthOffset = (numStats * statWidth) + badgesWidth + 40

			local nameHeader = Instance.new("TextLabel")
			nameHeader.Size = UDim2.new(1, -nameWidthOffset, 1, 0)
			nameHeader.Position = UDim2.new(0, 36, 0, 0)
			nameHeader.BackgroundTransparency = 1
			nameHeader.Text = "Name"
			nameHeader.TextColor3 = currentTheme.SUBTEXT
			nameHeader.TextSize = 10
			nameHeader.Font = Enum.Font.BuilderSansBold
			nameHeader.TextXAlignment = Enum.TextXAlignment.Left
			nameHeader.Parent = headerFrame

			for i, statName in ipairs(activeStats) do
				local statHeader = Instance.new("TextLabel")
				statHeader.Size = UDim2.new(0, statWidth, 1, 0)
				local rightOffset = -badgesWidth - ((numStats - i) * statWidth) - 5
				statHeader.Position = UDim2.new(1, rightOffset, 0, 0)
				statHeader.BackgroundTransparency = 1
				statHeader.Text = statName
				statHeader.TextColor3 = currentTheme.SUBTEXT
				statHeader.TextSize = 9
				statHeader.Font = Enum.Font.BuilderSansBold
				statHeader.TextXAlignment = Enum.TextXAlignment.Center
				statHeader.TextTruncate = Enum.TextTruncate.AtEnd
				statHeader.Parent = headerFrame
			end

			table.insert(tempRows, headerFrame)
		end

		local function createPlayerRow(plr)
			local row = Instance.new("TextButton")
			row.Name = "PlayerRow_" .. plr.UserId
			row.Size = UDim2.new(1, 0, 0, isMobile and 38 or 34)
			row.BackgroundColor3 = currentTheme.CARD
			row.BorderSizePixel = 0
			row.Text = ""
			
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 6)
			rc.Parent = row
			
			local avatarThumb = Instance.new("ImageLabel")
			avatarThumb.Name = "AvatarThumb"
			avatarThumb.Size = UDim2.new(0, 26, 0, 26)
			avatarThumb.Position = UDim2.new(0, 5, 0.5, -13)
			avatarThumb.BackgroundColor3 = currentTheme.BG
			avatarThumb.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150"
			avatarThumb.Parent = row
			
			local atc = Instance.new("UICorner")
			atc.CornerRadius = UDim.new(1, 0)
			atc.Parent = avatarThumb

			local statWidth = 42
			local badgesWidth = 45
			local nameWidthOffset = (numStats * statWidth) + badgesWidth + 40
			
			local nameContainer = Instance.new("Frame")
			nameContainer.Name = "NameContainer"
			nameContainer.Size = UDim2.new(1, -nameWidthOffset, 1, 0)
			nameContainer.Position = UDim2.new(0, 36, 0, 0)
			nameContainer.BackgroundTransparency = 1
			nameContainer.Parent = row

			local nameLayout = Instance.new("UIListLayout")
			nameLayout.FillDirection = Enum.FillDirection.Horizontal
			nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
			nameLayout.Padding = UDim.new(0, 4)
			nameLayout.Parent = nameContainer

			local nameTxt = Instance.new("TextLabel")
			nameTxt.Name = "NameTxt"
			nameTxt.Size = UDim2.new(0, 0, 1, 0)
			nameTxt.AutomaticSize = Enum.AutomaticSize.X
			nameTxt.BackgroundTransparency = 1
			nameTxt.Text = plr.DisplayName
			nameTxt.TextColor3 = currentTheme.TEXT
			nameTxt.TextSize = isMobile and 11 or 10
			nameTxt.Font = Enum.Font.BuilderSansMedium
			nameTxt.TextXAlignment = Enum.TextXAlignment.Left
			nameTxt.TextTruncate = Enum.TextTruncate.AtEnd
			nameTxt.LayoutOrder = 1
			nameTxt.Parent = nameContainer
			
			if plr.HasVerifiedBadge then
				local verifiedIcon = Instance.new("ImageLabel")
				verifiedIcon.Name = "VerifiedIcon"
				verifiedIcon.Size = UDim2.new(0, 12, 0, 12)
				verifiedIcon.BackgroundTransparency = 1
				verifiedIcon.Image = "rbxassetid://11478378840"
				verifiedIcon.LayoutOrder = 2
				verifiedIcon.Parent = nameContainer
			end
			
			if activeStats then
				for i, statName in ipairs(activeStats) do
					local statTxt = Instance.new("TextLabel")
					statTxt.Name = "Stat_" .. statName
					statTxt.Size = UDim2.new(0, statWidth, 1, 0)
					local rightOffset = -badgesWidth - ((numStats - i) * statWidth) - 5
					statTxt.Position = UDim2.new(1, rightOffset, 0, 0)
					statTxt.BackgroundTransparency = 1
					local val = getPlayerStatValue(plr, statName)
					statTxt.Text = type(val) == "number" and formatNumber(val) or tostring(val)
					statTxt.TextColor3 = Color3.fromRGB(255, 215, 0)
					statTxt.TextSize = 9
					statTxt.Font = Enum.Font.BuilderSansBold
					statTxt.TextXAlignment = Enum.TextXAlignment.Center
					statTxt.TextTruncate = Enum.TextTruncate.AtEnd
					statTxt.Parent = row
				end
			end

			local statusBadges = Instance.new("TextLabel")
			statusBadges.Name = "StatusBadges"
			statusBadges.Size = UDim2.new(0, badgesWidth, 1, 0)
			statusBadges.Position = UDim2.new(1, -badgesWidth - 2, 0, 0)
			statusBadges.BackgroundTransparency = 1
			statusBadges.Text = getPlayerBadges(plr)
			statusBadges.TextColor3 = currentTheme.TEXT
			statusBadges.TextSize = 10
			statusBadges.Font = Enum.Font.BuilderSans
			statusBadges.TextXAlignment = Enum.TextXAlignment.Right
			statusBadges.Parent = row
			
			row.MouseButton1Click:Connect(function()
				selectedTargetPlayer = plr
				
				local pos = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
				
				profileContentGroup.GroupTransparency = 1
				modalSpinnerOuter.Visible = true
				modalSpinnerTween:Play()
				
				animateOpen(profileModal, pos)
				
				task.spawn(function()
					cleanup3D()
					is3DMode = false
					toggleDimensionBtn.Text = "2D"
					viewport3D.Visible = false
					profileFullBody.Visible = true
					
					displayLabel.Text = plr.DisplayName
					profileVerifiedIcon.Visible = plr.HasVerifiedBadge
					
					usernameLabel.Text = "@" .. plr.Name
					accountCreatedLabel.Text = currentLang.Created .. getFormattedAccountAge(plr)
					followersLabel.Text = currentLang.Followers .. "..."
					friendsLabel.Text = currentLang.Friends .. "..."
					profileFullBody.Image = "rbxthumb://type=Avatar&id=" .. plr.UserId .. "&w=352&h=352"
					
					userDescriptionLabel.Text = "..."
					task.spawn(function()
						local descText = fetchUserDescriptionThirdParty(plr.UserId)
						if selectedTargetPlayer == plr then
							userDescriptionLabel.Text = '"' .. descText .. '"'
						end
					end)

					task.spawn(function()
						local fers, fris = fetchFriendsAndFollowers(plr.UserId)
						if selectedTargetPlayer == plr then
							followersLabel.Text = currentLang.Followers .. formatNumber(fers)
							friendsLabel.Text = currentLang.Friends .. formatNumber(fris)
						end
					end)

					local isActive, state = getVoiceStateData(plr)
					if isActive then
						voiceStatusLabel.Visible = true
						voiceStatusLabel.Text = currentLang.VoiceActive
						voiceStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 100)
					elseif state.lastActiveTick then
						voiceStatusLabel.Visible = true
						voiceStatusLabel.Text = currentLang.VoiceInactive .. formatTimeAgo(state.lastActiveTick)
						voiceStatusLabel.TextColor3 = currentTheme.SUBTEXT
					else
						voiceStatusLabel.Visible = false
					end
					
					if plr == localPlayer then
						friendBtn.Visible = false
						blockBtn.Visible = false
						disrespectfulBtn.Visible = false
					else
						friendBtn.Visible = true
						blockBtn.Visible = true
						disrespectfulBtn.Visible = true
						friendBtn.Text = localPlayer:IsFriendsWith(plr.UserId) and currentLang.UnAddFriend or currentLang.AddFriend
						
						local isDisrespectful = settingsData.DisrespectfulUsers[tostring(plr.UserId)]
						disrespectfulBtn.Text = isDisrespectful and currentLang.RemoveDisrespectful or currentLang.Disrespectful
					end
					
					task.wait(0.25)
					
					modalSpinnerTween:Cancel()
					modalSpinnerOuter.Visible = false
					
					TweenService:Create(profileContentGroup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						GroupTransparency = 0
					}):Play()
				end)
			end)

			return row
		end
		
		for _, team in ipairs(allTeams) do
			local teamPlayers = playersByTeam[team] or {}
			if #teamPlayers > 0 then
				sortPlayersByStats(teamPlayers)
				
				local teamFrame = Instance.new("Frame")
				teamFrame.Name = "TeamFrame_" .. team.Name
				teamFrame.Size = UDim2.new(1, 0, 0, 24)
				teamFrame.BackgroundColor3 = team.TeamColor.Color
				teamFrame.BorderSizePixel = 0
				
				local tfCorner = Instance.new("UICorner")
				tfCorner.CornerRadius = UDim.new(0, 4)
				tfCorner.Parent = teamFrame
				
				local bgCol = team.TeamColor.Color
				local luminance = (bgCol.R * 0.299 + bgCol.G * 0.587 + bgCol.B * 0.114)
				local dynamicTeamTextColor = luminance > 0.65 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)

				local statWidth = 42
				local badgesWidth = 45
				local teamNameWidthOffset = (numStats * statWidth) + badgesWidth + 10

				local teamLabel = Instance.new("TextLabel")
				teamLabel.Size = UDim2.new(1, -teamNameWidthOffset, 1, 0)
				teamLabel.Position = UDim2.new(0, 8, 0, 0)
				teamLabel.BackgroundTransparency = 1
				teamLabel.Text = formatTeamName(team.Name) .. " (" .. #teamPlayers .. ")"
				teamLabel.TextColor3 = dynamicTeamTextColor
				teamLabel.TextSize = 11
				teamLabel.Font = Enum.Font.BuilderSansBold
				teamLabel.TextXAlignment = Enum.TextXAlignment.Left
				teamLabel.Parent = teamFrame

				if activeStats then
					for i, statName in ipairs(activeStats) do
						local teamStatHeader = Instance.new("TextLabel")
						teamStatHeader.Size = UDim2.new(0, statWidth, 1, 0)
						local rightOffset = -badgesWidth - ((numStats - i) * statWidth) - 5
						teamStatHeader.Position = UDim2.new(1, rightOffset, 0, 0)
						teamStatHeader.BackgroundTransparency = 1
						teamStatHeader.Text = statName
						teamStatHeader.TextColor3 = dynamicTeamTextColor
						teamStatHeader.TextSize = 9
						teamStatHeader.Font = Enum.Font.BuilderSansBold
						teamStatHeader.TextXAlignment = Enum.TextXAlignment.Center
						teamStatHeader.TextTruncate = Enum.TextTruncate.AtEnd
						teamStatHeader.Parent = teamFrame
					end
				end
				
				table.insert(tempRows, teamFrame)

				for _, plr in ipairs(teamPlayers) do
					table.insert(tempRows, createPlayerRow(plr))
				end
			end
		end
		
		for _, plr in ipairs(neutralPlayers) do
			table.insert(tempRows, createPlayerRow(plr))
		end

		for _, elem in ipairs(tempRows) do
			elem.Parent = scrollingPlayers
		end

		scrollingPlayers.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end)

	hideLoadingCircle()
	isUpdatingList = false

	if updatePending then
		updatePending = false
		requestUpdate(false)
	end
end

requestUpdate = function(showLoading, specificPlayer)
	if specificPlayer and not showLoading then
		if updatePlayerRowOnly(specificPlayer) then
			return
		end
	end
	
	task.spawn(function()
		updatePlayerList(showLoading)
	end)
end

local function connectPlayerStats(plr)
	plr:GetPropertyChangedSignal("Team"):Connect(function() 
		requestUpdate(false, plr) 
	end)
	
	local leaderstats = plr:WaitForChild("leaderstats", 2)
	if leaderstats then
		for _, stat in ipairs(leaderstats:GetChildren()) do
			stat:GetPropertyChangedSignal("Value"):Connect(function() 
				requestUpdate(false, plr) 
			end)
		end
		leaderstats.ChildAdded:Connect(function(stat)
			if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
				stat:GetPropertyChangedSignal("Value"):Connect(function() 
					requestUpdate(false, plr) 
				end)
			end
			requestUpdate(false)
		end)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	connectPlayerStats(plr)
end

Players.PlayerAdded:Connect(function(plr)
	connectPlayerStats(plr)
	requestUpdate(false)
end)

Players.PlayerRemoving:Connect(function() requestUpdate(false) end)
Teams.ChildAdded:Connect(function() requestUpdate(false) end)
Teams.ChildRemoved:Connect(function() requestUpdate(false) end)

requestUpdate(true)

task.spawn(function()
	while task.wait(3) do
		if isOpen then
			for _, plr in ipairs(Players:GetPlayers()) do
				updatePlayerRowOnly(plr)
			end
		end
	end
end)

closeProfileBtn.MouseButton1Click:Connect(function()
	local pos = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
	animateClose(profileModal, pos, function()
		cleanup3D()
	end)
end)

blockBtn.MouseButton1Click:Connect(function()
	if selectedTargetPlayer and selectedTargetPlayer ~= localPlayer then
		local posProf = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
		animateClose(profileModal, posProf, function()
			cleanup3D()
			cmText.Text = currentLang.BlockText
			cmActionBtn.Text = currentLang.Block
			pendingAction = "Block"
			local posConf = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
			animateOpen(confirmModal, posConf)
		end)
	end
end)

avatarBtn.MouseButton1Click:Connect(function()
	if selectedTargetPlayer then
		pcall(function() GuiService:InspectPlayerFromUserId(selectedTargetPlayer.UserId) end)
	end
end)

friendBtn.MouseButton1Click:Connect(function()
	if not selectedTargetPlayer or selectedTargetPlayer == localPlayer then return end
	if localPlayer:IsFriendsWith(selectedTargetPlayer.UserId) then
		local posProf = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -150, 0.5, -202)
		animateClose(profileModal, posProf, function()
			cleanup3D()
			cmText.Text = currentLang.UnAddText
			cmActionBtn.Text = currentLang.UnAddFriend
			pendingAction = "UnAdd"
			local posConf = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
			animateOpen(confirmModal, posConf)
		end)
	else
		pcall(function() StarterGui:SetCore("PromptSendFriendRequest", selectedTargetPlayer) end)
		closeLeaderboard()
	end
end)

disrespectfulBtn.MouseButton1Click:Connect(function()
	if not selectedTargetPlayer or selectedTargetPlayer == localPlayer me return end
	local uidStr = tostring(selectedTargetPlayer.UserId)
	if settingsData.DisrespectfulUsers[uidStr] then
		settingsData.DisrespectfulUsers[uidStr] = nil
		disrespectfulBtn.Text = currentLang.Disrespectful
	else
		settingsData.DisrespectfulUsers[uidStr] = true
		disrespectfulBtn.Text = currentLang.RemoveDisrespectful
	end
	saveSettings()
	requestUpdate(false, selectedTargetPlayer)
end)

cmCancelBtn.MouseButton1Click:Connect(function()
	local pos = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
	animateClose(confirmModal, pos)
end)

cmActionBtn.MouseButton1Click:Connect(function()
	if pendingAction == "UnAdd" and selectedTargetPlayer then
		pcall(function() StarterGui:SetCore("PromptUnfriendPlayer", selectedTargetPlayer) end)
	elseif pendingAction == "Block" and selectedTargetPlayer then
		pcall(function() StarterGui:SetCore("PromptBlockPlayer", selectedTargetPlayer) end)
		closeLeaderboard()
	end
	local pos = isMobile and UDim2.new(0.5, -135, 0.5, -80) or UDim2.new(0.5, -155, 0.5, -85)
	animateClose(confirmModal, pos)
	requestUpdate(false)
end)

applyThemeAndLang()
