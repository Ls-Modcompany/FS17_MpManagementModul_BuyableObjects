-- 
-- MpManager - Event - BuyableObject
-- 
-- @Interface: 1.5.3.1 b1841
-- @Author: LS-Modcompany/kevink98 
-- @Date: 03.06.2018
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
-- 

MpManagementModul_BuyableObject_LoadClient = {};
MpManagementModul_BuyableObject_LoadClient_mt = Class(MpManagementModul_BuyableObject_LoadClient, Event);
InitEventClass(MpManagementModul_BuyableObject_LoadClient, "MpManagementModul_BuyableObject_LoadClient");
function MpManagementModul_BuyableObject_LoadClient:emptyNew()
    return Event:new(MpManagementModul_BuyableObject_LoadClient_mt);
end;
function MpManagementModul_BuyableObject_LoadClient:new()
    return MpManagementModul_BuyableObject_LoadClient:emptyNew();
end;
function MpManagementModul_BuyableObject_LoadClient:readStream(streamId, connection)
	connection:sendEvent(MpManagementModul_BuyableObject_Load:new());
end;
function MpManagementModul_BuyableObject_LoadClient:writeStream(streamId, connection)
end;

MpManagementModul_BuyableObject_Load = {};
MpManagementModul_BuyableObject_Load_mt = Class(MpManagementModul_BuyableObject_Load, Event);
InitEventClass(MpManagementModul_BuyableObject_Load, "MpManagementModul_BuyableObject_Load");
function MpManagementModul_BuyableObject_Load:emptyNew()
    return Event:new(MpManagementModul_BuyableObject_Load_mt);
end;
function MpManagementModul_BuyableObject_Load:new()
    return MpManagementModul_BuyableObject_Load:emptyNew();
end;
function MpManagementModul_BuyableObject_Load:readStream(streamId, connection)
	local num = streamReadInt32(streamId);
	for i=1, num do
		local index = streamReadInt32(streamId);
		local mpManagerFarm = streamReadString(streamId);
		g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT][index].object.mpManagerFarm = mpManagerFarm;
	end;	
end;

function MpManagementModul_BuyableObject_Load:writeStream(streamId, connection)
	streamWriteInt32(streamId, g_mpManager.utils:getTableLenght(g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT]));
	for index, d in pairs(g_mpManager.assignabels.assignabelsById[g_mpManager.assignabels.BUYABLEOBJECT]) do
		streamWriteInt32(streamId, index);
		streamWriteString(streamId, Utils.getNoNil(d.object.mpManagerFarm, g_mpManager.assignabels.notAssign));
	end;	
end;