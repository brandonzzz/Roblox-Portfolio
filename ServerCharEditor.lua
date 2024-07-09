-- Most of my code is too organized to have 200 full lines in a single script, but here you go.

local plr = script.Parent.Parent.Parent.Parent.Parent

local frame = script.Parent
local bodyColors = frame.BodyColorsFrame
local categories = frame.CategoryButtons
local inventoryFrame = frame.InventoryViewer
local preview = frame.Preview
local previewWorld = preview.Viewport.WorldModel
local wearingFrame = frame.WearingViewer

local SSS = game:GetService("ServerScriptService")
local charMod = require(SSS.ServerCharacter.CharacterModule)
local PDH = require(SSS.DataServices.PlayerDataHandler)
local CDH = require(SSS.DataServices.CatalogDataHandler)
local SS = game:GetService("ServerStorage")

local event = frame.CharacterEditEvent
local invPrevs = SS.GuiStorage.InventoryPreviews

-- Setup
local newChar = charMod:GenerateCharFromData(plr)
previewWorld.DisplayCharacter:Destroy()
newChar.Name = "DisplayCharacter"
newChar.Parent = previewWorld

bodyColors.Head.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "HeadColor"))
bodyColors.LeftArm.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "LeftArmColor"))
bodyColors.RightArm.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "RightArmColor"))
bodyColors.Torso.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "TorsoColor"))
bodyColors.LeftLeg.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "LeftLegColor"))
bodyColors.RightLeg.BackgroundColor3 = PDH:DecodeColor(PDH:Get(plr, "RightLegColor"))

--

event.OnServerEvent:Connect(function(sender, editType, val, val2)
	if sender == plr then
		if editType == "BodyColor" then
			local bodyPart = respace(val)
			local color = val2
			
			-- Update Data
			PDH:Set(plr, val.."Color", PDH:EncodeColor(color))
			-- Update Viewport
			previewWorld:FindFirstChild("DisplayCharacter"):FindFirstChild(bodyPart).Color = color
			-- Update Character
			if plr.Character and plr.Character:FindFirstChild(bodyPart) then
				plr.Character[bodyPart].Color = color
			end
		elseif editType == "Load" then
			local category = val
			local pg = val2
			
			local items = PDH:Get(plr, category)
			for _, frame in inventoryFrame:GetChildren() do
				if frame:IsA("ViewportFrame") or frame:IsA("ImageLabel") then
					frame:Destroy()
				end
			end
			
			local section = CDH.SectionReferences[category]
			
			for i = (pg-1) * 12 + 1, pg * 12 do
				local itemId = items[i]
				if itemId then
					
					-- Check if item has already been loaded (meaning user has more than 1)
					local loaded
					for _, frame in inventoryFrame:GetChildren() do
						if frame:IsA("ViewportFrame") or frame:IsA("ImageLabel") then
							if frame.ItemId.Value == itemId and frame.Category.Value == category then
								loaded = frame
							end
						end
					end
					if loaded then
						local newQuantity = string.sub(loaded.quantityLabel.Text, 1, string.len(loaded.quantityLabel.Text) - 1)
						newQuantity = string.split(newQuantity, "You have ")[2]
						newQuantity = tostring(tonumber(newQuantity) + 1)
						loaded.quantityLabel.Text = "You have "..newQuantity.."."
						loaded.quantityLabel.Visible = true
					else
						
						if section == "Accessories" then
							local data = CDH:DecodeAccessoryData(CDH:GetAssetData(itemId, section))
							local entry = invPrevs.Accessories:Clone()
							entry.ItemId.Value = itemId
							entry.Category.Value = category
							entry.Name = data.Name
							charMod:LoadAccessory(data).Parent = entry.WorldModel
							entry.Parent = inventoryFrame
							if CDH:IsWearing(plr, category, itemId) then
								entry.Wearing.Value = true
							end
						elseif section == "Clothing" then
							local data = CDH:DecodeClothingData(CDH:GetAssetData(itemId, section))
							local entry = invPrevs.Clothing:Clone()
							entry.ItemId.Value = itemId
							entry.Category.Value = category
							entry.Name = data.Name
							charMod:ApplyClothing(entry.WorldModel.Mannequin, itemId)
							entry.Parent = inventoryFrame
							if CDH:IsWearing(plr, category, itemId) then
								entry.Wearing.Value = true
							end
						elseif section == "Faces" then
							local data = CDH:DecodeFaceData(CDH:GetAssetData(itemId, section))
							local entry = invPrevs.Faces:Clone()
							entry.ItemId.Value = itemId
							entry.Category.Value = category
							entry.Name = data.Name
							entry.Image = 'rbxassetid://'..data.FaceId
							entry.ImageTransparency = data.Transparency
							entry.Parent = inventoryFrame
							if CDH:IsWearing(plr, category, itemId) then
								entry.Wearing.Value = true
							end
						elseif section == "Meshes" then
							local data = CDH:DecodeMeshData(CDH:GetAssetData(itemId, section))
							local entry = invPrevs.Meshes:Clone()
							entry.ItemId.Value = itemId
							entry.Category.Value = category
							entry.Name = data.Name
							charMod:ApplyMesh(entry.WorldModel.Mannequin, data)
							entry.Parent = inventoryFrame
							if CDH:IsWearing(plr, category, itemId) then
								entry.Wearing.Value = true
							end
						elseif section == "Packages" then
							local data = CDH:DecodePackageData(CDH:GetAssetData(itemId, section))
							local entry = invPrevs.Packages:Clone()
							entry.ItemId.Value = itemId
							entry.Category.Value = category
							entry.Name = data.Name
							local CM = charMod
							local ch = entry.WorldModel.Mannequin
							CM:ApplyMesh(ch, data.LeftArm) CM:ApplyMesh(ch, data.RightArm) CM:ApplyMesh(ch, data.Torso)
							CM:ApplyMesh(ch, data.LeftLeg) CM:ApplyMesh(ch, data.RightLeg) CM:ApplyMesh(ch, data.Head)
							CM:ApplyFace(ch, data.Face) CM:ApplyClothing(ch, data.TShirt) CM:ApplyClothing(ch, data.Shirt)
							CM:ApplyClothing(ch, data.Pants) CM:ApplyAccessory(ch, data.Accessory1)
							CM:ApplyAccessory(ch, data.Accessory2) CM:ApplyAccessory(ch, data.Accessory3)
							entry.Parent = inventoryFrame
						end
						
					end
				else
					break
				end
			end
			
			if pg > 1 then
				inventoryFrame.UngriddedElements.ScrollLeft.Visible = true
			else
				inventoryFrame.UngriddedElements.ScrollLeft.Visible = false
			end
			if #items > 12 * pg then
				inventoryFrame.UngriddedElements.ScrollRight.Visible = true
			else
				inventoryFrame.UngriddedElements.ScrollRight.Visible = false
			end
		elseif editType == "Wear" then
			local category = val
			local itemId = val2
			wearItem(category, itemId)
			
		elseif editType == "Unwear" then
			local category = val
			local itemId = val2
			unwearItem(category, itemId)
			refreshWearing()
			
		elseif editType == "LoadWearing" then
			frame.WearingPage.Value = val
			refreshWearing()
		end
	end
end)

function refreshWearing()
	local pg = frame.WearingPage.Value

	for _, frame in wearingFrame:GetChildren() do
		if frame:IsA("ViewportFrame") or frame:IsA("ImageLabel") then
			frame:Destroy()
		end
	end
	local acc1 = PDH:Get(plr, "Accessory1")
	local acc2 = PDH:Get(plr, "Accessory2")
	local acc3 = PDH:Get(plr, "Accessory3")
	local shrt = PDH:Get(plr, "Shirt")
	local pant = PDH:Get(plr, "Pant")
	local tees = PDH:Get(plr, "TShirt")
	local face = PDH:Get(plr, "Face")
	local head = PDH:Get(plr, "HeadMesh")
	local larm = PDH:Get(plr, "LeftArmMesh")
	local rarm = PDH:Get(plr, "RightArmMesh")
	local tors = PDH:Get(plr, "TorsoMesh")
	local lleg = PDH:Get(plr, "LeftLegMesh")
	local rleg = PDH:Get(plr, "RightLegMesh")

	local function loadWearingItem(cat, id)
		if cat == "Accessories" then
			local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Accessories"):Clone()
			entry.ItemId.Value = id
			entry.Category.Value = "Accessories"
			local data = CDH:DecodeAccessoryData(CDH:GetAssetData(id, CDH.SectionReferences["Accessories"]))
			entry.Name = data.Name
			charMod:LoadAccessory(data).Parent = entry.WorldModel
			entry.Parent = wearingFrame
		elseif cat == "Clothing" then
			local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Clothing"):Clone()
			entry.ItemId.Value = id
			local data = CDH:DecodeClothingData(CDH:GetAssetData(id, "Clothing"))
			entry.Category.Value = data.Type
			entry.Name = data.Name
			charMod:ApplyClothing(entry.WorldModel.Mannequin, id)
			entry.Parent = wearingFrame
		elseif cat == "Faces" then
			local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Faces"):Clone()
			entry.ItemId.Value = id
			local data = CDH:DecodeFaceData(CDH:GetAssetData(id, "Faces"))
			entry.Category.Value = "Faces"
			entry.Name = data.Name
			entry.Image = 'rbxassetid://'..data.FaceId
			entry.ImageTransparency = data.Transparency
			entry.Parent = wearingFrame
		elseif cat == "Meshes" then
			local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Meshes"):Clone()
			entry.ItemId.Value = id
			local data = CDH:DecodeMeshData(CDH:GetAssetData(id, "Meshes"))
			entry.Category.Value = data.BodyPart
			entry.Name = data.Name
			charMod:ApplyMesh(entry.WorldModel.Mannequin, id)
			entry.Parent = wearingFrame
		end
	end

	local wearingIds = {acc1, acc2, acc3, shrt, pant, tees, face, head, larm, rarm, tors, lleg, rleg}
	local wearingTable = {}
	for ind, id in wearingIds do
		if id ~= 0 then
			local cat
			if ind < 4 then cat = "Accessories"
			elseif ind < 7 then cat = "Clothing"
			elseif ind == 7 then cat = "Faces"
			elseif ind > 7 then cat = "Meshes" end
			table.insert(wearingTable, {Category = cat, Id = id})
		end
	end

	for i = (pg - 1) * 12 + 1, 12 * pg do
		local deta = wearingTable[i]
		if deta then
			loadWearingItem(deta.Category, deta.Id)
		else
			break
		end
	end

	if #wearingTable > 12 * pg then
		wearingFrame.UngriddedElements.ScrollRight.Visible = true
	else
		wearingFrame.UngriddedElements.ScrollRight.Visible = false
	end
	if pg > 1 then
		wearingFrame.UngriddedElements.ScrollLeft.Visible = true
	else
		wearingFrame.UngriddedElements.ScrollLeft.Visible = false
	end
end

function wearItem(category, itemId, pkItem)
	frame.cooldown.Value = true
	-- SECURITY LINE
	if not CDH:HasAsset(plr, category, itemId) then return end
	if category ~= "Packages" and CDH:IsWearing(plr, category, itemId) then return end

	local itemCreated
	local previewItem

	if category == "Accessories" then
		-- Equip item
		local data = CDH:DecodeAccessoryData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		if plr.Character then
			itemCreated = charMod:LoadAccessory(data)
			itemCreated.Parent = plr.Character
		end
		previewItem = charMod:LoadAccessory(data)
		previewItem.Parent = previewWorld:FindFirstChild("DisplayCharacter")
		
		if PDH:Get(plr, "Accessory1") ~= 0 then
			if PDH:Get(plr, "Accessory2") ~= 0 then
				if PDH:Get(plr, "Accessory3", itemId) ~= 0 then
					-- UNWEAR ACCESSORY (max already worn)
					local unwearId = PDH:Get(plr, "Accessory1")
					unwearItem(category, unwearId)
					event:FireClient(plr, "Unworn", category, unwearId)
					-- MOVE OTHER ACCESSORIES FORWARD
					-- not necessary- unwear function does this already
					-- PLACE NEW ACCESSORY
					PDH:Set(plr, "Accessory3", itemId)
				else
					PDH:Set(plr, "Accessory3", itemId)
				end
			else
				PDH:Set(plr, "Accessory2", itemId)
			end
		else
			PDH:Set(plr, "Accessory1", itemId)
		end
		--[[ Create "wearing" entry
		task.wait()
		local entry = SS.GuiStorage.WearingPreviews.Accessories:Clone()
		entry.ItemId.Value = itemId
		entry.Category.Value = category
		entry.Name = data.Name
		charMod:LoadAccessory(data).Parent = entry.WorldModel -- In entry, not preview.
		entry.Parent = wearingFrame]]
		
	elseif category == "Shirts" or category == "Pants" or category == "TShirts" then
		-- Equip item
		local data = CDH:DecodeClothingData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		if plr.Character then
			itemCreated = charMod:LoadClothing(data)
			itemCreated.Parent = plr.Character
		end
		previewItem = charMod:LoadClothing(data)
		previewItem.Parent = previewWorld:FindFirstChild("DisplayCharacter")

		if data.Type == "Shirts" then
			if PDH:Get(plr, "Shirt") ~= 0 then
				-- UNWEAR SHIRT before replacing
				local unwearId = PDH:Get(plr, "Shirt")
				unwearItem(category, unwearId)
				event:FireClient(plr, "Unworn", category, unwearId)
			end
			PDH:Set(plr, "Shirt", itemId)
		elseif data.Type == "Pants" then
			if PDH:Get(plr, "Pant") ~= 0 then
				-- UNWEAR PANTS before replacing
				local unwearId = PDH:Get(plr, "Pant")
				unwearItem(category, unwearId)
				event:FireClient(plr, "Unworn", category, unwearId)
			end
			PDH:Set(plr, "Pant", itemId)
		elseif data.Type == "TShirts" then
			if PDH:Get(plr, "TShirt") ~= 0 then
				-- UNWEAR TSHIRT before replacing
				local unwearId = PDH:Get(plr, "TShirt")
				unwearItem(category, unwearId)
				event:FireClient(plr, "Unworn", category, unwearId)
			end
			PDH:Set(plr, "TShirt", itemId)
		end
		--[[Create "wearing" entry
		local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Clothing"):Clone()
		entry.ItemId.Value = itemId
		local data = CDH:DecodeClothingData(CDH:GetAssetData(itemId, "Clothing"))
		entry.Category.Value = category
		entry.Name = data.Name
		charMod:ApplyClothing(entry.WorldModel.Mannequin, itemId)
		entry.Parent = wearingFrame]]
		
	elseif category == "Faces" then
		-- Equip item
		local data = CDH:DecodeFaceData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		if plr.Character then
			charMod:ApplyFace(plr.Character, itemId)
		end
		charMod:ApplyFace(previewWorld:FindFirstChild("DisplayCharacter"), data)

		if PDH:Get(plr, "Face") ~= 0 then
			local unwearId = PDH:Get(plr, "Face")
			unwearItem(category, unwearId)
			event:FireClient(plr, "Unworn", category, unwearId)
		end
		PDH:Set(plr, "Face", itemId)
		--[[ Create "Wearing" entry
		local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Faces"):Clone()
		entry.ItemId.Value = itemId
		local data = CDH:DecodeFaceData(CDH:GetAssetData(itemId, "Faces"))
		entry.Category.Value = category
		entry.Name = data.Name
		entry.Image = 'rbxassetid://'..data.FaceId
		entry.ImageTransparency = data.Transparency
		entry.Parent = wearingFrame]]
		
	elseif CDH.SectionReferences[category] == "Meshes" then
		local nonplural = string.sub(category, 1, string.len(category) - 2)
		-- Equip item
		local data = CDH:DecodeMeshData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		if plr.Character then
			charMod:ApplyMesh(plr.Character, itemId)
		end
		charMod:ApplyMesh(previewWorld:FindFirstChild("DisplayCharacter"), data)

		if PDH:Get(plr, nonplural) ~= 0 then --Shave off plural
			local unwearId = PDH:Get(plr, nonplural)
			unwearItem(category, unwearId)
			event:FireClient(plr, "Unworn", category, unwearId)
		end
		PDH:Set(plr, nonplural, itemId)
		--[[ Create "Wearing" entry
		local entry = SS.GuiStorage.WearingPreviews:FindFirstChild("Meshes"):Clone()
		entry.ItemId.Value = itemId
		local data = CDH:DecodeMeshData(CDH:GetAssetData(itemId, "Meshes"))
		entry.Category.Value = category
		entry.Name = data.Name
		charMod:ApplyMesh(entry.WorldModel.Mannequin, itemId)
		entry.Parent = wearingFrame]]
		
	elseif CDH.SectionReferences[category] == "Packages" then
		-- Equip item
		local data = CDH:DecodePackageData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		wearItem("LeftArmMeshes", tonumber(data.LeftArm), true)
		wearItem("RightArmMeshes", tonumber(data.RightArm), true)
		wearItem("TorsoMeshes", tonumber(data.Torso), true)
		wearItem("LeftLegMeshes", tonumber(data.LeftLeg), true)
		wearItem("RightLegMeshes", tonumber(data.RightLeg), true)
		wearItem("HeadMeshes", tonumber(data.Head), true)
		wearItem("Faces", tonumber(data.Face), true)
		wearItem("TShirts", tonumber(data.TShirt), true)
		wearItem("Shirts", tonumber(data.Shirt), true)
		wearItem("Pants", tonumber(data.Pants), true)
		wearItem("Accessories", tonumber(data.Accessory1), true)
		wearItem("Accessories", tonumber(data.Accessory2), true)
		wearItem("Accessories", tonumber(data.Accessory3), true)
	end
	-- Add Attributes
	if itemCreated then
		itemCreated:SetAttribute("Category", category)
		itemCreated:SetAttribute("ItemId", itemId)
	end
	if previewItem then
		previewItem:SetAttribute("Category", category)
		previewItem:SetAttribute("ItemId", itemId)
	end
	
	if not pkItem then
		frame.cooldown.Value = false
		refreshWearing()
	end
end

function unwearItem(category, itemId)
	if category == "Accessories" then
		local data = CDH:DecodeAccessoryData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		-- Set Data to Empty & scoot other data forward
		if PDH:Get(plr, "Accessory1") == itemId then
			PDH:Set(plr, "Accessory1", PDH:Get(plr, "Accessory2"))
			PDH:Set(plr, "Accessory2", PDH:Get(plr, "Accessory3"))
			PDH:Set(plr, "Accessory3", 0)
		elseif PDH:Get(plr, "Accessory2") == itemId then
			PDH:Set(plr, "Accessory2", PDH:Get(plr, "Accessory3"))
			PDH:Set(plr, "Accessory3", 0)
		elseif PDH:Get(plr, "Accessory3") == itemId then
			PDH:Set(plr, "Accessory3", 0)
		end
		-- Remove from preview
		for _, i in previewWorld:FindFirstChild("DisplayCharacter"):GetChildren() do
			if i:GetAttribute("Category") == CDH.SectionReferences[category] and i:GetAttribute("ItemId") == itemId then
				i:Destroy()
			end
		end
		-- Remove from character
		if plr.Character then
			for _, i in plr.Character:GetChildren() do
				if i:GetAttribute("Category") == CDH.SectionReferences[category] and i:GetAttribute("ItemId") == itemId then
					i:Destroy()
				end
			end
		end
	elseif category == "Clothing" or category == "Shirts" or category == "Pants" or category == "TShirts" then
		local data = CDH:DecodeClothingData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		-- Set data to empty
		if PDH:Get(plr, "Shirt") == itemId then
			PDH:Set(plr, "Shirt", 0)
		elseif PDH:Get(plr, "Pant") == itemId then
			PDH:Set(plr, "Pant", 0)
		elseif PDH:Get(plr, "TShirt") == itemId then
			PDH:Set(plr, "TShirt", 0)
		end
		-- Remove from preview
		for _, i in previewWorld:FindFirstChild("DisplayCharacter"):GetChildren() do
			if i:GetAttribute("Category") == category and i:GetAttribute("ItemId") == itemId then
				i:Destroy()
			end
		end
		-- Remove from Character
		if plr.Character then
			for _, i in plr.Character:GetChildren() do
				if i:GetAttribute("Category") == category and i:GetAttribute("ItemId") == itemId then
					i:Destroy()
				end
			end
		end
	elseif category == "Faces" then
		local data = CDH:DecodeFaceData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		-- Set data to empty
		if PDH:Get(plr, "Face") == itemId then
			PDH:Set(plr, "Face", 0)
		end
		-- Remove from preview
		previewWorld:FindFirstChild("DisplayCharacter").Head.face.Texture = 'rbxasset://textures/face.png'
		previewWorld:FindFirstChild("DisplayCharacter").Head.face.Transparency = 0
		-- Remove from Character
		if plr.Character and plr.Character:FindFirstChild("Head") then
			if not plr.Character.Head:FindFirstChild("face") then Instance.new("Decal", plr.Character.Head).Name = "face" end
			plr.Character.Head.face.Texture = 'rbxasset://textures/face.png'
			plr.Character.Head.face.Transparency = 0
		end
	elseif CDH.SectionReferences[category] == "Meshes" then
		local nonplural = string.sub(category, 1, string.len(category) - 2)
		local data = CDH:DecodeMeshData(CDH:GetAssetData(itemId, CDH.SectionReferences[category]))
		-- Set Data to empty
		if PDH:Get(plr, nonplural) == itemId then
			PDH:Set(plr, nonplural, 0)
		end
		-- Remove from preview
		if nonplural ~= "HeadMesh" then
			previewWorld:FindFirstChild("DisplayCharacter"):FindFirstChild(nonplural):Destroy()
		else
			previewWorld:FindFirstChild("DisplayCharacter").Head.Mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			previewWorld:FindFirstChild("DisplayCharacter").Head.Mesh.MeshType = Enum.MeshType.Head
		end
		-- Remove from Character
		if plr.Character and plr.Character:FindFirstChild("Head") then
			if nonplural ~= "HeadMesh" then
				plr.Character:FindFirstChild(nonplural):Destroy()
			else
				plr.Character.Head.Mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
				plr.Character.Head.Mesh.MeshType = Enum.MeshType.Head
			end
		end
	end
end

--

function respace(str)
	local newstr, num = str:gsub("%u", " %0"):gsub("^%s+", "") return newstr
	-- %u represents uppercase letters. %0 represents the part being replaced. Inserts a space before uppercase characters.
end
