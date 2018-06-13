-- 
-- MpManagerModul - BuyableObject
-- 
-- @Interface: 1.5.3.1 b1841
-- @Author: LS-Modcompany/kevink98 
-- @Date: 03.06.2018
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
-- 

local version = "1.0.0.0 (03.06.2018)";

MpManagerModul = {};
MpManagerModul.NONE = 1;
MpManagerModul.BUYABLEOBJECT = 2;

g_mpManager.assignabels.BUYABLEOBJECT = g_mpManager.assignabels:getNextNumber();
g_debug.write(-2, "load MpManagerModul BuyableObject %s", version);

source(g_currentModDirectory .. "Event_BuyableObjects.lua");

function MpManagerModul:load()
	if MpManagerModul.timer == nil then
		MpManagerModul.timer = 100;
		g_currentMission.environment:addHourChangeListener(MpManagerModul);
		g_currentMission.environment:addDayChangeListener(MpManagerModul);
	end;
	if MpManagerModul.timer <= 0 then
		MpManagerModul.activeMoneyStat = MpManagerModul.NONE;		
		
		for _,object in pairs(g_currentMission.onCreateLoadedObjects) do
			if object.className == "BuyableObject" then
				object.hourChanged = MpManagerModul.hourChangedO(object.hourChanged);
				local name = object.buyableText;
				if object.headlineText ~= nil and object.headlineText ~= "" then
					name = object.headlineText;
				end;
				g_mpManager.assignabels:addAssignables(g_mpManager.assignabels.BUYABLEOBJECT, name, object);
			end;
		end;	
		g_mpManager.saveManager:addSave(MpManagerModul.saveSavegame, MpManagerModul);
		if g_server ~= nil then
			MpManagerModul:loadSavegame();
		elseif g_client ~= nil then
			g_client:getServerConnection():sendEvent(MpManagementModul_BuyableObject_LoadClient:new());
		end;
		g_mpManager:removeUpdateable(MpManagerModul);
	else
		MpManagerModul.timer = MpManagerModul.timer - 1;
	end;
end;

function MpManagerModul:hourChanged()
	if g_mpManager.settings:getState("assignabelsBuildings") == 1 then
		MpManagerModul:pay();
	end;
end;
function MpManagerModul:dayChanged()
	if g_mpManager.settings:getState("assignabelsBuildings") == 2 then
		MpManagerModul:pay();
	end;
end;

function MpManagerModul:pay()
	if g_server == nil or not g_mpManager.isConfig then
		return;
	end;	
	local mbo_tbl = g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT];
	if mbo_tbl == nil then
		return;
	end;
	
	local farms = {};
	for _,farm in pairs(g_mpManager.farm:getFarms()) do
		farms[farm] = 0;
	end;	
	
	for _,mbo in pairs(mbo_tbl) do
		local farmname = mbo.object.mpManagerFarm;
		local money = mbo.object.mpManagerMoney;
		if money ~= nil and (money > 0 or money < 0) then
			local split = false;
			if farmname == g_mpManager.assignabels.notAssign or farmname == nil then
				split = true;
			end;
			if split then
				money = money / table.getn(g_mpManager.farm:getFarms());
				for _,farm in pairs(g_mpManager.farm:getFarms()) do
					farms[farm] = farms[farm] + money;					
				end;
			else
				local farm = g_mpManager.utils:getFarmTblFromFarmname(farmname);
				farms[farm] = farms[farm] + money;
			end;
			mbo.object.mpManagerMoney = 0;
		end;
	end;
	
	for farm, money in pairs(farms) do	
		if money ~= 0 then
			g_mpManager.moneyStats:addMoneyStatsToFarm(g_mpManager.moneyStats:getDate(), "--", farm, "other", g_i18n:getText("mpManager_moneyinput_automaticIncome"), "MapBuyableObject", "--", money);
			farm:addMoney(money);
		end;
	end;	
end;

function MpManagerModul:saveSavegame()
	if g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT] ~= nil then
		local index = 0;
		for _,ass in pairs(g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT]) do
			g_mpManager.saveManager:setXmlString(string.format("assignabels.buyableObject.mbo(%d)#name", index), ass.object.buyableText);
			g_mpManager.saveManager:setXmlInt(string.format("assignabels.buyableObject.mbo(%d)#money", index), Utils.getNoNil(ass.object.mpManagerMoney, 0));
			g_mpManager.saveManager:setXmlString(string.format("assignabels.buyableObject.mbo(%d)#mpManagerFarm", index), Utils.getNoNil(ass.object.mpManagerFarm, g_mpManager.assignabels.notAssign));
			index = index + 1;
		end;
	end;
end;
function MpManagerModul:loadSavegame()
	local index = 0;
	while true do
		local addKey = string.format("assignabels.buyableObject.mbo(%d)", index);
		if not g_mpManager.loadManager:hasXmlProperty(addKey) then
			break;
		end;
		local name = g_mpManager.loadManager:getXmlString(addKey .. "#name");
		local mpManagerMoney = g_mpManager.loadManager:getXmlInt(addKey .. "#money");
		local mpManagerFarm = g_mpManager.loadManager:getXmlString(addKey .. "#mpManagerFarm");
		for _,ass in pairs(g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT]) do
			if ass.object.buyableText == name then
				ass.object.mpManagerFarm = mpManagerFarm;
				ass.object.mpManagerMoney = mpManagerMoney;
				break;
			end;
		end;
		index = index + 1;
	end;
end;

function MpManagerModul:run(statType, amount)
	if MpManagerModul.activeMoneyStat == MpManagerModul.BUYABLEOBJECT then
		if MpManagerModul.activeMBO ~= nil then
			if amount ~= 0 then
				local mbo_tbl = g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT];
				for _, mbo in pairs(mbo_tbl) do
					if mbo.object == MpManagerModul.activeMBO then
						if mbo.object.mpManagerMoney == nil then
							mbo.object.mpManagerMoney = 0;
						end;
						mbo.object.mpManagerMoney = mbo.object.mpManagerMoney + amount;
						break;
					end;
				end;
			end;
		else
			g_debug.write(-1, "Can't add money to MBO");
		end;
		return true;
	end;
	return false;
end;

function MpManagerModul.hourChangedO(old)
	return function(s)
		MpManagerModul.activeMoneyStat = MpManagerModul.BUYABLEOBJECT;
		MpManagerModul.activeMBO = s;
		old(s);
		MpManagerModul.activeMoneyStat = MpManagerModul.NONE;
	end;
end;

g_mpManager:addUpdateable(MpManagerModul, MpManagerModul.load);
g_mpManager.modulManager:addModul(MpManagerModul, MpManagerModul.run);