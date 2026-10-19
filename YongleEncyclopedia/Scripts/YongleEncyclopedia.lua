-- Gameplay context: applies to human and AI players, including multiplayer.
local ENCYCLOPEDIA = "GREATWORK_YONGLE_ENCYCLOPEDIA";
local FRAGMENT = "GREATWORK_ARTIFACT_36433025";
local PROPERTY_PREFIX = "YongleEncyclopedia_Acquired_";

-- Technologies without a Eureka (including repeatable future tech) are excluded.
local boostableTechnologies = {};
local hasEureka = {};
for boost in GameInfo.Boosts() do
  if boost.TechnologyType ~= nil and boost.Boost > 0 then
    hasEureka[boost.TechnologyType] = true;
  end
end
for technology in GameInfo.Technologies() do
  if hasEureka[technology.TechnologyType] then
    table.insert(boostableTechnologies, technology);
  end
end
table.sort(boostableTechnologies, function(a, b) return a.Index < b.Index; end);

local function GrantEurekas(player, isFragment)
  local techs = player:GetTechs();
  -- XP1+ uses the world era; base rules use the acquiring civilization's era.
  local eraIndex = player:GetEra();
  if Game.GetEras ~= nil then
    eraIndex = Game.GetEras():GetCurrentEra();
  end
  local eraType = GameInfo.Eras[eraIndex].EraType;
  local candidates = {};
  for _, technology in ipairs(boostableTechnologies) do
    if (not isFragment or technology.EraType == eraType)
        and not techs:HasTech(technology.Index)
        and not techs:HasBoostBeenTriggered(technology.Index) then
      table.insert(candidates, technology.Index);
    end
  end

  if isFragment then
    for _ = 1, math.min(5, #candidates) do
      -- Use the synchronized gameplay RNG, and draw without replacement.
      local choice = Game.GetRandNum(#candidates, "Yongle Encyclopedia fragment Eureka") + 1;
      techs:TriggerBoost(table.remove(candidates, choice), 1);
    end
  else
    for _, technologyIndex in ipairs(candidates) do
      techs:TriggerBoost(technologyIndex, 1);
    end
  end
end

-- Great-work inventory APIs exist only in UI, not Gameplay. The hidden UI
-- context sends a synchronized EXECUTE_SCRIPT operation; only this context
-- changes technology state or consumes the gameplay random number generator.
local function OnAcquire(senderID, parameters)
  if type(parameters) ~= "table" then return; end
  local workType = parameters.WorkType;
  local workIndex = parameters.WorkIndex;
  local player = Players[parameters.OwnerID];
  if player == nil or type(workIndex) ~= "number" or workIndex < 0
      or workIndex ~= math.floor(workIndex)
      or (workType ~= ENCYCLOPEDIA and workType ~= FRAGMENT) then return; end
  local city = player:GetCities():FindID(parameters.CityID);
  if city == nil or not city:GetBuildings():HasBuilding(parameters.BuildingID) then return; end
  local key = PROPERTY_PREFIX .. tostring(workIndex);
  if player:GetProperty(key) then return; end
  player:SetProperty(key, true);
  GrantEurekas(player, workType == FRAGMENT);
  print("Yongle Encyclopedia: acquired", parameters.OwnerID, workType, workIndex);
end

GameEvents.YongleEncyclopediaAcquire.Add(OnAcquire);
print("Yongle Encyclopedia: acquisition handlers loaded.");
