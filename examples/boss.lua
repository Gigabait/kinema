local cinematic = {
	rate = 1,
	frames = {
		[0] = {
			{type = KINEMA_FADE, fade = SCREENFADE.IN, color = color_black, time = 1, hold = 0.5},

			{type = KINEMA_CAMPOS, pos = Vector(2611.991943, -320.963531, 64.031250), ang = Angle(0, 0, 0), fov = 40},
			{type = KINEMA_SHAKE, pos = Vector(2611.991943, -320.963531, 64.031250), amp = 20, dur = 2, radius = 2048},

			{type = KINEMA_CSMDL, name = "boss", mdl = Model("models/player/skeleton.mdl"), pos = Vector(3061.991943, -320.963531, 0.031250), ang = Angle(0, 180, 0), oncreate = function(mdl)
				mdl:SetModelScale(2, 0)
				mdl:SetSequence("zombie_slump_rise_01")
				mdl.RenderOverride = function(me)
					if (!IsValid(me)) then
						return end

					me:FrameAdvance()
					me:DrawModel()

					local realtime = RealTime() * 5

					local matGlow = Material("sprites/glow04_noz")
					local coltouse = Color(255, 0, 255, 125)

					render.SetMaterial(matGlow)
					for i = 0, me:GetBoneCount() - 1, 1 do
						local bone = me:GetBoneMatrix(i)
						if (bone) then
							local pos2 = bone:GetTranslation()
							local sinned = math.sin(realtime + i * 0.1)
							local size1 = 14 + sinned * 12
							local size2 = 20 + sinned * 16
							render.DrawSprite(pos2, size1, size1, Color(255, 255, 255, coltouse.a))
							render.DrawSprite(pos2, size2 + math.Rand(5, 7), size2 + math.Rand(5, 7), coltouse)
						end
					end
				end
			end},

			{type = KINEMA_SOUND, name = "boss", snd = "ambient/materials/metal_rattle.wav"},
			{type = KINEMA_SOUND, name = "boss", snd = "physics/concrete/concrete_break2.wav", pitch = 80},
			{type = KINEMA_EMITTER, pos = Vector(3061.991943, -327.963531, 0.031250), call = function(pos, emitter)
				for i = 1, math.random(14, 16) do
					local vel = VectorRand() * 128
					vel.z = math.Rand(0, 10)

					local var = math.random(0, 80)

					local particle = emitter:Add("particles/smokey", pos)
					particle:SetStartSize(math.random(20, 40))
					particle:SetEndSize(math.random(60, 80))
					particle:SetDieTime(math.random(2, 4))
					particle:SetStartAlpha(math.random(20, 40))
					particle:SetEndAlpha(0)
					particle:SetRoll(math.random(-180, 180))
					particle:SetRollDelta(math.Rand(-1, 1))
					particle:SetColor(210 - var, 180 - var, 140 - var)
					particle:SetVelocity(vel)
					particle:SetAirResistance(math.random(30, 80))
					particle:SetGravity(Vector(0, 0, math.random(0, 15)))
				end
			end}
		},
		[0.5] = {
			{type = KINEMA_SOUND, name = "boss", snd = "player/footsteps/dirt(1-4).wav"},
		},
		[1] = {
			{type = KINEMA_SOUND, name = "boss", snd = "player/footsteps/dirt(1-4).wav"},
		},
		[1.6] = {
			{type = KINEMA_SOUND, name = "boss", snd = "player/footsteps/dirt(1-4).wav"},
			{type = KINEMA_HUD, paint = function()
				local x, y = ScrW() * 0.5, ScrH() * 0.6
				local tx = "The Halloween Boss"
				draw.SimpleTextOutlined(tx, "ChatFont", x, y, Color(255, 165, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)

				local wi, he = surface.GetTextSize(tx)
				local is = 32
				local is2 = is * 0.5
				y = y - is2 + draw.GetFontHeight("ChatFont") * 1.25
			end, fadein = 0.5, dur = 4, fadeout = 0.5},
		},
		[3.4] = {
			{type = KINEMA_SEQUENCE, name = "boss", seq = "menu_zombie_01"},
			{type = KINEMA_SOUND, name = "boss", snd = "vo/halloween_boss/knight_laugh0(1-4).wav", pitch = {90, 100}},
		},
		[5.1] = {
			{type = KINEMA_FADE, fade = SCREENFADE.OUT, color = color_black, time = 0.5, hold = 0.1},
		},
		[5.6] = {
			{type = KINEMA_END},
			{type = KINEMA_FADE, fade = SCREENFADE.IN, color = color_black, time = 0.5, hold = 0.1},
		},
	}
}

kinema.Execute(cinematic)
