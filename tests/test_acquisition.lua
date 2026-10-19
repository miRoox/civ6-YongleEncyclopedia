-- Behavioral regression tests for the gameplay event handlers, without Civ VI.
-- Run from the repository root: lua tests/test_acquisition.lua
local function rows(data)
  return setmetatable(data, {__call = function()
    local i = 0;
    return function() i = i + 1; return data[i]; end;
  end});
end

local technologies, boosts = {}, {};
for i = 1, 12 do
  technologies[i] = {Index=i, TechnologyType="TECH_" .. i,
    EraType=i <= 8 and "ERA_RENAISSANCE" or "ERA_INDUSTRIAL"};
  boosts[i] = {TechnologyType="TECH_" .. i, Boost=40};
end
technologies[13] = {Index=13, TechnologyType="TECH_FUTURE", EraType="ERA_INDUSTRIAL"};
local eraRows = {[0]={EraType="ERA_ANCIENT"}, [3]={EraType="ERA_RENAISSANCE"},
  [4]={EraType="ERA_INDUSTRIAL"}};
GameInfo = {Technologies=rows(technologies), Boosts=rows(boosts), Eras=eraRows,
  GreatWorks={
    [0]={GreatWorkType="GREATWORK_YONGLE_ENCYCLOPEDIA"},
    [1]={GreatWorkType="GREATWORK_ARTIFACT_36433025"},
    [2]={GreatWorkType="GREATWORK_QU_YUAN_1"}
  }, Buildings=rows({{Index=0}})};

local worldEra, randomCalls = 3, 0;
local inGameplay = false;
Game = {
  GetLocalPlayer=function() return 0; end,
  GetEras=function() return {GetCurrentEra=function() return worldEra; end}; end,
  GetRandNum=function(limit)
    assert(limit > 0, "RNG must never receive an empty candidate list");
    randomCalls = randomCalls + 1;
    return (randomCalls * 3) % limit;
  end
};

local function newPlayer(id)
  local p = {properties={}, boosted={}, researched={}, calls={}, inventory={}, era=3};
  function p:GetProperty(key) return self.properties[key]; end
  function p:SetProperty(key, value) self.properties[key]=value; end
  function p:GetEra() return self.era; end
  local techs = {};
  function techs:HasTech(index) return p.researched[index]; end
  function techs:HasBoostBeenTriggered(index) return p.boosted[index]; end
  function techs:TriggerBoost(index, source)
    assert(source==1 and index~=13);
    assert(not p.boosted[index] and not p.researched[index], "duplicate or completed Eureka");
    p.boosted[index]=true;
    table.insert(p.calls, index);
  end
  function p:GetTechs() return techs; end
  local buildings = {};
  function buildings:HasBuilding(index) return index==0; end
  function buildings:GetNumGreatWorkSlots() assert(not inGameplay, "UI-only API called from Gameplay"); return #p.inventory; end
  function buildings:GetGreatWorkInSlot(building, slot) assert(not inGameplay); return p.inventory[slot+1].instance; end
  function buildings:GetGreatWorkTypeFromIndex(instance)
    assert(not inGameplay);
    for _, work in ipairs(p.inventory) do
      if work.instance==instance then return work.kind; end
    end
    return -1;
  end
  p.city = {GetID=function() return id; end, GetOwner=function() return id; end, GetBuildings=function() return buildings; end};
  function p:GetCities()
    return {Members=function() return ipairs({p.city}); end, FindID=function(_, cityID) if cityID==id then return p.city; end end};
  end
  return p;
end

Players = {[0]=newPlayer(0), [1]=newPlayer(1), [2]=newPlayer(2)};
CityManager = {GetCityAt=function(x) return Players[x] and Players[x].city; end};
GameConfiguration = {IsNetworkMultiplayer=function() return false; end};
Network = {IsGameHost=function() return true; end};
PlayerOperations = {EXECUTE_SCRIPT=1};
PlayerManager = {GetAliveIDs=function()
  local ids = {}; for id in pairs(Players) do table.insert(ids,id); end; table.sort(ids); return ids;
end};
local function loadScript()
  Events = {};
  for _, name in ipairs({"GreatWorkCreated", "GreatWorkMoved", "CityTransfered", "PlayerTurnActivated", "LoadGameViewStateDone"}) do
    local event = {handlers={}};
    function event.Add(callback) table.insert(event.handlers, callback); end
    function event.Fire(...)
      for _, callback in ipairs(event.handlers) do callback(...); end
    end
    Events[name]=event;
  end
  GameEvents = {YongleEncyclopediaAcquire={}};
  local handler;
  function GameEvents.YongleEncyclopediaAcquire.Add(callback) handler=callback; end
  UI = {RequestPlayerOperation=function(sender, operation, parameters)
    assert(not inGameplay and sender==0 and operation==PlayerOperations.EXECUTE_SCRIPT);
    assert(parameters.OnStart=="YongleEncyclopediaAcquire");
    inGameplay=true; handler(sender,parameters); inGameplay=false;
  end};
  inGameplay=true; dofile("YongleEncyclopedia/Scripts/YongleEncyclopedia.lua"); inGameplay=false;
  dofile("YongleEncyclopedia/UI/YongleEncyclopedia_UI.lua");
end
loadScript();

-- The encyclopedia boosts every unresearched, unboosted technology across eras.
local p = Players[0];
p.researched[1], p.boosted[2] = true, true;
p.inventory={{instance=100, kind=0}};
Events.GreatWorkCreated.Fire(0, 0, 0, 0, 0, 100);
assert(#p.calls==10 and p.boosted[12] and not p.boosted[13]);
Events.PlayerTurnActivated.Fire(0, true);
Events.GreatWorkMoved.Fire(0, 0, 0, 0, 0, 0);
assert(#p.calls==10, "same-owner movement/next turn must not repeat the reward");

-- A fragment draws five distinct eligible Eurekas, excluding other eras.
p = Players[1];
p.era=4; -- XP1+ must use the world era, not this player's personal era.
p.researched[1], p.boosted[2] = true, true;
p.inventory={{instance=101, kind=1}};
Events.GreatWorkCreated.Fire(1, -1, 1, 0, 0, 101);
assert(#p.calls==5);
for _, index in ipairs(p.calls) do assert(index>=3 and index<=8); end
local rngAfterFirstAcquisition = randomCalls;
loadScript(); -- Properties survive a save/reload; event callbacks are recreated.
Events.PlayerTurnActivated.Fire(1, true);
Events.GreatWorkMoved.Fire(1, 0, 1, 0, 0, 1);
assert(#p.calls==5 and randomCalls==rngAfterFirstAcquisition, "reload must not reroll");

-- A new civilization receives the transferred work's reward exactly once.
p.inventory={};
local receiver = Players[2];
receiver.inventory={{instance=101, kind=1}};
Events.GreatWorkMoved.Fire(1, 0, 2, 0, 0, 1);
assert(#receiver.calls==5);
receiver.inventory={};
p.inventory={{instance=101, kind=1}};
Events.GreatWorkMoved.Fire(2, 0, 1, 0, 0, 1);
assert(#p.calls==5, "return trades must not farm rewards");

-- Fewer than five remaining: grant all remaining, with no earlier/later fill.
p = newPlayer(3); Players[3]=p;
for i = 1, 7 do p.boosted[i]=true; end
p.inventory={{instance=102, kind=1}};
Events.CityTransfered.Fire(3, 0);
assert(#p.calls==1 and p.calls[1]==8);
p.inventory={{instance=103, kind=1}};
local callsBeforeEmpty = randomCalls;
Events.PlayerTurnActivated.Fire(3, true);
assert(#p.calls==1 and randomCalls==callsBeforeEmpty);

-- Base-game era fallback, empty/ordinary slots, invalid players, and late events.
Game.GetEras=nil;
p=newPlayer(4); Players[4]=p; p.era=4;
p.inventory={{instance=104, kind=1}, {instance=105, kind=2}, {instance=-1}};
Events.PlayerTurnActivated.Fire(4, true);
assert(#p.calls==4);
for _, index in ipairs(p.calls) do assert(index>=9 and index<=12); end
Events.PlayerTurnActivated.Fire(-1, true);
Events.GreatWorkCreated.Fire(-1, -1, -1, 0, 0, -1);

-- An acquisition missed by a not-yet-updated inventory is recovered next turn.
p=newPlayer(5); Players[5]=p;
Events.GreatWorkMoved.Fire(0, 0, 5, 0, 0, 1);
assert(#p.calls==0);
p.inventory={{instance=106, kind=1}};
Events.PlayerTurnActivated.Fire(5, true);
assert(#p.calls==5);
print("PASS: creation, era filtering, random selection, transfers, capture, reload, empty pool and base rules");
