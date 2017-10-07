/************************
	kinema by Shendow
	http://steamcommunity.com/id/shendow/

	Copyright (c) 2017

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
************************/

AddCSLuaFile()

KINEMA_CAMPOS = 1
KINEMA_CSMDL = 2
KINEMA_SEQUENCE = 3
KINEMA_SOUND = 4
KINEMA_EFFECT = 5
KINEMA_FADE = 6
KINEMA_SHAKE = 7
KINEMA_EMITTER = 8
KINEMA_HUD = 9
KINEMA_END = 10

_KINEMA_CSMDLS = _KINEMA_CSMDLS or {}
_KINEMA_EMITTERS = _KINEMA_EMITTERS or {}

local RealTime = RealTime

module("kinema", package.seeall)

local Shake
local NextShake = 0

function Perform(act)
	local typ = act.type
	if (CLIENT) then
		if (typ == KINEMA_CAMPOS) then
			hook.Add("CalcView", "kinema", function(ply, pos, angles, fov)
				local t = {origin = act.pos or vector_origin, angles = act.ang or angle_zero, fov = act.fov or fov}
				if (Shake and Shake.end_time > RealTime()) then
					local rt = RealTime()
					local f = 1 - math.Clamp((rt - Shake.start_time) / Shake.dur, 0, 1)
					t.origin = t.origin + VectorRand() * Shake.amp * f
				end

				return t
			end)
		elseif (typ == KINEMA_CSMDL) then
			local name = act.name
			SafeRemoveEntity(_KINEMA_CSMDLS[name])

			local mdl = ClientsideModel(act.mdl)
			mdl:SetPos(act.pos)
			mdl:SetAngles(act.ang)
			_KINEMA_CSMDLS[name] = mdl

			if (act.oncreate) then
				act.oncreate(mdl)
			end
		elseif (typ == KINEMA_SEQUENCE) then
			local mdl = _KINEMA_CSMDLS[act.name]
			if (IsValid(mdl)) then
				mdl:SetCycle(0)
				mdl:ResetSequence(act.seq)
			end
		elseif (typ == KINEMA_SOUND) then
			local snd = act.snd
			local s, e, min, max = string.find(snd, "%((%d+)%-(%d+)%)")
			if (s) then
				snd = snd:sub(1, s - 1) .. math.random(tonumber(min), tonumber(max)) .. snd:sub(e + 1)
			end

			local ptch = 100
			if (isnumber(act.pitch)) then
				ptch = act.pitch
			elseif (istable(act.pitch)) then
				ptch = math.random(act.pitch[1], act.pitch[2])
			end

			if (act.name) then
				local mdl = _KINEMA_CSMDLS[act.name]
				if (IsValid(mdl)) then
					mdl:EmitSound(snd, 75, ptch)
				end
			else
				sound.Play(snd, act.pos, 75, ptch)
			end
		elseif (typ == KINEMA_EFFECT) then
			-- TODO
		elseif (typ == KINEMA_FADE) then
			LocalPlayer():ScreenFade(act.fade, act.color, act.time, act.hold or 0)
		elseif (typ == KINEMA_SHAKE) then
			local t = table.Copy(act)
			t.start_time = RealTime()
			t.end_time = RealTime() + t.dur
			Shake = t
		elseif (typ == KINEMA_EMITTER) then
			local emitter = ParticleEmitter(act.pos)
			act.call(act.pos, emitter)
			table.insert(_KINEMA_EMITTERS, emitter)
		elseif (typ == KINEMA_HUD) then
			local start_fadetime
			local end_fadetime
			if (act.fadein) then
				start_fadetime = RealTime() + act.fadein
			end
			if (act.dur and act.fadeout) then
				end_fadetime = RealTime() + act.dur - act.fadeout
			end
		
			local function func()
				local rt = RealTime()
				local f = 1
				if (start_fadetime and rt <= start_fadetime) then
					f = 1 - (start_fadetime - rt) / act.fadein
				elseif (end_fadetime and rt >= end_fadetime) then
					f = 1 - (RealTime() - end_fadetime) / act.fadeout
				end
				
				f = math.Clamp(f, 0, 1)
			
				if (f > 0) then
					surface.SetAlphaMultiplier(f)
						act.paint()
					surface.SetAlphaMultiplier(1)
				end
			end
		
			hook.Add("HUDPaint", "kinema", (start_fadetime or end_fadetime) and func or act.paint)
		end
	end

	if (typ == KINEMA_END) then
		End()
	end
end

function Execute(obj)
	End()

	local cin = table.Copy(obj)

	local rate = cin.rate or 1
	local starttime = RealTime()
	local endtime = RealTime() + table.maxn(cin.frames) * rate

	local curframe = -1
	hook.Add("Tick", "kinema", function()
		for frame, acts in pairs (cin.frames) do
			if (RealTime() >= starttime + frame * rate and frame > curframe) then
				curframe = frame

				for _, act in pairs (acts) do
					Perform(act)
				end
			end
		end
	end)
end

function End()
	hook.Remove("Tick", "kinema")
	hook.Remove("CalcView", "kinema")
	hook.Remove("HUDPaint", "kinema")

	for cls, mdl in pairs (_KINEMA_CSMDLS) do
		SafeRemoveEntity(mdl)
	end
	for _, emitter in pairs (_KINEMA_EMITTERS) do
		if (IsValid(emitter)) then
			emitter:Finish()
		end
	end

	_KINEMA_CSMDLS = {}
	_KINEMA_EMITTERS = {}
end

function IsActive()
	return hook.GetTable().Tick.kinema ~= nil
end
