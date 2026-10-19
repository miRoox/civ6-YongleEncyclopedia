-- Inventory is readable only in UI. No yields, properties or RNG are changed here.
local pending = {};
local PROPERTY_PREFIX = "YongleEncyclopedia_Acquired_";

local function CanSend()
  return Game.GetLocalPlayer() >= 0
    and (not GameConfiguration.IsNetworkMultiplayer() or Network.IsGameHost());
end

local function CheckPlayerWorks(playerID)
  if not CanSend() then return; end
  local player = Players[playerID];
  if player == nil then return; end
  for _, city in player:GetCities():Members() do
    local buildings = city:GetBuildings();
    for building in GameInfo.Buildings() do
      if buildings:HasBuilding(building.Index) then
        for slot = 0, buildings:GetNumGreatWorkSlots(building.Index) - 1 do
          local workIndex = buildings:GetGreatWorkInSlot(building.Index, slot);
          if workIndex ~= nil and workIndex >= 0 then
            local work = GameInfo.GreatWorks[buildings:GetGreatWorkTypeFromIndex(workIndex)];
            local key = tostring(playerID) .. ":" .. tostring(workIndex);
            if work ~= nil and (work.GreatWorkType == "GREATWORK_YONGLE_ENCYCLOPEDIA"
                or work.GreatWorkType == "GREATWORK_ARTIFACT_36433025")
                and not pending[key] and not player:GetProperty(PROPERTY_PREFIX .. tostring(workIndex)) then
              pending[key] = true;
              UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT, {
                OnStart = "YongleEncyclopediaAcquire", OwnerID = playerID,
                WorkType = work.GreatWorkType, WorkIndex = workIndex,
                CityID = city:GetID(), BuildingID = building.Index
              });
            end
          end
        end
      end
    end
  end
end

local function CheckAllWorks()
  pending = {};
  if not CanSend() then return; end
  for _, playerID in ipairs(PlayerManager.GetAliveIDs()) do
    CheckPlayerWorks(playerID);
  end
end

local function OnGreatWorkMoved(fromPlayerID, fromCityID, toPlayerID)
  CheckPlayerWorks(toPlayerID);
end

Events.GreatWorkCreated.Add(CheckPlayerWorks);
Events.GreatWorkMoved.Add(OnGreatWorkMoved);
Events.CityTransfered.Add(CheckPlayerWorks);
Events.PlayerTurnActivated.Add(CheckAllWorks);
Events.LoadGameViewStateDone.Add(CheckAllWorks);
print("Yongle Encyclopedia: UI inventory bridge loaded.");
