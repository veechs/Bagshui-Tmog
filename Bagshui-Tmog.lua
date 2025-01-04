-- Bagshui-Tmog
-- Add support for Turtle WoW transmog collection to Bagshui's Transmog()
-- function by leveraging data cached by Tmog.

-- Explicit access to global environment for clarity.
local _G = _G or getfenv()

-- Pointer to Bagshui utility functions (set up in `BagshuiTmog:Init()`).
-- Declaring here so it stays in local scope.
local BsUtil

-- Need a frame to process events.
local BagshuiTmog = _G.CreateFrame("Frame")
_G.BagshuiTmog = BagshuiTmog  -- Expose globally.


--- Event handler.
--- Vanilla event parameters come via global variables, not function parameters.
BagshuiTmog:SetScript("OnEvent", function()

	-- This is entirely unnecessary, but it's nice QOL to have the Organize
	-- toolbar icon light up if an inventory window is open when transmog
	-- collection changes happen.
	-- Putting this first because it's going to happen the most.
	if
		(
			-- Turtle Transmog API messages.
			_G.event == "CHAT_MSG_ADDON"
			and string.find(_G.arg1, "TW_TRANSMOG", 1, true)
			and _G.arg4 == _G.UnitName("player")
		)
		or (
			-- Tmog also monitors the player inventory and adds items
			-- to its cache as they're equipped.
			_G.event == "UNIT_INVENTORY_CHANGED"
			and _G.arg1 == "player" 
		)
	then
		-- Make sure there was a change (delay slightly so Tmog can do its work).
		Bagshui:QueueClassCallback(BagshuiTmog, BagshuiTmog.CheckForChanges, 0.05)
		return
	end

	-- Startup.
	if _G.event == "ADDON_LOADED" then
		if _G.arg1 == "Bagshui-Tmog" then
			BagshuiTmog:Init()
		end
		return
	end

end)
-- Get bootstrapped and we'll register additional events in `BagshuiTmog:Init()`.
BagshuiTmog:RegisterEvent("ADDON_LOADED")



-- Initialize our addon.
function BagshuiTmog:Init()

	-- The TOC shouldn't let these conditions occur but we'll check just to be safe.
	if not _G.IsAddOnLoaded("Bagshui") then
		Bagshui:PrintError("Bagshui-Tmog requires Bagshui.")
		return
	end
	if not _G.IsAddOnLoaded("Tmog") then
		Bagshui:PrintError("Bagshui-Tmog requires Tmog.")
		return
	end
	if not _G.TMOG_CACHE then
		Bagshui:PrintError("Tmog collection cache not found - Bagshui-Tmog cannot load.")
		return
	end

	-- Point our local BsUtil to the Bagshui utility functions.
	BsUtil = Bagshui.components.Util

	-- Register for the additional events we need to monitor for Tmog changes.
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")

	-- This is our copy of the Tmog cache so we can determine when changes happen.
	self.TmogCacheCache = {}
	self:UpdateCache()

	--- Register to handle the Transmog() rule function.
	Bagshui:AddRuleFunction({
		functionNames = {
			"Transmog",
			"Tmog",
		},
		ruleFunction = function(rules, ruleArguments)
			-- It really shouldn't be possible to fail this condition, but just in case!
			if not _G.IsAddOnLoaded("Tmog") then
				rules.errorMessage = string.format(L.Error_AddonDependency, "Tmog")
				return false
			end

			-- Reusable table for slot names to IDs.
			-- Used to check transmog eligibility and process the transmog collection.
			-- This is a local in Tmog and we need the information here.
			if not rules._tmog_SlotIds then
				rules._tmog_SlotIds = {
					["INVTYPE_HEAD"] = 1,
					["INVTYPE_SHOULDER"] = 3,
					["INVTYPE_CHEST"] = 5,
					["INVTYPE_ROBE"] = 5,
					["INVTYPE_WAIST"] = 6,
					["INVTYPE_LEGS"] = 7,
					["INVTYPE_FEET"] = 8,
					["INVTYPE_WRIST"] = 9,
					["INVTYPE_HAND"] = 10,
					["INVTYPE_CLOAK"] = 15,
					["INVTYPE_WEAPONMAINHAND"] = 16,
					["INVTYPE_2HWEAPON"] = 16,
					["INVTYPE_WEAPON"] = 16,
					["INVTYPE_WEAPONOFFHAND"] = 17,
					["INVTYPE_HOLDABLE"] = 17,
					["INVTYPE_SHIELD"] = 17,
					["INVTYPE_RANGED"] = 18,
					["INVTYPE_RANGEDRIGHT"] = 18,
					["INVTYPE_TABARD"] = 19,
					["INVTYPE_BODY"] = 4,
					["INVTYPE_RELIC"] = 18,
				}
			end

			-- Decide how to handle the call.
			if ruleArguments[1] == rules.environment.Eligible then
				-- Just check eligibility (call was `Transmog(Eligible)`).
				return (
					string.len(rules.item.equipLocation or "") > 0
					and rules._tmog_SlotIds[rules.item.equipLocation] ~= nil
				)

			else
				-- Is the item in the transmog collection? (Call was `Transmog()`).

				-- Here's a sample of the data we're looking at.
				-- TMOG_CACHE = {
				--     [1] = {
				--         [4322] = "Enchanter's Cowl",
				--         [21525] = "Green Winter Hat",
				--         [80221] = "Forever-Lovely Rose",
				--         [41503] = "Black Banded Top Hat",
				--         [51219] = "Woolen Cowl",
				--     },
				--     [3] = {
				--         [17047] = "Luminescent Amice",
				--         [14170] = "Buccaneer's Mantle",
				--     },
				-- },

				-- Make sure things are ready to go.
				if type(_G.TMOG_CACHE) ~= "table" then
					return false
				end

				-- Comparisons are done on item ID and require it to be equippable.
				if
					not rules.item.id or rules.item.id == 0
					or string.len(rules.item.equipLocation or "") == 0
					or not rules._tmog_SlotIds[rules.item.equipLocation]
					or not _G.TMOG_CACHE[rules._tmog_SlotIds[rules.item.equipLocation]]
				then
					return false
				end

				-- Determine whether the item is in the transmog collection.
				return (_G.TMOG_CACHE[rules._tmog_SlotIds[rules.item.equipLocation]][rules.item.id] == rules.item.name)

			end

		end
	})
end



--- Compare Tmog's cache with our copy to see if Bagshui should be notified of changes.
function BagshuiTmog:CheckForChanges()
	if not BsUtil.ObjectsEqual(_G.TMOG_CACHE, self.TmogCacheCache) then
		Bagshui:QueueInventoryUpdate(0.1, true)
		self:UpdateCache()
	end
end



--- Make a copy of Tmog's cache so we can compare in `BagshuiTmog:CheckForChanges()`.
function BagshuiTmog:UpdateCache()
	-- 3rd param: Force key-value copy. Since TMOG_CACHE has a [1] element but is actually a
	-- key-value table, we need to copy using `pairs()` instead of `ipairs()`.
	BsUtil.TableCopy(_G.TMOG_CACHE, self.TmogCacheCache, true)
end
