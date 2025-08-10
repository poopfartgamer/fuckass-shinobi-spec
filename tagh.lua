local FindFirstChild,WaitForChild = game.FindFirstChild,game.WaitForChild
local GetChildren,GetDescendants = game.GetChildren,game.GetDescendants
local CollectionService = game:GetService("CollectionService")
local commands = require(game.ServerScriptService.Modules.Commands)
local TemperatureHandler = require(game.ServerScriptService.Modules.TemperatureHandler)
local u4 = require(game.ServerScriptService.Modules.EffectModule)
local combatanims = game.ReplicatedStorage.CombatAnims
local TweenService = game:GetService("TweenService")
local function create(name,deletetime,parent)
	if name == "Knocked" and parent:FindFirstChild("WakingUp") then
		return
	end
	local i = Instance.new("Accessory")
	i.Name = name
	i.Parent = parent
	if (name == "Knocked" and game.Players:FindFirstChild(parent.Name)) and game.ServerStorage.PlayerData[parent.Name].Injuries.Value:find("BrokenRib") then
		if deletetime then
			game.Debris:AddItem(i, deletetime * 1.25)
		end
		for i,v in pairs(parent:GetChildren()) do
			if v.Name == "Knocked" then
				if deletetime then
					game.Debris:AddItem(v, deletetime * 1.25)
				end
			end
		end
	elseif name == "Knocked" then
		if deletetime then
			game.Debris:AddItem(i, deletetime)
		end
		for i,v in pairs(parent:GetChildren()) do
			if v.Name == "Knocked" then
				if deletetime then
					game.Debris:AddItem(v, deletetime)
				end
			end
		end
	else
		if deletetime then
			game.Debris:AddItem(i, deletetime)
		end
	end
	return i
end

local function changetransparency(enemy,transparency)
	enemy.Torso.Transparency = transparency
	for _,v in pairs(GetChildren(enemy.Torso))do
		if v:IsA("Motor6D")then
			v.Part1.Transparency = transparency
		end
	end
	for i,v in pairs(enemy:GetDescendants()) do
		if v.Name == "EnchantEffect" then
			if transparency == 1 then
				v.Enabled = false
			else
				v.Enabled = true
			end
		end
	end
end

local function plantedcheck(v)
	if FindFirstChild(v,"Planted")then
		return true
	else
		return false
	end
end

local function wrap(...)
	coroutine.wrap(...)()
end

local function bodyvelocitycheck(c, checkit)
	local children = GetChildren(c.HumanoidRootPart)
	for i = 1,#children do
		local v = children[i]
		if v.ClassName == "BodyVelocity"then
			v:Destroy()
		end
	end
end

local function hitknockback(root,parent)
	if not plantedcheck(parent.Parent)then
		bodyvelocitycheck(parent.Parent)
		local bv = Instance.new("BodyVelocity")
		CollectionService:AddTag(bv,"AllowedBM")
		local novel = Instance.new("Accessory")
		novel.Name = "noveloc"
		novel.Parent = c
		game.Debris:AddItem(novel,0.15)
		bv.MaxForce = Vector3.new(1000000,0,1000000)
		bv.Velocity = root.CFrame.LookVector.unit*10
		bv.Parent = parent
		game.Debris:AddItem(bv,0.15)
	end
end

local function soundplay(part,sound,pitch)
	if FindFirstChild(part,sound)then
		local sound = part[sound]
		if pitch then
			sound.Pitch = tonumber(pitch)
		end
		sound:Play()
	end
end

local FlowingParry = game.ServerStorage.NPCAnims.FlowingParry

local function Send(Title, Content, Color)
	game.ServerStorage.Requests.SendWebhook:Fire(
		Title,
		Content,
		Color
	)
end

local function getCurseCount(Character)
	local count = 0;
	for i,v in pairs(Character.HumanoidRootPart:GetChildren()) do
		if v.Name == "Cursey" and v.Enabled == true then
			count += 1
		end
	end
	return count
end

function taghumanoid(character,enemy,info)
	local anyreturn = nil
	if FindFirstChild(enemy,"Grabbed")then
		return
	end
	if FindFirstChild(enemy,"ForceField")then
		return
	end
	local Player = game.Players:GetPlayerFromCharacter(character)or nil
	local EnemyPlayer = game.Players:GetPlayerFromCharacter(enemy)or nil
	local cancellingthat = false
	local blocking = FindFirstChild(enemy,"Blocking")
	local enemydata = EnemyPlayer and game.ServerStorage.PlayerData:FindFirstChild(EnemyPlayer.Name)or nil
	local playerdata = Player and game.ServerStorage.PlayerData:FindFirstChild(Player.Name)or nil
	local ehumanoid = enemy:FindFirstChild('Humanoid')
	local humanoid = character:FindFirstChild('Humanoid')
	local root = character:FindFirstChild('HumanoidRootPart')
	local eroot = enemy:FindFirstChild('HumanoidRootPart')
	if not ehumanoid or not humanoid or not root or not eroot then
		return
	end
	if ehumanoid.Health<= 0 then
		return
	end
	if enemydata and info.damage and info.damage <= 0 and enemydata.Injuries.Value ~= "" then
		info.damage = nil
	end
	if info.damage and Player and Player:FindFirstChild("Sect") then
		info.damage *= 2
		if Player:FindFirstChild("Bishop") then
			info.damage *= 2
		end
	end
	if info.damage and EnemyPlayer and EnemyPlayer:FindFirstChild("Sect") then
		info.damage /= 2
		if EnemyPlayer:FindFirstChild("Bishop") then
			info.damage /= 2
		end
	end
	local knockback = false
	local behind = false
	local blocked = false
	local knockm = 35
	if workspace:FindFirstChild("passived") then
		if not (enemy:FindFirstChild("FightAllow") or character:FindFirstChild("FightAllow")) then
			return
		end
	end
	if FindFirstChild(enemy,"TimeStopped")then
		info.downbypass = true
		repeat wait() until not FindFirstChild(enemy,"TimeStopped")
	end
	if FindFirstChild(enemy, "Expansion") then
		if info.damage and info.damage > 0 then
			info.damage *= 5
		end
	end
	local cancelknockback = false

	if enemy:FindFirstChild("MonsterInfo") and enemy.MonsterInfo:FindFirstChild("MonsterType") and enemy.MonsterInfo.MonsterType.Value == "Howler" then
		if info.curse and not info.physical then
			u4.HowlerLannis(enemy)
			return
		end
	end
	if enemy:FindFirstChild("WakingUp") and not info.downbypass then
		return
	end
	if enemy:FindFirstChild("MonsterInfo") and enemy.MonsterInfo:FindFirstChild("MonsterType") and enemy.MonsterInfo.MonsterType.Value == "Terra Serpent" then
		if not game.ServerStorage.PlayerData:FindFirstChild(character.Name) then return end;
		if not info.physical then
			return
		end
	end

	if EnemyPlayer and EnemyPlayer.Backpack:FindFirstChild("Epitaph") and not EnemyPlayer:FindFirstChild("Danger") then
		create("IFRAME",1,enemy)
		create("NoDam",0.1,enemy)
		local dodgeanim = ehumanoid:LoadAnimation(script["Dodge"..math.random(1,2)])
		dodgeanim:Play()
		enemy.HumanoidRootPart.Dodgerr:Play()
		if EnemyPlayer then
			local danger = enemy:FindFirstChild("Danger")or Instance.new("NumberValue",EnemyPlayer)
			danger.Name = "Danger"
			if danger.Value+45<120 then
				danger.Value+=30
			else
				danger.Value = 120
			end
		end
		return
	end
	
		if Player and EnemyPlayer then
	if EnemyPlayer and Player and (EnemyPlayer:FindFirstChild("Sect") and Player:FindFirstChild("Sect")) or (Player and EnemyPlayer and Player:FindFirstChild("Sect") and Player.Sect.Value == EnemyPlayer.Name) or (Player and EnemyPlayer and EnemyPlayer:FindFirstChild("Sect") and EnemyPlayer.Sect.Value == Player.Name) then
		if EnemyPlayer.Sect.Value == Player.Sect.Value or Player.Name == EnemyPlayer.Sect.Value or EnemyPlayer.Name == Player.Sect.Value then
			if info.damage and info.damage > 0 then
				ehumanoid.Health += info.damage
				return
				end
			end
		end

			if workspace.Map:FindFirstChild("Church") then
				local v44, v45 = workspace:FindPartOnRayWithWhitelist(Ray.new(eroot.Position, Vector3.new(0, 1000, 0)), { workspace.AreaMarkers })
		if v44 and v44.Name == "Church of Light" then
			local sectowner = v44:FindFirstChildOfClass("Folder").Name
			
			    if EnemyPlayer and Player then
				if (Player:FindFirstChild("Sect") and Player.Sect.Value == sectowner) or Player.Name == sectowner then
				else
				enemy = character
				eroot = root
				EnemyPlayer = Player
				ehumanoid = humanoid
					enemydata = playerdata
				end
			else
				return
			end
							
					
					

						
						end
				end
			end
	
	if info.cero then
		if enemy:FindFirstChild("Unconscious") then
			for i, v in pairs(enemy:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Transparency = 1
				end
			end
			if enemy:FindFirstChild("HumanoidRootPart") then
				if enemy:FindFirstChild("Extinguish") then
					enemy.Extinguish:Play()
				end
			end
			local EnemyPlayer = game.Players:GetPlayerFromCharacter(enemy) or nil
			if EnemyPlayer then
				for _,v in pairs(GetChildren(EnemyPlayer))do
					if v.Name == "Danger"then
						v:Destroy()
					end
				end
			end
			_G.Death(enemy, character)
		end
		if enemy:FindFirstChild("HumanoidRootPart") and not enemy:FindFirstChild("SpellBlocking") then
			local effect = game.ServerStorage.SpellEffects.Cero.CeroHit:Clone()
			effect.Parent = enemy.HumanoidRootPart
			game.Debris:AddItem(effect, 0.4)
		end
	end

	local minfo = enemy:FindFirstChild("MonsterInfo")
	if minfo then
		if enemy.MonsterInfo:FindFirstChild("MonsterType") and enemy.MonsterInfo.MonsterType.Value ~= "Terra Serpent" and enemy.MonsterInfo.MonsterType.Value ~= "Howler" and enemy.MonsterInfo.MonsterType.Value ~= "Zombie Scroom" and enemy.MonsterInfo.MonsterType.Value ~= "Howwgy" then
			if FindFirstChild(enemy,"Knocked")then
				if not info.curse and not (info.sunlight and game.CollectionService:HasTag(enemy, "Vampirism")) then
					if not info.downbypass and not info.ignoreragdoll then
						return
					end
				elseif info.curse and info.anticurse then
					return
				end
			end
		end
	else
		if FindFirstChild(enemy,"Knocked")then
			if not info.curse and not (info.sunlight and game.CollectionService:HasTag(enemy, "Vampirism")) and not (info.axe and enemy:FindFirstChild("Unconscious")) then
				if not info.downbypass and not info.ignoreragdoll then
					return
				end
			elseif info.curse and info.anticurse then
				return
			end
		end
	end

	if enemy:FindFirstChild("MonsterInfo") and enemy.MonsterInfo:FindFirstChild("MonsterType") and enemy.MonsterInfo.MonsterType.Value == "Terra Serpent" then
		if not game.ServerStorage.PlayerData:FindFirstChild(character.Name) then return end;
		if info.fist and not info.smash then
			if game.ServerStorage.PlayerData[character.Name].Class.Value ~= "Akuma" or game.ServerStorage.PlayerData[character.Name].Class.Value ~= "Oni" then
				enemy.Hitboxes.Hitbox1.MetalClash:Play()
				enemy.Hitboxes.Hitbox1.Sparks:Emit(5)
				return
			end
		elseif info.smash and info.fist and info.damage then
			info.damage *= 2.5
		end
	end

	if info.exhaust then
		if not character:FindFirstChild("decomposingrn") then
			for i,v in pairs(character:GetDescendants()) do
				if v.Name == "FreezeRoot" or v.Name == "Planted" or v.Name == "Hardened" or v.Name == "Action" or (v.Name == "HealthRegen" and v.Parent == character.Boosts) or (v.Name == "ClickDetector" and v.Parent == character.Head)  then
					v:Destroy()
				end
			end
			if game.CollectionService:HasTag(character, "Decomposing") then
				game.CollectionService:RemoveTag(character, "Decomposing")
			end
		elseif character:FindFirstChild("decomposingrn") then
			task.spawn(function()
				repeat wait() until not character:FindFirstChild("decomposingrn")
				wait(1)
				for i,v in pairs(character:GetDescendants()) do
					if v.Name == "FreezeRoot" or v.Name == "Planted" or v.Name == "Hardened" or v.Name == "Action" or (v.Name == "HealthRegen" and v.Parent == character.Boosts) or (v.Name == "ClickDetector" and v.Parent == character.Head)  then
						v:Destroy()
					end
				end
				if game.CollectionService:HasTag(character, "Decomposing") then
					game.CollectionService:RemoveTag(character, "Decomposing")
				end
			end)
		end
	end

	if info.executes and game.ServerStorage.PlayerData:FindFirstChild(enemy.Name) and game.ServerStorage.PlayerData:FindFirstChild(enemy.Name).Race.Value == "Cameo" then
		info.executes = false
	end
	if (info.executes and info.damage and not enemy:FindFirstChild("Knocked") and not enemy:FindFirstChild("Unconscious") and not enemy:FindFirstChild("SpellBlocking")) or (info.executes and info.damage and info.axe) then
		if (enemy.Humanoid.Health-info.damage<=0 and info.executes) or (info.axe and enemy:FindFirstChild("Unconscious")) then
			if enemy.Humanoid.Health>0 then
				if Player and FindFirstChild(Player.Backpack,"NoKill")then
					if EnemyPlayer then
						for _,v in pairs(GetChildren(EnemyPlayer))do
							if v.Name == "Danger"then
								v:Destroy()
							end
						end
					end
				end
				_G.Death(enemy,character)
			end
			return
		end
	end
	if FindFirstChild(enemy,"Immortal") or FindFirstChild(enemy,"IFRAME") then
		if (info.falldamage and enemy:FindFirstChild("FallDamageBypass")) or info.torture2 or (info.falldamage and FindFirstChild(enemy, "Dissolved")) then
		else
			return
		end
	end
	if character.Parent ~= workspace.Live and not character:FindFirstChild("LichSummon") then
		return
	end
	if enemy.Parent ~= workspace.Live and not enemy:FindFirstChild("LichSummon") then
		return
	end
	if enemy:FindFirstChild("Hallucination") or character:FindFirstChild("Hallucination") then
		return
	end
	if game.PlaceId == 9329476718 and not enemy:FindFirstChild("FightAllow") then
		return
	end

	if game.PlaceId == 9329476718 and not character:FindFirstChild("FightAllow") then
		return
	end

	if (CollectionService:HasTag(character,"Vampirism") or character.Boosts:FindFirstChild("SuperStrength") or (playerdata and playerdata.Race.Value == "Cameo")) and info.physical then
		knockm *= 2
	end
	if info.canspellcounter and info.damage and enemy:FindFirstChild("CounterSpell") then
		enemy = character
		enemydata = playerdata
		eroot = root
		ehumanoid = humanoid
		EnemyPlayer = Player
	end
	if info.snarvin and enemy:FindFirstChild("MonShield") then
		if not plantedcheck(enemy) then
			knockback = true
			bodyvelocitycheck(character)
			create("Knocked", 2, character)
			local bv = Instance.new("BodyVelocity")
			CollectionService:AddTag(bv,"AllowedBM")
			bv.MaxForce = Vector3.new(1000000,1000000,1000000)
			bv.Velocity = root.CFrame.lookVector.unit*-35+Vector3.new(0,10,0)
			bv.Parent = root
			eroot.SLAMJAM:Play()
			game.Debris:AddItem(bv,0.5)
			create("ChargeBlock",0.85,enemy)
		end
		return
	end
	if (eroot.Position-root.Position).Unit:Dot(eroot.CFrame.LookVector) >= 0.25 and not FindFirstChild(enemy, "MonShield") then
		behind = true
	end
	if FindFirstChild(enemy,"InDialogue")then
		FindFirstChild(enemy,"InDialogue"):Destroy()
	end
	if info.sparks then
		eroot.Sparks:Emit(20)
	end
	if info.wraithfire then
		local burncolor = Color3.new(0,0,0)
		local manainfo = {}
		manainfo.manastop = true
		manainfo.wraithfire = true
		commands.StartBurn(enemy,eroot,burncolor,manainfo,character)
	end
	if info.pullTo then
		local BP = Instance.new("BodyPosition")
		BP.Name = "pullTo"
		BP.MaxForce = Vector3.new(60000,60000,60000)
		BP.P = 10000	
		BP.D = 500
		BP.Parent = eroot
		BP.Position = info.pullTo
		wait(1)
		BP:Destroy()
	end;
	if info.waterspikes then
		local delay_inbetween = info.delay or 0.2
		for i = 1,info.waterspikes do
			local spike = game.ServerStorage.Assets.Trident.Spike:Clone()
			spike.Parent = game.Workspace.Thrown
			spike.Position = eroot.Position+Vector3.new(math.random(-5,5),-10,math.random(-5,5))
			spike.CFrame = CFrame.lookAt(spike.Position,eroot.Position)
			spike.Orientation = spike.Orientation+Vector3.new(-80,0,0)
			spike.ParticleEmitter:Emit(10)
			game:GetService("Debris"):AddItem(spike,0.6)
			TweenService:Create(spike,TweenInfo.new(0.4),{CFrame=spike.CFrame*CFrame.new(0,spike.Size.Y,0),Transparency = 1}):Play()
			game.ServerStorage.Requests.TagHumanoid:Fire(character,enemy,{physical = true,spear = true,slash = true,damage = info.damage/2.5})
			task.wait(delay_inbetween)
		end
	end
	if info.damage and enemy and enemy:FindFirstChild("Hardened") then
		info.damage /= 5
	end
	if enemy:FindFirstChild("BloodTieMaster") then
		for i,v in ipairs(workspace.Live:GetDescendants()) do
			if v.Name == "BloodTied" and enemy.Name == v.Value  then
				ehumanoid = v.Parent.Humanoid
				if game.Players:FindFirstChild(v.Parent.Name) then
					enemydata = game.ServerStorage.PlayerData[v.Parent.Name]
					EnemyPlayer = game.Players:GetPlayerFromCharacter(v.Parent)
				else
					enemydata = nil
					EnemyPlayer = nil
				end
			end
		end
	end
	if info.death and not FindFirstChild(enemy, "CurseBlocking")then
		coroutine.wrap(function()
			for i,v in pairs(enemy:GetChildren()) do
				if v:IsA("Shirt") or v:IsA("Pants") then
					v:Destroy()
				end
				if v:IsA("Part") or v:IsA("BasePart") then
					local dec = v:FindFirstChildOfClass("Decal")
					if dec then
						dec:Destroy()
					end
					local bv = Instance.new("BodyVelocity")
					game.CollectionService:AddTag(bv,"AllowedBM")
					bv.Velocity = Vector3.new(math.random(-10,10),math.random(-10,10),math.random(-10,10))
					bv.Parent = v
					v.Material = Enum.Material.Neon
					local tweenInfo02 = TweenInfo.new(1.25,	Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
					local tween02 = TweenService:Create(v,tweenInfo02,{Transparency=1,Color=Color3.new()})
					tween02:Play()
				end
				_G.Death(enemy,character,true);
			end
		end)()
		return
	end
	if info.bardragdoll and not FindFirstChild(enemy, "CurseBlocking") then
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1000000,1000000,1000000)
		CollectionService:AddTag(bv,"AllowedBM")
		bv.Velocity = enemy.HumanoidRootPart.CFrame.lookVector.unit * -60
		bv.Parent = eroot
		game.Debris:AddItem(bv, 0.5)
	end
	if info.percent then
		info.damage = enemy.Humanoid.MaxHealth/100 * info.percent
	end
	if info.blacksmithfreeze and not (FindFirstChild(enemy, "CurseBlocking")) and not FindFirstChild(enemy, "CounterSpell") then
		create("Knocked", 1.5, enemy)
		commands.StopBurn(enemy)
		local icecase = game.ServerStorage.SpellEffects.FireWhip.IceCase:Clone()
		icecase.CFrame = eroot.CFrame
		icecase.Weld.Part0 = eroot
		icecase.Weld.Part1 = icecase
		icecase.Parent = enemy
		game.Debris:AddItem(icecase,1.5)
		local bv = Instance.new("BodyVelocity")
		CollectionService:AddTag(bv,"AllowedBM")
		bv.MaxForce = Vector3.new(1000000,1000000,1000000)
		bv.Parent = eroot
		bv.Velocity = eroot.CFrame.lookVector.unit * -60
		game.Debris:AddItem(bv, 0.5)
		task.delay(1.5, function()
			for i,v in pairs(enemy:GetChildren()) do
				if v.Name == "WakingUp" then
					task.wait()
					v:Destroy()
				end
			end
			local slowdown = Instance.new("NumberValue")
			slowdown.Value = -10
			slowdown.Name = "SpeedBoost"
			slowdown.Parent = enemy.Boosts
			game.Debris:AddItem(slowdown,12.5)
			create("Knocked", 2, enemy)
			local bv = Instance.new("BodyVelocity")
			CollectionService:AddTag(bv,"AllowedBM")
			bv.MaxForce = Vector3.new(1000000,1000000,1000000)
			bv.Parent = eroot
			bv.Velocity = eroot.CFrame.lookVector.unit * -40
			game.Debris:AddItem(bv, 0.5)
			game.ServerStorage.Requests.TagHumanoid:Fire(character, enemy, {damage = 10, physical = true, noenchant = true,})
		end)
	elseif info.blacksmithfreeze and (FindFirstChild(enemy, "CurseBlocking")) and not FindFirstChild(enemy, "CounterSpell") then
		info.damage = 0
		local icecase = game.ServerStorage.SpellEffects.FireWhip.IceCase:Clone()
		icecase.CFrame = eroot.CFrame
		icecase.Weld.Part0 = eroot
		icecase.Weld.Part1 = icecase
		icecase.Parent = enemy
		game.Debris:AddItem(icecase,1.5)
		task.delay(1.5, function()
			for i,v in pairs(enemy:GetChildren()) do
				if v.Name == "WakingUp" then
					task.wait()
					v:Destroy()
				end
			end
			if not FindFirstChild(enemy, "CurseBlocking") then
				local slowdown = Instance.new("NumberValue")
				slowdown.Value = -10
				slowdown.Name = "SpeedBoost"
				slowdown.Parent = enemy.Boosts
				game.Debris:AddItem(slowdown,12.5)
				create("Knocked", 2, enemy)
				local bv = Instance.new("BodyVelocity")
				CollectionService:AddTag(bv,"AllowedBM")
				bv.MaxForce = Vector3.new(1000000,1000000,1000000)
				bv.Parent = eroot
				bv.Velocity = eroot.CFrame.lookVector.unit * -40
				game.Debris:AddItem(bv, 0.3)
				game.ServerStorage.Requests.TagHumanoid:Fire(character, enemy, {damage = 10, physical = true, noenchant = true,})
			end
		end)
	elseif info.blacksmithfreeze and FindFirstChild(enemy, "CounterSpell") then
		enemy = character
		eroot = character.HumanoidRootPart
		create("Knocked", 1.5, enemy)
		for i,v in pairs(enemy:GetChildren()) do
			if v.Name == "WakingUp" then
				task.wait()
				v:Destroy()
			end
		end
		commands.StopBurn(enemy)
		local icecase = game.ServerStorage.SpellEffects.FireWhip.IceCase:Clone()
		icecase.CFrame = eroot.CFrame
		icecase.Weld.Part0 = eroot
		icecase.Weld.Part1 = icecase
		icecase.Parent = enemy
		game.Debris:AddItem(icecase,1.5)
		local bv = Instance.new("BodyVelocity")
		CollectionService:AddTag(bv,"AllowedBM")
		bv.MaxForce = Vector3.new(1000000,1000000,1000000)
		bv.Parent = eroot
		bv.Velocity = eroot.CFrame.lookVector.unit * -60
		game.Debris:AddItem(bv, 0.3)
		task.delay(1.5, function()
			create("Knocked", 2, enemy)
			local slowdown = Instance.new("NumberValue")
			slowdown.Value = -10
			slowdown.Name = "SpeedBoost"
			slowdown.Parent = enemy.Boosts
			game.Debris:AddItem(slowdown,12.5)
			local bv = Instance.new("BodyVelocity")
			CollectionService:AddTag(bv,"AllowedBM")
			bv.MaxForce = Vector3.new(1000000,1000000,1000000)
			bv.Parent = eroot
			bv.Velocity = eroot.CFrame.lookVector.unit * -40
			game.Debris:AddItem(bv, 0.3)
			game.ServerStorage.Requests.TagHumanoid:Fire(character, enemy, {damage = 10, physical = true, noenchant = true,})
		end)
	end
	if enemy:FindFirstChild("FlowingParry")and not(enemy == character)and not character:FindFirstChild("MonsterInfo") then
		local Action = FindFirstChild(enemy,"HeavyAttack")
		local Stun = FindFirstChild(enemy, "Action")
		if Action then
			task.wait()
			Action:Destroy()
		end
		if Stun then
			task.wait()
			Stun:Destroy()
		end
		info = {damage = 10, physical = true, manabreaker = true, slash = true, blade = true}
		enemy = character
		enemydata = playerdata
		EnemyPlayer = Player
		ehumanoid = humanoid
		eroot = root
	end
	if enemy:FindFirstChild("FULLPARRY") and not character:FindFirstChild("MonsterInfo") and info.physical and not info.fist and not info.subzero and not info.injury then
		local Action = FindFirstChild(enemy,"HeavyAttack")
		local Stun = FindFirstChild(enemy, "Action")
		local Assets = game.ServerStorage.Assets
		local COUNTER = ehumanoid:LoadAnimation(Assets.Sword.FULLPARRY.COUNTER)
		COUNTER:Play()
		local COUNTERED = humanoid:LoadAnimation(Assets.Sword.FULLPARRY.COUNTERED)
		COUNTERED:Play()
		if Action then
			task.wait()
			Action:Destroy()
		end
		if Stun then
			task.wait()
			Stun:Destroy()
		end
		enemy = character
		enemydata = playerdata
		EnemyPlayer = Player
		ehumanoid = humanoid
		eroot = root
	end
	if character.Boosts:FindFirstChild("MeleeDamageMultiplier")and info.damage and info.physical and not info.snarvin then
		info.damage *= character.Boosts.MeleeDamageMultiplier.Value
	end
	if enemy:FindFirstChild("Weakness") and info.damage and info.damage > 0 then
		info.damage *= 2
	end
	if character:FindFirstChild("Weakness") and info.damage and info.damage > 0 then
		info.damage /= 2
	end
	if enemy:FindFirstChild("Lordsbaned") and info.damage then
		info.damage /= 2
	end
	if character:FindFirstChild("Lordsbaned") and info.damage then
		info.damage *= 1.75
	end
	if enemy:FindFirstChild("HyperArmor") and info.damage then
		if enemydata.Race.Value == "Metascroom" then
			info.damage /= 2.5
		elseif enemy:FindFirstChild("HyperArmor") then
			info.damage /= 1.5
		end
	end
	if info.undead then
		if enemy:FindFirstChild("Knocked") and enemy:FindFirstChild("Unconscious") and not enemy:FindFirstChild("MonsterInfo") then
			info.executes = true
			local v11 = game.ServerStorage.Requests.SpawnMonster:Invoke("Shrieker", enemy.HumanoidRootPart.Position, character, true);
			local v12 = game.ServerStorage.Assets.Dark:Clone();
			v12.CFrame = v11.Torso.CFrame;
			v12.Parent = workspace.Thrown;
			if enemydata.DaysSurvived.Value < 3 then
				local v123 = Instance.new("Accessory")
				v123.Name = "Summoned"
				v123.Parent = v11
			end
			game:GetService("Debris"):AddItem(v12, 2);
			v12.Sound:Play();
			v12.Attachment.OrbParticle:Emit(100);
			TweenService:Create(v12, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false), {
				Size = Vector3.new(10.05, 10.05, 10.05)
			}):Play();
			_G.Death(EnemyPlayer, Player)
		end
	end
	if info.disarm and not FindFirstChild(enemy, "CurseBlocking") then
		if enemy:FindFirstChildOfClass("Tool") and ((enemy:FindFirstChildOfClass("Tool"):FindFirstChild("Skill") and enemy:FindFirstChildOfClass("Tool"):FindFirstChild("RequiresWeapon")) or enemy:FindFirstChildOfClass("Tool"):FindFirstChild("PrimaryWeapon"))  then
			create("Disarmed", 0.5, enemy)
			if info.knockondisarm then
				create("Knocked", info.knockondisarm, enemy)
				local bv = Instance.new("BodyVelocity")
				CollectionService:AddTag(bv, "AllowedBM")
				bv.MaxForce = Vector3.new(1000000000, 0, 1000000000)
				bv.Velocity = eroot.CFrame.lookVector.unit * -20
				bv.Parent = enemy
				game.Debris:AddItem(bv, 0.25)
			end
		end
	end
	if not enemy:FindFirstChild("MonsterInfo") and enemydata and enemydata.Injuries.Value:find("chestgash") and info.damage and info.physical then
		info.damage *= 1.18
	end
	if info.injury and info.injury == "rib cage" and not blocking then
		create("Knocked", 1, enemy)
		if not enemy:FindFirstChild("MonsterInfo") and not enemydata.Injuries.Value:find(info.injury) then
			enemydata.Injuries.Value ..= ",BrokenRib"
		end
	elseif blocking and info.injury and info.injury == "rib cage" then
		create("Knocked", 1, character)
		enemy = character
		ehumanoid = humanoid
		eroot = root
		EnemyPlayer = Player
		enemydata = playerdata
	end
	if info.azaelcheck then
		if info.burn and not enemy:FindFirstChild("MonsterInfo") and enemydata and enemydata.Race.Value == "Azael" then
			info.burn = false
			info.fakeburn = true
			if info.damage then
				info.damage += .75
			end
			if info.dsagem2 then
				info.cancelsmana = false
			end
		end
	end
	if info.injury and info.injury == "heat" and info.damage and not enemy:FindFirstChild("MonsterInfo") and not enemydata.Injuries.Value:find(info.injury) then
		enemydata.Injuries.Value = enemydata.Injuries.Value..",heat"
		if not enemy:FindFirstChild("SpellBlocking") then
			create("Knocked", 2, enemy)
			local bod = Instance.new("BodyVelocity")
			CollectionService:AddTag(bod, "AllowedBM")
			bod.MaxForce = Vector3.new(50000, 30, 50000)
			bod.Velocity = eroot.CFrame.lookVector.unit * -40
			bod.Velocity += Vector3.new(0, 25, 0)
			game.Debris:AddItem(bod, 0.5)
		end
	end
	if not enemy:FindFirstChild("MonsterInfo") and enemydata and enemydata.Injuries.Value:find("heat") and info.damage then
		info.damage = info.damage * 1.5
	end
	if FindFirstChild(enemy,"Awakening")then
		if not info.falldamage and not info.nododge and not info.blockbreak and not info.strongknockback and not (info.curse) and not (info.mana) or (info.mana and info.sunlight) or (info.mana and info.snarvin) then
			local awakening = enemy.Awakening
			if awakening.Value>0 then
				awakening.Value-=1
				if awakening.Value == 0 then
					awakening.Parent = nil
					task.spawn(function()
						wait(1)
						if awakening and awakening.Parent then
							awakening:Destroy()
						end
					end)
				end
				create("NoDam",0.3,enemy)
				local dodgeanim = ehumanoid:LoadAnimation(script["Dodge"..math.random(1,2)])
				dodgeanim:Play()
				return
			end
		end
	end

	if info.blade and info.damage then
		if EnemyPlayer and EnemyPlayer.Backpack:FindFirstChild("SlashResistance")then
			if info.damage then
				info.damage = info.damage/100 * 75
			end
		end
	end
	if info.damage then
		if enemy:FindFirstChild("IronRes") then
			info.damage /= 3
			soundplay(eroot, "MetalClash")
			eroot.Sparks:Emit(10)
		end
	end
	if info.mana then
		if FindFirstChild(enemy,"SpellBlocking")and not info.manabreaker and not info.curse then
			eroot.SpellBlock:Play()
			if enemy == character then
				local ac = FindFirstChild(character, "Action")
				local ha = FindFirstChild(character, "HeavyAttack")
				if ha then
					ha:Destroy()
				end
				if ac then
					ac:Destroy()
				end
			end
			create("ChargeBlock", 0.85, enemy)
			if character.Head.Transparency ~= 1 then
				eroot.Orb.Transparency = 0
				TweenService:Create(eroot.Orb,TweenInfo.new(0.5),{Transparency = 0.75}):Play()
			end
			return
		end
		if FindFirstChild(enemy, "MonShield") and not info.monkbreaker and not info.sunlight then
			return
		end
		if (info.curse or info.tsc) and FindFirstChild(enemy, "MonShield") and not info.blockbreak then return end
		if info.curse and FindFirstChild(enemy,"CurseBlocking")then
			return
		end
		if info.burn and not enemy:FindFirstChild("MonsterInfo") and enemydata and enemydata.Race.Value == "Azael" then
			return
		end
		if info.rubyshard and enemy:FindFirstChild("RubyShardCD") then
			return
		else
			create("RubyShardCD", 0.8, enemy)
		end
		if info.disease then
			create(info.disease, 180, enemy)
		end
		if info.sunlight or info.floresco then
			create("NoDam", 0.2, enemy)
		end
		if info.torture2 and not enemy:FindFirstChild("MonsterInfo") then
			local injuries = {"brokenleg", "brokenarm", "heat", "chestgash", "Frostbite", "blind", "dizzy"}
			local choseninjury = nil
			for i = 1,#injuries do
				if not enemydata.Injuries.Value:find(injuries[i]) then
					choseninjury = injuries[i]
				end
			end
			if choseninjury then
				enemydata.Injuries.Value ..= ","..choseninjury
				if not enemy:FindFirstChild("InjuryCooldown") then
					eroot.Injury:Play()
					local injury = game.ReplicatedStorage.Assets.Injure:Clone()
					injury.Parent = eroot
					injury:Emit(3)
					game.Debris:AddItem(injury,1.5)
					local f = Instance.new("Accessory") f.Name = "InjuryCooldown" f.Parent = enemy game.Debris:AddItem(f,1)
				end
			end
			return
		end
		if info.torture and not enemy:FindFirstChild("MonsterInfo") then
			local injuries = {"brokenleg", "brokenarm", "heat", "chestgash", "Frostbite", "blind", "dizzy"}
			local choseninjury = nil
			for i = 1,#injuries do
				if not enemydata.Injuries.Value:find(injuries[i]) then
					choseninjury = injuries[i]
				end
			end
			if choseninjury then
				enemydata.Injuries.Value ..= ","..choseninjury
				info.injury = true
			end
			local bv = Instance.new("BodyVelocity")
			game.CollectionService:AddTag(bv, "AllowedBM")
			bv.P = 1250
			bv.MaxForce = Vector3.new(1e+06, 1e+06, 1e+06)
			bv.Velocity = eroot.CFrame.LookVector.Unit * (math.random(1,2) == 1 and -60 or 60) + Vector3.new(10, 0, 10)
			bv.Parent = enemy.HumanoidRootPart
			game.Debris:AddItem(bv, 0.5)
		end
		if info.curse and FindFirstChild(enemy.Artifacts,"Lannis")and not info.bypasslannis then
			if  enemy ~= character and enemydata.Race.Value ~= "Cameo" then -- lannis proc on own moves
				if not FindFirstChild(enemy,"LannisCD")then
					u4.Lannis(enemy)
					create("LannisCD", 1, character)
					return
				end
			end
		end
		if info.curseblast then
			if enemy:FindFirstChild("tenebriscd") then return end
			create("tenebriscd", 5, enemy)
			require(game.ServerScriptService.Modules.EffectModule)["Lanniseffect3"](enemy)
		end
		if info.curseeffect then
			local curseCount = getCurseCount(enemy)
			if curseCount < 4 and not enemy.Boosts:FindFirstChild("CurseEffectImmune") then
				local Cursey = game.ServerStorage.Assets.Cursey:Clone()
				Cursey.Parent = enemy.HumanoidRootPart
				game.Debris:AddItem(Cursey, 30);
				curseCount += 1
			end
		end
		if info.closemana then
			create("ContrariumTag", 0.9, enemy)
			if enemy:FindFirstChild("Charge") then
				enemy.Charge:Destroy()
			end
		end
		if info.gelidusfreeze and not FindFirstChild(enemy.Artifacts, "Lannis") then
			knockback = true
			bodyvelocitycheck(enemy)
			create("Knocked", 2, enemy)
			create("GelidusCD", 5, enemy)
			local bv = Instance.new("BodyVelocity")
			CollectionService:AddTag(bv,"AllowedBM")
			bv.MaxForce = Vector3.new(1e+06, 1e+06, 1e+06)
			bv.P = 1250
			bv.Velocity = eroot.CFrame.lookVector.unit*-40
			bv.Velocity += Vector3.new(0, 10, 0)
			bv.Parent = eroot
			game.Debris:AddItem(bv,0.3)
		elseif info.gelidusfreeze and FindFirstChild(enemy.Artifacts, "Lannis") and FindFirstChild(enemy, "LannisCD") then
			knockback = true
			bodyvelocitycheck(enemy)
			create("Knocked", 2, enemy)
			create("GelidusCD", 5, enemy)
			local bv = Instance.new("BodyVelocity")
			CollectionService:AddTag(bv,"AllowedBM")
			bv.MaxForce = Vector3.new(1000000,10000000,1000000)
			bv.Velocity = eroot.CFrame.lookVector.unit*-40
			bv.Velocity = bv.Velocity + Vector3.new(0, 10, 0)
			bv.Parent = eroot
			game.Debris:AddItem(bv,0.3)
		end
		if info.curse and not(enemy == character)and FindFirstChild(enemy,"CounterSpell")then
			local oldplayer = EnemyPlayer
			local olddata = enemydata
			local oldenemy = enemy
			local oldroot = eroot
			local oldhumanoid = ehumanoid
			EnemyPlayer = Player
			enemydata = playerdata
			enemy = character
			eroot = root
			ehumanoid = humanoid
			Player = EnemyPlayer
			playerdata = olddata
			character = oldenemy
			root = oldroot
			humanoid = oldhumanoid
			info.bypasslannis = true
		end
		if info.fimbul then
			task.spawn(function()
				local v28 = game.ServerStorage.SpellEffects.GreatWinter.IceCase:Clone()
				v28.CFrame = enemy.HumanoidRootPart.CFrame
				v28.Parent = enemy
				local v29 = Instance.new("Motor6D")
				v29.Part0 = enemy.Torso
				v29.Part1 = v28
				v29.Parent = v28
				game.Debris:AddItem(v28, 2)
				wait(2)
				game.ServerStorage.Requests.TagHumanoid:Fire(character, enemy, {
					mana = true, 
					damage = 12, 
					manaknockupself = true, 
					curse = true, 
					downbypass = true,
				})
			end)
		end
		if info.manaknockup then
			if not plantedcheck(enemy)then
				knockback = true
				bodyvelocitycheck(enemy)
				create("Knocked", 2, enemy)
				local bv = Instance.new("BodyVelocity")
				CollectionService:AddTag(bv,"AllowedBM")
				bv.MaxForce = Vector3.new(1e+06, 0, 1e+06)
				bv.P = 1250
				bv.Velocity = root.CFrame.lookVector.unit*(knockm+5)
				bv.Parent = eroot
				game.Debris:AddItem(bv,0.5)
			end
		end
		if info.manaknockupself then
			if not plantedcheck(enemy) and not enemy:FindFirstChild("SpellBlocking") then
				knockback = true
				bodyvelocitycheck(enemy)
				if not info.tsc then
					create("Knocked", 2, enemy)
					local bv = Instance.new("BodyVelocity")
					CollectionService:AddTag(bv,"AllowedBM")
					bv.MaxForce = Vector3.new(1000000,1000000,1000000)
					bv.Velocity = eroot.CFrame.lookVector.unit*-40
					bv.Velocity = bv.Velocity+Vector3.new(0,20,0)
					bv.Parent = eroot
					game.Debris:AddItem(bv,0.3)
				else
					create("Knocked", 2.5, enemy)
					local bv = Instance.new("BodyVelocity")
					CollectionService:AddTag(bv,"AllowedBM")
					bv.MaxForce = Vector3.new(1000000,1000000,1000000)
					bv.Velocity = eroot.CFrame.lookVector.unit*-40
					bv.Velocity = bv.Velocity+Vector3.new(0,20,0)
					bv.Parent = eroot
					game.Debris:AddItem(bv,0.3)
				end
			end
		end
	else
		if FindFirstChild(enemy,"Awakening")then
			if not info.falldamage and not info.nododge and not info.blockbreak and not info.strongknockback and not info.curse then
				local awakening = enemy.Awakening
				if awakening.Value>0 then
					awakening.Value-=1
					if awakening.Value == 0 then
						awakening.Parent = nil
						task.spawn(function()
							wait(1)
							if awakening and awakening.Parent then
								awakening:Destroy()
							end
						end)
					end
					create("NoDam",0.3,enemy)
					local dodgeanim = ehumanoid:LoadAnimation(script["Dodge"..math.random(1,2)])
					dodgeanim:Play()
					return
				end
			end
		end
	end
	if info.cursestack then
		local curseCount = getCurseCount(enemy)
		if curseCount < 4 and not blocking then
			if enemy.Boosts and not enemy.Boosts:FindFirstChild("CurseEffectImmune") then
				local Cursey = game.ServerStorage.Assets.Cursey:Clone()
				Cursey.Parent = enemy.HumanoidRootPart
				game.Debris:AddItem(Cursey, 30);
				curseCount += 1
			end
		end
	end
	if info.freeze and not info.subzero then
		commands.StopBurn(enemy)
		local icecase = game.ServerStorage.SpellEffects.FireWhip.IceCase:Clone()
		icecase.CFrame = eroot.CFrame
		icecase.Weld.Part0 = eroot
		icecase.Weld.Part1 = icecase
		icecase.Parent = enemy
		game.Debris:AddItem(icecase,1.5)
		Player = game.Players:GetPlayerFromCharacter(enemy)
		TemperatureHandler.CHANGE_TEMPERATURE(enemy,-1, 0.1)
		create("BurnCooldown",2,enemy)
		create("AntiBurn", 6, enemy)
	end
	if info.burn then
		local burncolor
		if info.burncolor then
			burncolor = info.burncolor
		end
		local manainfo = {}
		if info.antimanaburn then
			manainfo.manastop = true
		end
		manainfo.wraithfire = info.wraithfire
		commands.StartBurn(enemy,eroot,burncolor,manainfo,character)
	end
	if info.fakeburn then
		local partic = game.ServerStorage.Assets.FakeBurn:clone()
		partic.Parent = enemy.PrimaryPart
		partic:Emit(30)
		game.Debris:AddItem(partic,1.5)
		if enemy:FindFirstChild("HumanoidRootPart") then
			if enemy:FindFirstChild("FakeExtinguish") then
				enemy.FakeExtinguish:Play()
			end
		end
	end
	if info.sunlight then
		if game.CollectionService:HasTag(enemy,"Vampirism") then
			if not FindFirstChild(enemy,"NoHunger") and enemy.Name ~= "PixelAissar" then
				enemy.Stomach.Value = math.clamp(enemy.Stomach.Value-info.sunlight, 0, humanoid.MaxHealth)
			end
			if info.mana then
				commands.StartBurn(enemy,eroot,nil,nil,character)
				create("NoRegen", 7, enemy)
				create("AntiVampirism", 7, enemy)

			end
		end
	end
	if FindFirstChild(enemy,"SilverGuard") and enemydata.Silver.Value > 0 then
		if not info.nododge and not info.falldamage and info.damage then
			if enemydata and enemydata.Silver.Value>0 then
				eroot.SilverEmit:Emit(25)
				eroot.SilverClash:Play()
				task.spawn(function()
					if enemydata.Silver.Value > info.damage/5 then
						enemydata.Silver.Value -= info.damage/5
					else
						enemydata.Silver.Value = 0
					end
				end)
				info.damage = info.damage/100 * 80
			end
		end
	end

	if FindFirstChild(enemy,"PlayingSong") then
		if info.damage and info.damage > 0 and not info.nododge then
			if enemydata and enemydata.Class.Value == "Candence" then
				info.damage = info.damage/100 * 55
			end
		end
	end

	if info.nrag ~= nil then
		anyreturn = create("Knocked", info.nrag, enemy)
	end

	if enemy:FindFirstChild("HaseldanDamageMultiplier")and info.damage then
		info.damage /= 1.5
	end

	if info.physical and not info.nohitanim then
		if blocking and not behind and not info.bypassblock or enemy:FindFirstChild("MonShield") and not info.bypassblock or blocking and info.blockallsides and not info.bypassblock then
			if info.blockbreak then
				if enemy:FindFirstChild("Parry")and not info.noparry then
					local v1 = Instance.new("Accessory")
					v1.Name = "COUNTERED"
					v1.Parent = character
					game.Debris:AddItem(v1,0.5)
					local v4 = Instance.new("Accessory")
					v4.Name = "Action"
					v4.Parent = character
					game.Debris:AddItem(v4,1.15)
					root.Counter:Play()
					root.counterparticle:Emit(50)
					game.ReplicatedStorage.Requests.ScreenFlip:FireClient(Player)
					wait(0.125)
					for _,v in pairs(humanoid:GetPlayingAnimationTracks())do
						v:AdjustSpeed(0)
					end
					wait(0.7)
					for _,v in pairs(humanoid:GetPlayingAnimationTracks())do
						v:AdjustSpeed(1.5)
					end
					return
				else -- block break
					if not info.manaexception and not enemy:FindFirstChild("CurseBlocking") then
						local v1 = Instance.new("Accessory")
						v1.Name = "Action"
						v1.Parent = enemy
						game.Debris:AddItem(v1,1.25)
						local v2 = Instance.new("Accessory")
						v2.Name = "BREAK"
						v2.Parent = enemy
						game.Debris:AddItem(v2,0.75)
						local v23 = Instance.new("Accessory")
						v23.Name = "NoDam"
						v23.Parent = enemy
						game.Debris:AddItem(v23,0.75)
						knockback = true
						blocking:Destroy()
						for _,v in pairs(ehumanoid:GetPlayingAnimationTracks())do
							v:Stop()
						end
						soundplay(eroot,"Break")
					end
				end
			else -- blocked
				local returning = false
				info.poison = false
				blocked = true
				if enemy:FindFirstChild("MonShield") then
					if not info.bypassblock then
						returning = true
						if not plantedcheck(enemy) and not info.iselbow and not info.bypassblock then
							knockback = true
							bodyvelocitycheck(character)
							create("Knocked", 2, character)
							local bv = Instance.new("BodyVelocity")
							CollectionService:AddTag(bv,"AllowedBM")
							bv.MaxForce = Vector3.new(1000000,1000000,1000000)
							bv.Velocity = root.CFrame.lookVector.unit*-35+Vector3.new(0,10,0)
							bv.Parent = root
							eroot.SLAMJAM:Play()
							game.Debris:AddItem(bv,0.5)
							create("ChargeBlock",0.85,enemy)
						end
					else
						create("NoDam", 0.6, enemy)
					end
				else
					if not info.slash then
						soundplay(eroot,"BlockSound")
						eroot.BlockParticle:Emit(1)
						returning = true

						local ac = FindFirstChild(character,"Action")
						local la = FindFirstChild(character,"ChargeBlock")
						if la and not la:FindFirstChild("NoDelete") then
							la:Destroy()
						end
						local ha = FindFirstChild(character,"HeavyAttack")
						if ha and not ha:FindFirstChild("NoDelete") then
							ha:Destroy()
						end
						if ac then
							local ha = FindFirstChild(character,"HeavyAttack")
							if ha then
								ac:Destroy()
								ha:Destroy()
							else
								if not FindFirstChild(ac,"NoDelete")then
									ac:Destroy()
								end
							end
						end

					else -- slash
						local w = FindFirstChild(enemy,"HasWeapon")or FindFirstChild(enemy,"IronBody")or false
						if not w then
							create("ChargeBlock", 0.85, enemy)
							info.damage = info.damage / 10
							soundplay(eroot,"FleshBlock")
							FindFirstChild(eroot,"BloodHit"):Emit(10)

							local ac = FindFirstChild(character,"Action")
							local la = FindFirstChild(character,"ChargeBlock")
							if la and not la:FindFirstChild("NoDelete") then
								la:Destroy()
							end
							local ha = FindFirstChild(character,"HeavyAttack")
							if ha then
								ha:Destroy()
							end
							if ac then
								local ha = FindFirstChild(character,"HeavyAttack")
								if ha then
									ac:Destroy()
									ha:Destroy()
								else
									if not FindFirstChild(ac,"NoDelete")then
										ac:Destroy()
									end
								end
							end

						else
							create("ChargeBlock", 0.85, enemy)
							soundplay(eroot,"MetalClash")
							local ss_assets = game.ServerStorage.Assets
							local ac = FindFirstChild(character,"Action")
							local la = FindFirstChild(character,"ChargeBlock")
							local bm = FindFirstChild(EnemyPlayer.Backpack,"LordsTraining")
							if not info.mana then
								if bm and enemydata.Weapon.Value == "Sword" and enemy:FindFirstChildOfClass("Tool") and (enemy:FindFirstChildOfClass("Tool"):FindFirstChild("PrimaryWeapon") or (enemy:FindFirstChildOfClass("Tool"):FindFirstChild("Skill") and enemy:FindFirstChildOfClass("Tool"):FindFirstChild("RequiresWeapon"))) then
									local counter = ehumanoid:LoadAnimation(ss_assets.Sword.FULLPARRY.COUNTER)
									counter:Play()
									local countered = humanoid:LoadAnimation(ss_assets.Sword.FULLPARRY.COUNTERED)
									countered:Play()
									local action = Instance.new('Accessory')
									action.Name = "Action"
									action.Parent = character
									game:GetService("Debris"):AddItem(action,0.3)
								end
							end
							if la and not la:FindFirstChild("NoDelete") then
								la:Destroy()
							end
							local ha = FindFirstChild(character,"HeavyAttack")
							if ha then
								ha:Destroy()
							end
							if ac then
								local ha = FindFirstChild(character,"HeavyAttack")
								if ha then
									ac:Destroy()
									ha:Destroy()
								else
									if not FindFirstChild(ac,"NoDelete")then
										ac:Destroy()
									end
								end
							end

							if FindFirstChild(enemy,"HasDagger")then
								ehumanoid:LoadAnimation(combatanims["DaggerBlockReact"..math.random(1,2)]):Play()
							end
							return
						end
					end end
				ehumanoid:LoadAnimation(combatanims["BlockReact"..math.random(1,3)]):Play()
				if returning then
					if info.blockallsides then
						bodyvelocitycheck(enemy)
					end
					return
				end
			end
		end
	end
	if not enemy:FindFirstChild("MonsterInfo") and enemydata and enemydata.Injuries.Value:find("Frostbite") and info.damage and info.physical then
		info.damage *= 1.33
	end
	if info.injury and info.injury == "dizzy" and not blocked then
		if not enemy:FindFirstChild("MonsterInfo") and not enemydata.Injuries.Value:find(info.injury) then
			enemydata.Injuries.Value ..= ",dizzy"
		end
	end
	if not blocked and not info.nododge and not info.falldamage then

		local ac = FindFirstChild(character,"Action")
		local la = FindFirstChild(character,"ChargeBlock")
		if la and not la:FindFirstChild("NoDelete") then
			la:Destroy()
		end
		local ha = FindFirstChild(character,"HeavyAttack")
		if ha then
			ha:Destroy()
		end
		if ac then
			local ha = FindFirstChild(character,"HeavyAttack")
			if ha then
				ac:Destroy()
				ha:Destroy()
			else
				if not FindFirstChild(ac,"NoDelete")then
					ac:Destroy()
				end
			end
		end

	end

	if not info.nododge and not knockback then
		if blocking and(behind or info.ignoreblock)then
			if info.blockbreak then
				if FindFirstChild(enemy,"Parry")and not info.noparry then
					local v1 = Instance.new("Accessory")
					v1.Name = "COUNTERED"
					v1.Parent = character
					game.Debris:AddItem(v1,0.5)
					local v4 = Instance.new("Accessory")
					v4.Name = "Action"
					v4.Parent = character
					game.Debris:AddItem(v4,1.15)
					root.Counter:Play()
					root.counterparticle:Emit(50)
					game.ReplicatedStorage.Requests.ScreenFlip:FireClient(Player)
					return
				end
			end
			blocking:Destroy()
		end
		if not blocked then
			if FindFirstChild(enemy, "WindDodges") then
				create("DodgeCancel", false, enemy)
			end
			local stun = 0.35
			if info.nostun then
				stun = 0
			end
			local dodged = false
			if FindFirstChild(enemy,"WindDodges")and not info.nododge and not enemy:FindFirstChild("CurseBlocking") and not info.bypassfischdodge then
				if enemy.WindDodges.Value>0 then
					enemy.WindDodges.Value-=1
					eroot.ColdWind:Play()
					if not info.mana then
						info.damage = 0
					end
					dodged = true
					task.spawn(function()
						if enemy.WindDodges.Value > 0 then
							local start = tick()
							if FindFirstChild(enemy, "DodgeCancel") then
								wait(.1)
								for i,v in pairs(enemy:GetChildren()) do
									if v.Name == "DodgeCancel" then
										v:Destroy()
									end
								end
							end
							while true do
								if tick() - start >= 15 then
									if enemy and enemy:FindFirstChild("WindDodges") then
										enemy.WindDodges.Value = 4
									end
									break
								end
								if not enemy then
									break
								end
								if enemy:FindFirstChild("DodgeCancel") then
									break
								end
								task.wait()
							end

						else
							task.wait(30)
							if enemy and enemy:FindFirstChild("WindDodges") then
								enemy.WindDodges.Value = 4
							end
						end
					end)
					task.spawn(function()
						local old = enemy.Torso.Transparency
						for i = 0,0.5,0.1 do
							if enemy.Torso.Transparency ~= old then
								break
							end
							changetransparency(enemy,i)
							old = enemy.Torso.Transparency
							wait(0.0455)
						end
						wait()
						for i = 0.3,0,-0.1 do
							if enemy.Torso.Transparency ~= old then
								break
							end
							changetransparency(enemy,i)
							old = enemy.Torso.Transparency
							wait(0.0455)
						end
						changetransparency(enemy,0)
					end)
				end
			end
			if not info.nododge then
				if info.slash then
					if FindFirstChild(enemy,"SpellBlocking") then
						if not info.manabreaker and not info.daggerthrow then
							eroot.SpellBlock:Play()
							create("ChargeBlock", 0.85, enemy)
							if character.Head.Transparency ~= 1 then
								eroot.Orb.Transparency = 0

								TweenService:Create(eroot.Orb,TweenInfo.new(0.5),{Transparency = 0.75}):Play()
							end
							if EnemyPlayer and (table.find(_G.MageClasses, enemydata.Class.Value) or enemydata.Skills.Value:find("MageShield")) then
								if not plantedcheck(enemy)then
									knockback = true
									bodyvelocitycheck(character)
									create("Knocked", 2, character)
									local bv = Instance.new("BodyVelocity")
									CollectionService:AddTag(bv,"AllowedBM")
									bv.MaxForce = Vector3.new(1000000,1000000,1000000)
									bv.Velocity = root.CFrame.lookVector.unit*-50+Vector3.new(0,50,0)
									bv.Parent = root
									eroot.SpellBlock:Play()
									game.Debris:AddItem(bv,0.7)
								end
							end
							return
						elseif info.manabreaker then
							cancellingthat = true
							local manashieldtween
							knockback = false
							if blocking then
								blocking:Destroy()
							end
							if FindFirstChild(enemy,"CurseBlocking")then
								local m = FindFirstChild(enemy,"SpellBlocking")
								local c = FindFirstChild(enemy,"CurseBlocking")
								eroot.ShieldDown:Play()
								if m then
									m:Destroy()
								end
								if c then
									c:Destroy()
								end
								if manashieldtween then
									manashieldtween:Pause()
									manashieldtween = nil
								end
								local orb = eroot.Orb
								manashieldtween = TweenService:Create(orb.Mesh,TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{Scale = Vector3.new(0,0,0)})
								manashieldtween:Play()
								orb.Attachment.ParticleEmitter.Enabled = false
							end
							for _,v in pairs(ehumanoid:GetPlayingAnimationTracks())do
								v:Stop()
							end
						end
					end
				end
				if info.knockup and info.shoryu then
					if not plantedcheck(enemy)then
						knockback = true
						bodyvelocitycheck(enemy)
						create("Knocked", 2, enemy)
						local v2 = Instance.new("ObjectValue")
						v2.Name = "LandedShoryuExcept"
						v2.Value = enemy
						v2.Parent = character
						game.Debris:AddItem(v2,1)
						local bv = Instance.new("BodyVelocity")
						CollectionService:AddTag(bv,"AllowedBM")
						bv.MaxForce = Vector3.new(1000000,1000000,1000000)
						bv.Velocity = Vector3.new(0,80,0)
						bv.Parent = eroot
						game.Debris:AddItem(bv,0.3)
						local FreezeRoot = FindFirstChild(enemy,"FreezeRoot")if FreezeRoot then
							FreezeRoot:Destroy()
						end
					end
				end
				if info.misogi then
					create("Knocked", 2, enemy)
				end
				if info.strongknockback then
					if not plantedcheck(enemy) and not (info.iselbow and enemy:FindFirstChild("SpellBlocking")) then
						knockback = true
						bodyvelocitycheck(enemy)
						create("Knocked", 2.2, enemy)
						local bv = Instance.new("BodyVelocity")
						CollectionService:AddTag(bv,"AllowedBM")
						bv.MaxForce = Vector3.new(1000000,0,1000000)
						bv.Velocity = root.CFrame.lookVector.unit* (knockm + 16)
						bv.Parent = eroot
						game.Debris:AddItem(bv,0.7)
					end
				end
				if not dodged then
					if info.fist then
						local iswind = FindFirstChild(enemy, "WindDodges")
						local iswindamount = 0
						if iswind  then
							iswindamount = enemy.WindDodges.Value
						end
						if info.electric then
							stun = 0.9
						end
						if info.smitestun then
							stun = 1.5
						end
						if not info.droar then
							if Player and Player:FindFirstChild("Backpack") then
								if Player.Backpack:FindFirstChild("ChiBlock") and not (info.iselbow or info.snarvin) and character.Mana.Value >= 5 then
									if iswindamount < 1 then
										soundplay(eroot,"ManaPunch")
										FindFirstChild(eroot,"ManaStopParticle"):Emit(20)
										create("ManaStop",5,enemy)
									end
								elseif Player.Backpack:FindFirstChild("ChiBlock") and (info.iselbow or info.snarvin) and not blocking then
									if iswindamount < 1 then
										soundplay(eroot,"ManaPunch")
										FindFirstChild(eroot,"ManaStopParticle"):Emit(20)
										create("ManaStop",5,enemy)
									end
								end
							end
						end
						if (info.manastop or info.snarvin or info.iselbow or info.dsagem2) and not info.blockbreak and not info.blacksmithm1 then
							soundplay(eroot,"ManaPunch")
							FindFirstChild(eroot,"ManaStopParticle"):Emit(20)
							create("ManaStop",0.25,enemy)
						else 
							soundplay(eroot,"Hit")
							FindFirstChild(eroot,"Hit1"):Emit(3)
						end
						if not dodged and not knockback and not info.knockback and not info.blockbreak then
							hitknockback(root,eroot)
						end
					elseif info.rapier then
						stun = 0.25
						soundplay(eroot,"SwordHit")
						FindFirstChild(eroot,"BloodHit"):Emit(20)
					elseif info.norpsword then
						stun = 0.35
						soundplay(eroot,"norpGreatswordHit")
						FindFirstChild(eroot,"BloodHit"):Emit(20)
					elseif info.givestun then
						stun = 0.25
					elseif info.dagger then
						if not info.daggerthrow and not info.nobackstab then
							if info.isdaggerm1 and playerdata.PrimaryWeapon.Value == "Tanto" then
								info.damage *= 2
							end
							if behind then
								if not info.daggerthrow and not info.nobackstab then
									if info.damage then
										info.damage *= 1.7
									end
								end
							end
						end
						stun = 0.25
						soundplay(eroot,"DaggerHit")
						FindFirstChild(eroot,"BloodHit"):Emit(20)
					elseif info.sword then
						stun = 0.35
						soundplay(eroot,"SwordHit")
						if info.sigilice then
							local slowdown = Instance.new("NumberValue")
							slowdown.Value = -2
							slowdown.Name = "SpeedBoost"
							slowdown.Parent = enemy.Boosts
							game.Debris:AddItem(slowdown,2)
							eroot.IceHit:Play()
							eroot.SigilIceHit:Emit(6)
							commands.StopBurn(enemy)
						elseif info.sigilthunder then
							stun = 0.5
							if info.chargedblow then
								stun = 0.8
								task.spawn(function()
									u4.Lightning(eroot.CFrame*CFrame.new(0,20,0).Position,eroot.Position,1,2,"White")
								end)
								if FindFirstChild(character, "Action") then
									character.Action:Destroy()
								end
								if FindFirstChild(character, "HeavyAttack") then
									character.HeavyAttack:Destroy()
								end

							end
							if info.currentprop then
								info.currentprop.LightningHit:Play()
							end
							eroot.Lightning:Emit(5)
						elseif info.sigilflame then
							commands.StartBurn(enemy,eroot,nil,nil,character)
							if info.currentprop then
								info.currentprop.FireHit:Play()
							end
							eroot.SigilFireHit:Emit(5)
						elseif info.sigilwhitefire then
							commands.StartBurn(enemy,eroot,Color3.fromRGB(255,255,255),nil,character)
							if info.currentprop then
								info.currentprop.FireHit:Play()
							end
							eroot.SigilWhiteFireHit:Emit(5)
						end
						if FindFirstChild(character,"SigilBuff")and character.SigilBuff.Value =="BlackFlame"then
							local burncolor = Color3.new(0,0,0)
							local manainfo = {}
							manainfo.manastop = true
							manainfo.wraithfire = true
							commands.StartBurn(enemy,eroot,burncolor,manainfo,character)
						end
						eroot:FindFirstChild("BloodHit"):Emit(20)
					elseif info.spear then
						stun = 0.35
						soundplay(eroot,"SpearHit")
						FindFirstChild(eroot,"BloodHit"):Emit(20)
						if info.spearmovestack and enemy:FindFirstChild("LastHit") then
							if tick()-enemy.LastHit.Value<0.25  then
								cancelknockback = true
							end
						end
						if info.churchpull then
							bodyvelocitycheck(enemy)
							local bp = Instance.new("BodyPosition")
							bp.Name = "PULLING"
							CollectionService:AddTag(bp, "AllowedBM")
							bp.Position = (root.Position+root.CFrame.LookVector*3)
							bp.MaxForce = Vector3.new(1e+06, 1e+06, 1e+06)
							bp.P = 10000
							bp.D = 500
							bp.Parent = eroot
							game.Debris:AddItem(bp,2)
						end
						if info.subzero and not enemy:FindFirstChild("MonsterInfo") then
							info.injury = "frostbite"
							if not enemydata.Injuries.Value:find(info.injury) then
								enemydata.Injuries.Value = enemydata.Injuries.Value..",Frostbite"
							end
							commands.StopBurn(enemy)
							eroot.IceHit:Play()
						end
					elseif info.katana then
						stun = 0.35
						soundplay(eroot,"SwordHit")
						FindFirstChild(eroot,"BloodHit"):Emit(20)
					end
				end
				if not blocked and not info.nododge and not FindFirstChild(enemy,"Planted") and not info.nohitanim and not info.nostun then
					for _,v in pairs(ehumanoid:GetPlayingAnimationTracks())do
						if not v.Looped and not info.noanimationcancel then
							v:Stop()
						end
					end
					local minfo = enemy:FindFirstChild("MonsterInfo")
					if minfo then
						if minfo:FindFirstChild("MonsterType") and enemy.MonsterInfo.MonsterType.Value ~= "Zombie Scroom" and enemy.MonsterInfo.MonsterType.Value ~= "Howler" and enemy.MonsterInfo.MonsterType.Value ~= "Howwgy" and enemy.MonsterInfo.MonsterType.Value ~= "Terra Serpent" then
							ehumanoid:LoadAnimation(combatanims["Hit"..math.random(1,4)]):Play()
						end
					else
						if not info.torture2 and not info.nohitanim then
							ehumanoid:LoadAnimation(combatanims["Hit"..math.random(1,4)]):Play()
						end
					end
				end
			end
			if info.droar then
				stun = 0.05
			end
			if info.knockback and not cancellingthat then
				if not plantedcheck(enemy) then

					if not info.specialrag then
						create("Knocked", 1, enemy)
					else
						create("Knocked", info.specialrag, enemy)
					end
					if not cancelknockback then
						knockback = true
						local bv = Instance.new("BodyVelocity")
						CollectionService:AddTag(bv,"AllowedBM")
						bodyvelocitycheck(enemy)
						bv.MaxForce = Vector3.new(1000000,0,1000000)
						bv.Velocity = root.CFrame.lookVector.unit * knockm
						bv.Parent = eroot
						game.Debris:AddItem(bv,0.7)
					end
				end
			end
			if character:FindFirstChild("ShinobiRuby") then
				if not (info.noenchant) then
					commands.StartBurn(enemy,eroot,nil,nil,character)
				end
			end
			if not (info.noenchant) then
				if (playerdata) then
					local val = playerdata.PrimaryWeapon.Value or "None"
					local val2 = playerdata.Enchant.Value or ""
					local no = false
					if (playerdata.PrimaryWeapon.Value~="Caestus"and info.fist) and not info.blacksmithm1 then
						no = true
					end
					if info.daggerthrow then
						no = true
					end
					if not (no) and not info.noenchant then
						if val2 ~= "" then
							if not info.noenchant then
								if val2:find("Ruby") then
									if info.damage and math.random(1,10)<=1+(info.damage*0.2) then
										commands.StartBurn(enemy,eroot,nil,nil,character)
									end
								end
								if val2:find("Emerald") then
									if info.damage and math.random(1,10)<=1+(info.damage*0.2) then
										game.ServerStorage.Requests.TagHumanoid:Fire(enemy,enemy,{poison = true,nododge = true})
									end
								end
								if val2:find("Opal") and not info.noenchant then
									eroot.HolyClash:Play()
									eroot.HolyEmit:Emit(9)
									if info.damage and game.CollectionService:HasTag(enemy,"Vampirism")then
										info.damage*=1.1
										create("NoRegen", 7, enemy)
										create("AntiVampirism", 7, enemy)
									end

								end
								if val2:find("Sapphire") then
									if info.damage and math.random(1,50)<=1+(info.damage*0.2) then
										local da = 0
										for i,v in pairs(enemy.Boosts:GetChildren()) do
											if v.Name == "SpeedBoost" and v.Value < 0 then
												da += 1
											end
										end
										if da < 4 then
											local slowdown = Instance.new("NumberValue")
											slowdown.Value = -3
											slowdown.Name = "SpeedBoost"
											slowdown.Parent = enemy.Boosts
											game.Debris:AddItem(slowdown,30)
										end
										eroot.IceHit:Play()
										eroot.SigilIceHit:Emit(6)
									end
								end
								if val2:find("Diamond") then
									if info.damage and math.random(1,10)<=1+(info.damage*0.2) then
										stun = stun * 1.75
										eroot.LightningBurst:Play()
										eroot.LightningEnchant:Emit(5)
									end
								end
								if val2:find("Nightstone") then
									if EnemyPlayer then
										game.ReplicatedStorage.Requests.NightStoneHit:FireClient(EnemyPlayer)
									end
								end
							end
						end
					end
				end
			end
			if dodged then
				stun /= 2
			end
			if not info.falldamage and not enemy:FindFirstChild("NoStun") then
				if not info.nohitanim then
					if not info.nostun and not enemy:FindFirstChild("NoStun") and not info.torture2 then
						create("ClimbCooldown", 1.25, enemy)
						create("Stun", stun + 0.05, enemy)
						create("NoDash", 0.85, enemy)
						create("NoJump", 0.85, enemy)
						create("ChargeBlock", 0.85, enemy)
					end
					if info.bypassblock and not enemy:FindFirstChild("MonShield") then
						create("noblockcancel", 0.2, enemy)
					end
					if not info.nohitanim and not info.nostun then
						create("NoDash", 0.85, enemy)
						if not info.snarvin then
							create("NoDam", 0.6, enemy)
						elseif info.snarvin and enemy:FindFirstChild("SpellBlocking") then
							create("NoDam", 0.2, enemy)
						end
						if not enemy:FindFirstChild("NoStun") then
							create("Stun", 0.2, enemy)
						end
					end
				end
			end
		end
	end
	if info.poison and not enemy:FindFirstChild("MonsterInfo") then
		local poisoning = true
		if enemydata and enemydata.Race.Value == "Gaian"then
			poisoning = false
		end
		if enemydata and enemydata.Race.Value == "Lich"then
			poisoning = false
		end
		if enemydata and enemydata.Race.Value == "Scroom"then
			poisoning = false
		end
		if enemydata and enemydata.Race.Value == "Metascroom"then
			poisoning = false
		end
		if EnemyPlayer and EnemyPlayer.Backpack:FindFirstChild("Nature Mastery")then
			poisoning = false
		end
		if enemy:FindFirstChild("Blocking")then
			poisoning = false
		end
		if not enemy:FindFirstChild("Poisoned") and poisoning then
			eroot.Poison:Play()
			eroot.PoisonParticle:Emit(20)
			local v1 = Instance.new("Accessory")
			v1.Name = "Poisoned"
			v1.Parent = enemy
			game.Debris:AddItem(v1,10)
			task.spawn(function(): ()
				local totaldam: number = ehumanoid.MaxHealth/16
				local damage = totaldam/20
				for i: number = 1,20 do
					wait(0.2)
					game.ServerStorage.Requests.TagHumanoid:Fire(enemy,enemy,{damage = damage,nododge = true,nobuff = true, noenchant = true})
					eroot.PoisonParticle:Emit(8)
					create("NoRegen", 0.2, enemy)
				end
				create("PoisonPitCD", 0.6, enemy)
				if v1 then
					v1:Destroy()
				end
			end)
		end
	end

	if info.falldamage then
		if not info.damage then
			info.damage = 1
		end
		if info.damage < 0 then 
			Send(Player.Name.." Banned", "Tried to god mode", Color3.new(0.113725, 0.113725, 0.113725))
			playerdata.Banned.Value = true
			Player:Kick("You've been banned from the game")
			return
		end
		local knockedhealth: number = humanoid.MaxHealth*1.8
		if FindFirstChild(enemy, "Dissolved") then
			for i,v in pairs(enemy:GetChildren()) do
				if v.Name == "Dissolved" then
					task.wait()
					v:Destroy()
				end
			end
		end
		for i,v in pairs(character:GetChildren()) do
			if v.Name == "HeavyAttack" or v.Name == "Action" then
				v:Destroy()
			end
		end
		if info.damage>knockedhealth then
			info.executes = true
		end

		if info.damage < 20 and not character:FindFirstChild("FeatherFall") then
			root.LightFall:Play()
		end

		if info.damage > 20 and not character:FindFirstChild("FeatherFall") then
			if not character:FindFirstChild("InjuryCooldown") then
				root.Fall:Play()
			end
			if info.damage >= humanoid.Health + 20 and info.damage < knockedhealth then
				info.injury = "leg"
				create("Knocked",10,character)
			elseif info.damage < 80 then
				if playerdata.Race.Value ~= "Cameo" then
					create("Knocked",info.damage/15,character)
				else
					create("Knocked",0.25,character)
				end
			elseif info.damage > 80 then
				if playerdata.Race.Value ~= "Cameo" then
					create("Knocked",7,character)
				else
					create("Knocked",0.25,character)
				end
			elseif info.damage >= knockedhealth then
				_G.Death(Player)
			end
		elseif info.damage > 40 and character:FindFirstChild("FeatherFall") then
			if not character:FindFirstChild("InjuryCooldown") then
				root.Fall:Play()
			end
			if info.damage >= humanoid.Health + 20 and info.damage < knockedhealth then
				info.injury = "leg"
				create("Knocked",10,character)
			elseif info.damage < 80 then
				if playerdata.Race.Value ~= "Cameo" then
					create("Knocked",info.damage/15,character)
				else
					create("Knocked",0.25,character)
				end
			elseif info.damage > 80 then
				if playerdata.Race.Value ~= "Cameo" then
					create("Knocked",7,character)
				else
					create("Knocked",0.25,character)
				end
			elseif info.damage >= knockedhealth then
				_G.Death(Player)
			end
		end
	end
	if info.injury and not enemy:FindFirstChild("MonsterInfo")then
		local ignore: boolean = false
		if info.injury == "frostbite"then
			local no = false
			if info.spear and blocking then
				no = true
			end
			if not no then
				commands.StopBurn(enemy)
				local icecase = game.ServerStorage.SpellEffects.FireWhip.IceCase:Clone()
				icecase.CFrame = eroot.CFrame
				icecase.Weld.Part0 = eroot
				icecase.Weld.Part1 = icecase
				icecase.Parent = enemy
				if not FindFirstChild(enemy, "SpellBlocking") then
					create("Knocked",1.3,enemy)
				end
				task.delay(1.3, function()
					icecase:Destroy()
					if not FindFirstChild(enemy, "SpellBlocking") then
						if enemy.Humanoid.Health > 10 then
							enemy.Humanoid:TakeDamage(10)
						else
							enemy.Humanoid.Health = 1
						end
						for i,v in pairs(enemy:GetChildren()) do
							if v.Name == "WakingUp" then
								task.wait()
								v:Destroy()
							end
						end
						task.wait()
						create("Knocked",2,enemy)
						local bv = Instance.new("BodyVelocity")
						CollectionService:AddTag(bv, "AllowedBM")
						bv.MaxForce = Vector3.new(0, 250000, 0)
						bv.Velocity = eroot.CFrame.lookVector.unit * -50
						bv.Name = "FlingVelocity"
						bv.Parent = eroot
						task.delay(0.5, function() bv:Destroy() end)
					end
				end)
				ignore = true
				create("Frostbitten",60,enemy)
			end
		end
		local injurecd = false
		if not enemy:FindFirstChild("InjuryCooldown")or ignore then
			injurecd = true
			if info.injury == "leg" and not enemy:FindFirstChild("Unprotect") then
			else

				eroot.Injury:Play()
				local injury = game.ReplicatedStorage.Assets.Injure:Clone()
				injury.Parent = eroot
				injury:Emit(3)
				game.Debris:AddItem(injury,1.5)
			end
			if EnemyPlayer then
				local danger = enemy:FindFirstChild("Danger")or Instance.new("NumberValue",EnemyPlayer)
				danger.Name = "Danger"
				if danger.Value+45<120 then
					danger.Value+=30
				else
					danger.Value = 120
				end
			end
		end
		if info.injury == "chestgash" and not enemy:FindFirstChild("MonsterInfo") then
			if not blocking then
				if not enemy:FindFirstChild("ImpaleCD") and not enemydata.Injuries.Value:find(info.injury)then
					create("ImpaleCD",20,enemy)
					create("NoRegen",10,enemy)
					if not enemydata.Injuries.Value:find("chestgash") and (not FindFirstChild(EnemyPlayer.Backpack, "SlashResistance")) or enemydata.Race.Value == "Kasparan" then
						enemydata.Injuries.Value = enemydata.Injuries.Value..",chestgash"
					end
				end
			end
		elseif info.injury == "leg"then
			if not enemy:FindFirstChild("InjuryCooldown") and FindFirstChild(enemy, "Unprotect") then
				injurecd = true
				eroot.Bonebreak:Play()
			end
			if FindFirstChild(enemy, "Unprotect") then
				create("Knocked",1.5,enemy)
				if not enemydata.Injuries.Value:find("brokenleg") then 
					enemydata.Injuries.Value = enemydata.Injuries.Value..",brokenleg"
				end	
			else
				create("Unprotect", false, enemy)
			end
		elseif info.injury == "spine"then
			if not enemy:FindFirstChild("InjuryCooldown") then
				injurecd = true
				eroot.Bonebreak:Play()
			end
			create("Knocked",2,enemy)
		end
		if injurecd then
			local f = Instance.new("Accessory") f.Name = "InjuryCooldown" f.Parent = enemy game.Debris:AddItem(f,1)
		end
	end
	if info.shriekerhit then
		local MonsI = character:FindFirstChild("MonsterInfo")
		if MonsI and MonsI.Master.Value and game.Players:GetPlayerFromCharacter(MonsI.Master.Value) and game.Players:GetPlayerFromCharacter(MonsI.Master.Value).Backpack:FindFirstChild("ShriekerHeal") then
			character.MonsterInfo.Master.Value.Humanoid.Health += 8
		end
	end
	if info.damage then
		if info.physical and FindFirstChild(character,"HaseldanDamageMultiplier")then
			info.damage *= 2
		end
		if not info.nobuff then
			local cursecount = getCurseCount(enemy)
			if cursecount > 0 then
				info.damage *= 1 + (cursecount * 0.40)
			end
		end
		if FindFirstChild(character,"LifeSteal") and info.damage then
			local toheal: number = info.damage / 2
			if humanoid.Health + toheal < humanoid.MaxHealth then
				humanoid.Health += toheal
			else
				humanoid.Health = humanoid.MaxHealth
			end
		end
		if ehumanoid.Health - info.damage > 3 or (enemy:FindFirstChild("MonsterInfo") and (enemy.MonsterInfo.MonsterType.Value == "Howler" or enemy.MonsterInfo.MonsterType.Value == "Terra Serpent" or enemy.MonsterInfo.MonsterType.Value == "Zombie Scroom" or enemy.MonsterInfo.MonsterType.Value == "Howwgy")) then
			ehumanoid.Health -= info.damage
		else

			if  (info.executes and info.damage and not enemy:FindFirstChild("Unconscious") and not enemy:FindFirstChild("Knocked") and not enemy:FindFirstChild("SpellBlocking")) or (info.executes and info.damage and info.axe) then
				if ehumanoid.Health>0 or (info.axe and enemy:FindFirstChild("Unconscious")) then
					if Player and Player.Backpack:FindFirstChild("NoKill")then
						if EnemyPlayer then
							for _,v in pairs(EnemyPlayer:GetChildren())do
								if v.Name == "Danger"then
									v:Destroy()
								end
							end
						end
					end
					_G.Death(enemy,character)
				end
				return
			end

			if (not enemy:FindFirstChild("MonsterInfo") or (enemy:FindFirstChild("MonsterInfo") and enemy.MonsterInfo.MonsterType.Value == "Shrieker")) or (enemy:FindFirstChild("MonsterInfo") and (enemy.MonsterInfo.MonsterType.Value ~= "Howler" and enemy.MonsterInfo.MonsterType.Value ~= "Terra Serpent" and enemy.MonsterInfo.MonsterType.Value ~= "Zombie Scroom" and enemy.MonsterInfo.MonsterType.Value ~= "Howwgy")) then
				ehumanoid.Health = 3
				create("Knocked", 10, ehumanoid.Parent)
			end
			if not enemydata or (enemydata and enemydata.Race.Value ~= "Cameo") then
				local v2 = Instance.new("Accessory")
				v2.Name = "Unconscious"
				v2.Parent = ehumanoid.Parent
				game.Debris:AddItem(v2,10)
			elseif enemydata and enemydata.Race.Value == "Cameo" then
				enemydata.Injuries.Value = ""
				if not enemy:FindFirstChild("NoLoss") and game.PlaceId ~= 9329476718 then
					enemydata.Lives.Value-=1
				end
				enemy.Humanoid.PlatformStand = false
				enemy.Humanoid.AutoRotate = true
				if not enemy:FindFirstChild("NoLoss") then
					create("NoLoss", 30, enemy)
				end
				for _,v in pairs(workspace.Live:getChildren())do
					if v ~= enemy and v:FindFirstChild("HumanoidRootPart")then
						if (enemy.HumanoidRootPart.Position-v.HumanoidRootPart.Position).Magnitude<11 then
							game.ServerStorage.Requests.TagHumanoid:Fire(v,v,{mana = true,manaknockupself = true})
						end
					end
				end
				wait()


				for _,v in pairs(enemy:GetChildren())do
					if v.Name == "Knocked"or v.Name == "Unconscious"or v.Name == "Action"or v.Name == "NoDam"or v.Name == "FreezeRoot"then
						v:Destroy()
					end
				end

				enemy.HumanoidRootPart.Cameo:Emit(75)
				enemy.HumanoidRootPart.CameoGetUp:Play()
				enemy.Humanoid.Health += enemy.Humanoid.MaxHealth
				enemy.HumanoidRootPart.LightningHit:Play()

			end
		end
	end
	if info.falldamage and not info.injury then
		return
	end
	if FindFirstChild(character.Artifacts,"Bloodring") and info.damage then
		local Healthback: number = info.damage / 1.6
		if humanoid.Health + Healthback < humanoid.MaxHealth then
			humanoid.Health += Healthback
		else
			humanoid.Health = humanoid.MaxHealth
		end
	end
	if enemy:FindFirstChild("LastHit")then
		enemy.LastHit.Value = tick()
	end
	if EnemyPlayer and character~=enemy or EnemyPlayer and info.falldamage then
		if not info.nocombattag then
			local danger = enemy:FindFirstChild("Danger")or Instance.new("NumberValue",EnemyPlayer)
			danger.Name = "Danger"
			if danger.Value + 30 < 120 then
				danger.Value += 30
			else
				danger.Value = 120
			end
		end
	end
	return anyreturn
end

game.ServerStorage.Requests.TagHumanoid.Event:Connect(taghumanoid)

_G.RemoteTag = taghumanoid -- for returning
