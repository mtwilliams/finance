--[[

Finance is used to determine accurate market prices and to simplify
the process of exporting World of Warcraft market data from the game.

Send suggestions, comments, and bugs to m.t.williams@live.com

----------------------------------------------------------------------

TODO:
	* Implement a better/cleaner system for scanning auctions
	
	* Seperate scanners from core
		* Core loads all the other modules
	
	* Create a gui
	
	* Create options
	
	* Create a fast scan (getall = true)
	
	* Better error-checking
	
	* Market bias (Supply vs. Demand)

----------------------------------------------------------------------

This file is part of Finance.

WoW-Finance is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

WoW-Finance is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with WoW-Finance.  If not, see <http://www.gnu.org/licenses/>.

----------------------------------------------------------------------

]]--

-- Create the addon
local Finance = LibStub("AceAddon-3.0"):NewAddon("Finance", "AceConsole-3.0", "AceTimer-3.0")

-- Used for scanning
local scanning = false
local page = 0

function Finance:OnInitialize()
	-- Setup saved variables
	self.db = LibStub("AceDB-3.0"):New("FinanceDB")
	
	-- Register the scan command
	Finance:RegisterChatCommand("fscan", "SlashFinanceScan")
	
	-- Item buffer
	self.db.factionrealm.items = {}
	
	-- Alert the user
	Finance:Print("Finance Addon has initialized!")
end

function Finance:OnEnable()

end

function Finance:OnDisable()
end

-- Handle the /fscan
function Finance:SlashFinanceScan(input)	
	-- Check if we can query
	if scanning then
		Finance:Print("Cannot start another well one is in progress.")
		return
	end

	-- Prevent multiple scans
	scanning = true
	
	Finance:Print("Starting scan")
	self.scanTimer = self:ScheduleRepeatingTimer("QueryItems", tonumber(input))
end

-- Query all items in the market by scanning pages
function Finance:QueryItems()
	-- Query the Auction House
	QueryAuctionItems(nil, nil, nil, nil, nil, nil, page, nil, nil, nil)
	
	-- Get the number of items
	local num, total = GetNumAuctionItems("list")
	
	Finance:Print("Starting sub-scan (".. (num+(page*50)) ..",".. total ..")")
	
	-- Store all items
	for i=1,num do
		local itemString = string.match(GetAuctionItemLink("list", i), "item[%-?%d:]+")
		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)
		
		self.db.factionrealm.items[i+(page*50)] = (itemString ..",".. name ..",".. texture ..",".. count ..",".. quality ..",".. level ..",".. buyoutPrice)
	end
	

	if (num+(page*50)) >= total then
		page = 0
		scanning = false
		self:CancelTimer(self.scanTimer)
		Finance:Print("Finished scan")
		return
	end
	
	page = page + 1
end