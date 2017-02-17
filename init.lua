-- A mod that adds darkness around mobs that have a "darkness = true" property

-- Try to generalize to darkness and light

local aura_interval = 3
local aura_chance = 1
local aura_range = 5
local aura_depth = 2

local darken_size = 7
local brighten_size = 3
local particle_rarity = 5

aura = {}

-- ===============
-- Helper functions

-- FIXME - sound plays at all distances.... should not be the case
local function playsound(soundname, pos, gain)
	if not gain then
		gain = 1
	end
	minetest.sound_play({
		name = soundname,
		pos = pos,
		max_hear_distance = 3,
		gain = gain,
	})
end

local function set_aura(pos, range, aurablock, aurasound, particledef)
	if not range then
		range = aura_range
	end
	
	local airnodes = minetest.find_nodes_in_area(
		{x = pos.x - range, y = pos.y - range, z = pos.z - range},
		{x = pos.x + range, y = pos.y + range, z = pos.z + range},
		{"air", "aura:darkness", "aura:light"}
	)
	
	for _,tpos in pairs(airnodes) do
		local reach = vector.distance(pos, tpos)
		if reach > range - aura_depth and reach < range then
			minetest.set_node(tpos, {name = aurablock})

			if math.random(1, particle_rarity) == 1 then
				minetest.after(math.random(1, 10)/10, function()
					particledef.pos = tpos
					minetest.add_particle(particledef)
				end)
			end
		end
	end
	playsound(aurasound, pos)
end

local function darken(pos, range)
	set_aura(pos, range, "aura:darkness", "aura_darkness", {
		pos = pos,
		velocity = {x=0, y=-1, z=0},
		expiration_time = 1,
		size = 1,
		texture = "aura_dark_particle.png",
	})
end

local function brighten(pos, range)
	set_aura(pos, range, "aura:light", "aura_light", {
		pos = pos,
		velocity = {x=0, y=3, z=0},
		expiration_time = 1,
		size = 1,
		texture = "aura_light_particle.png",
	})
end

-- ================
-- Nodes & effects

-- -------------
-- Darkness

minetest.register_node("aura:darkness", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = false,
	walkable = false,
	pointable = false,
	buildable_to = true,
})

minetest.register_node("aura:light", {
	drawtype = "airlike",
	paramtype = "light",
	light_source = 15,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	buildable_to = true,
})

minetest.register_abm({
	nodenames = {"aura:darkness", "aura:light"},
	interval = 5,
	chance = 20,
	action = function(pos)
		minetest.swap_node(pos, {name = "air"})
	end
})

-- ------------------
-- Darkness Generator

minetest.register_node("aura:obsidian", {
	description = "Dark Aura Stone",
	tiles = {"default_obsidian_brick.png"},
	groups = {cracky = 1, level = 2},
	after_place_node = function(pos) darken(pos, darken_size) end
})

minetest.register_abm({
	nodenames = {"aura:obsidian"},
	interval = 10,
	chance = 2,
	action = function(pos)
		darken(pos, darken_size)
	end
})

do
	local base_stone = "default:obsidian"
	local base_magic = "default:mese_crystal"

	minetest.register_craft({
		output = "aura:obsidian",
		recipe = {
			{base_stone, base_stone, base_stone},
			{base_stone, base_magic, base_stone},
			{base_stone, base_stone, base_stone},
		},
	})
end

-- ------------------
-- Glow Generator

minetest.register_node("aura:mese", {
	description = "Bright Aura Stone",
	tiles = {"default_mese_block.png"},
	groups = {cracky = 1, level = 2},
	after_place_node = function(pos) brighten(pos, brighten_size) end
})

minetest.register_abm({
	nodenames = {"aura:mese"},
	interval = 10,
	chance = 2,
	action = function(pos)
		brighten(pos, brighten_size)
	end
})

do
	local base_stone = "default:meselamp"
	local base_magic = "default:mese_crystal"

	minetest.register_craft({
		output = "aura:mese",
		recipe = {
			{base_stone, base_stone, base_stone},
			{base_stone, base_magic, base_stone},
			{base_stone, base_stone, base_stone},
		},
	})
end

-- =======================
-- API

aura.darken = darken
aura.brighten = brighten

function aura.darkness_shroud(self, dtime)
	local mobobj = self.object

	local pos = mobobj:getpos()
	local mobe = mobobj:get_luaentity()
	
	if not mobe.time then
		mobe.time = 0
	end
	
	mobe.time = mobe.time + dtime
	if mobe.time < aura_interval then
		return true
	end
	
	mobe.time = 0
	
	darken(pos)

	if self.aura_effect then
		self:aura_effect()
	end

	return true
end

function aura.holy_glow(self, dtime)
	local mobobj = self.object

	local pos = mobobj:getpos()
	local mobe = mobobj:get_luaentity()
	
	if not mobe.time then
		mobe.time = 0
	end
	
	mobe.time = mobe.time + dtime
	if mobe.time < aura_interval then
		return true
	end
	
	mobe.time = 0
	
	bighten(pos)

	if self.aura_effect then
		self:aura_effect()
	end

	return true
end

minetest.register_chatcommand("darken",{
	privs = {give = true},
	func = function(playername, params)
		local player = minetest.get_player_by_name(playername)
		local pos = player:getpos()
		darken(pos, 10)
	end
})

minetest.register_chatcommand("brighten",{
	privs = {give = true},
	func = function(playername, params)
		local player = minetest.get_player_by_name(playername)
		local pos = player:getpos()
		brighten(pos, 3)
	end
})
