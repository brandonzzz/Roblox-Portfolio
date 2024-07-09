-- GITHUB COMMENT: This is a script I use in various games to easily apply advanced movement mechanics. I usually pair it with screen bobbing effects if it's in first person.

local plr = game.Players.LocalPlayer
local hum = plr.Character:FindFirstChildOfClass("Humanoid")

local CAS = game:GetService("ContextActionService")
local SOUND = game:GetService("SoundService")
local TS = game:GetService("TweenService")

-- vars

local smallButNotZero = 0.02

local lastInputType = nil
local sprinting = false
local sprintPower = 1
local maxPower = 1.8
local timeUntilMaxSprint = 0.33

local sneaking = false
local sneakSpeed = game.StarterPlayer.CharacterWalkSpeed * .7
local sneakIdleTrack = hum:FindFirstChildOfClass("Animator"):LoadAnimation(script:WaitForChild('SneakIdle'))
local sneakWalkTrack = hum:FindFirstChildOfClass("Animator"):LoadAnimation(script:WaitForChild('SneakWalk'))

local swimmingSpeed = 15

-- sneaking

-- lastspeed var stops the "play walk animation" part of the script from running when not necessary: avoids glitchy looking animations
local lastspeed = false

function sneakRunning(runningSpeed)
	if not sneaking then return end
	if runningSpeed > smallButNotZero then
		if not lastspeed then
			-- If moving, play walk animation
			sneakIdleTrack:Stop(.3)
			sneakWalkTrack:Play(.3, 1, 0.6)
			lastspeed = true
		end
	else
		-- If still, play idle animation
		sneakIdleTrack:Play(.3, 1, 1)
		sneakWalkTrack:Stop(.3)
		lastspeed = false
	end
end

hum.Running:Connect(function(runningSpeed)
	sneakRunning(runningSpeed)
end)

function startSneaking()
	if hum:GetState() ~= Enum.HumanoidStateType.Swimming and not sprinting then
		sneaking = true
		hum.WalkSpeed = sneakSpeed
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		SOUND.FootstepSounds.Volume = 0.3
		sneakRunning(hum.MoveDirection.Magnitude)
	end
end

function stopSneaking()
	hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
	sprintPower = 1
	-- Double check to not allow jumping while swimming
	if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	sneaking = false
	sneakIdleTrack:Stop(.3)
	sneakWalkTrack:Stop(.3)
	SOUND.FootstepSounds.Volume = 1
	lastspeed = false
end

CAS:BindAction('SneakKey', function(actionName, inputState, inputObject)
	if inputObject.UserInputType == Enum.UserInputType.Touch and sprinting then
		sprinting = false
		CAS:SetTitle('SprintKey', 'Run')
	end
	if inputState == Enum.UserInputState.Begin then
		if sneaking then
			stopSneaking()
			CAS:SetTitle('SneakKey', 'Sneak')
		elseif not sneaking then
			startSneaking()
			CAS:SetTitle('SneakKey', 'Stand')
		end
	end
end, true, Enum.KeyCode.LeftControl, Enum.KeyCode.C, Enum.KeyCode.ButtonB)

-- swimming

-- disable jumping immediately when swimming starts, to avoid a situation where player can jump across ocean
-- player should also lose access to tools while swimming
hum.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Swimming then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		stopSneaking()
		hum.WalkSpeed = swimmingSpeed
		game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		hum:UnequipTools()
	end
end)

-- walking

CAS:BindAction('SprintKey', function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if inputObject.UserInputType == Enum.UserInputType.Gamepad1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			lastInputType = inputObject.UserInputType
			sprinting = not sprinting
			if sprinting then
				CAS:SetTitle('SprintKey', 'Walk')
			elseif not sprinting then
				CAS:SetTitle('SprintKey', 'Run')
			end
		else
			sprinting = true
		end
	elseif inputState == Enum.UserInputState.End then
		if inputObject.UserInputType ~= Enum.UserInputType.Gamepad1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then
			sprinting = false
		end
	end
end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)

-- Buttons

local sneakButton = CAS:GetButton('SneakKey')
local sprintButton = CAS:GetButton('SprintKey')

CAS:SetTitle('SprintKey', 'Run')
CAS:SetTitle('SneakKey', 'Sneak')
CAS:SetPosition('SprintKey', UDim2.new(.8, 0, .15, 0))
CAS:SetPosition('SneakKey', UDim2.new(.6, 0, .15, 0))

-- loop

local waitTime = 0.2
while hum do
	
	task.wait(waitTime)
	-- Prevents jumping while swimming.
	if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
		
		-- When player exits water, their tools should come back.
		if hum.FloorMaterial ~= Enum.Material.Air then
			game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		end
		
		if sprinting and sneaking then
			stopSneaking()
			CAS:SetTitle('SneakKey', 'Sneak')
		end
		
		if sprinting and hum.MoveDirection == Vector3.new(0, 0, 0) and (lastInputType == Enum.UserInputType.Gamepad1) then
			sprinting = false
		end
		
		-- Prevents jumping on top of water, since the character temporarily enters a "Running" state
		-- But we have to also double check to not accidentally enable jumping while sneaking.
		if hum.FloorMaterial ~= Enum.Material.Air and not sneaking then
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
		
		-- The rest of the script involves sprinting. We don't wanna run sprinting code while sneaking.
		-- It's impossible to be sprinting and sneaking at the same time.
		if not sneaking then
			
			local increment = maxPower - 1
			increment *= waitTime / timeUntilMaxSprint

			if sprinting then
				sprintPower += increment
			else
				sprintPower -= increment
			end

			if sprintPower < 1 then
				sprintPower = 1
			elseif sprintPower > maxPower then
				sprintPower = maxPower
			end

			hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed * sprintPower
			
		end
		
	end
	
end
