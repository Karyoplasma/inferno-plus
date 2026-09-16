local Script = setmetatable({}, {__index = Base})
Script.__index = Script

--- adjust the formula here. currently 0 * imps + familiars
local UNIT_WEIGHTS = {
	["core:familiar"] = 1.0,
	["core:imp"] = 0.0
}

--- Returns the target-adjusted damage bonus value
local function getDamageBonusValue(mechanics, target)
	local battle = mechanics:getBattle()
	local side = mechanics:getCasterSide()
	local damageBonus = 0
	local units = battle:getUnitsIf(function(unit)
		return unit:getSide() == side and unit:isAlive() and not unit:isClone()
	end)

	for _, filtered in ipairs(units) do
		local weight = UNIT_WEIGHTS[filtered:getCreature():getJsonKey()]

		if weight then
			damageBonus = damageBonus + (filtered:getCount() * weight)
		end
	end

	damageBonus = math.floor(damageBonus)
	--- adjust Damage bonus for hero skills (Sorcery, etc) and target resistances/vulnerabilities
	if damageBonus > 0 then
		local spell = mechanics:getSpell()
		--- units[1] is never nil at this point
		return spell:adjustDamage(battle, units[1], target, damageBonus)
	else
		return 0
	end
end

function Script:damageForTarget(targetIndex, mechanics, unit)
	local base
	if self.killByPercentage then
		local toKill = math.floor(unit:getCount() * mechanics:getEffectValue() / 100)
		base = toKill * unit:getMaxHealth()
	elseif self.killByCount then
		base = mechanics:getEffectValue() * unit:getMaxHealth()
	else
		base = mechanics:adjustEffectValue(unit)
	end
	-- check for our new bonus type
	local hero = mechanics:getHeroCaster()
--        local oppositeHero = mechanics:getBattle():getHero(1-side)
 --       if oppositeHero then
--		print("OppositeHeroFound!")
  --      end

	-- if a hero casts the damage spell
	if hero then
		base = base + getDamageBonusValue(mechanics, unit)
	end

	-- continue with whatever it was doing in vanilla
	local chainLength = self.chainLength or 0
	if chainLength > 1 and targetIndex > 0 then
		base = math.floor((self.chainFactor ^ targetIndex) * base)
	end
	return base
end

return Script