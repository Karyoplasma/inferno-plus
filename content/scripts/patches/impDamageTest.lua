local Script = setmetatable({}, {__index = Base})
Script.__index = Script

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
	local DamnSpell = mechanics:getSpell():isNegative()
	local side= mechanics:getCasterSide()
	
	
--        local oppositeHero = mechanics:getBattle():getHero(1-side)
 --       if oppositeHero then
--		print("OppositeHeroFound!")
  --      end
	
	local function countImpsAndFamiliars(mechanics)
	    local battle = mechanics:getBattle()
	    local battleSide = mechanics:getCasterSide()
	    local imps = 0
	    local familiars = 0
	    local units = battle:getUnitsIf(function(unit)
        	return unit:unitSide() == battleSide
	    end)
	    for _, filtered in ipairs(units) do
        	if filtered:getCreature():getJsonKey() == "core:imp" then
	            imps = imps + filtered:getCount()
        	elseif filtered:getCreature():getJsonKey() == "core:familiar" then
        	    familiars = familiars + filtered:getCount()
        	end
	    end  -- end for loop

	    return imps, familiars
	end -- end local function
	
	-- if a hero casts a negative spell
	if hero and DamnSpell then
		local dmgBonus=0;
		local imps, familiars = countImpsAndFamiliars(mechanics)
		dmgBonus= 0*imps + familiars;
		if dmgBonus > 0 then
			local spellPowerPercent = 100
			local heroBonuses = hero:getBonuses(function(b)
				return (b:getType() == "PRIMARY_SKILL" and b:getSubtype() == "spellpower" and b:getValType()==2)  -- percentToAll=2
			end)
			for i = 1, heroBonuses:size() do
				spellPowerPercent = spellPowerPercent + heroBonuses:getBonus(i):getVal();
			end
				dmgBonus = math.floor(dmgBonus * math.min(1.0,(spellPowerPercent / 100)))
				

		
			local unitBonuses = unit:getBonuses(function(b)
				return b:getType() == "SPELL_DAMAGE_REDUCTION" and (b:getSubtype() == "fire" or b:getSubtype() == "any")
			end)
			
			local unitResist = 0
			for i = 1, unitBonuses:size() do
				unitResist = unitResist + unitBonuses:getBonus(i):getVal()
			end
			dmgBonus = math.floor(dmgBonus * (1 - (unitResist / 100)));
		end
			
		base=base+dmgBonus
	end
	-- continue with whatever it was doing in vanilla
	local chainLength = self.chainLength or 0
	if chainLength > 1 and targetIndex > 0 then
		base = math.floor((self.chainFactor ^ targetIndex) * base)
	end
	return base
end

return Script

