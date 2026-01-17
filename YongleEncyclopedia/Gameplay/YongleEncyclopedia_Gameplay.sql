-- Yongle Encyclopedia core gameplay definitions

-- Types
INSERT OR REPLACE INTO Types (Type, Kind) VALUES
  ('TRAIT_LEADER_WENYUANGE', 'KIND_TRAIT'),
  ('BUILDING_WENYUANGE', 'KIND_BUILDING'),
  ('PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'KIND_PROJECT'),
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'KIND_GREATWORK'),
  ('GREATWORK_YONGLE_FRAGMENT', 'KIND_GREATWORK');

-- Leader trait hookup
INSERT OR REPLACE INTO Traits (TraitType, Name, Description)
VALUES ('TRAIT_LEADER_WENYUANGE', 'LOC_TRAIT_LEADER_WENYUANGE_NAME', 'LOC_TRAIT_LEADER_WENYUANGE_DESCRIPTION');

INSERT OR IGNORE INTO LeaderTraits (LeaderType, TraitType)
VALUES ('LEADER_YONGLE', 'TRAIT_LEADER_WENYUANGE');

INSERT OR REPLACE INTO Trait_Buildings (TraitType, BuildingType)
VALUES ('TRAIT_LEADER_WENYUANGE', 'BUILDING_WENYUANGE');

-- Building: Wenyuan Pavilion (replaces Library for Yongle)
INSERT OR REPLACE INTO Buildings (
  BuildingType, Name, Description, PrereqDistrict, PrereqTech, Cost, AdvisorType,
  CitizenSlots, Maintenance, GreatWorkSlotType, GreatWorkCount, OuterDefenseHitPoints,
  Housing, TraitType
) VALUES (
  'BUILDING_WENYUANGE', 'LOC_BUILDING_WENYUANGE_NAME', 'LOC_BUILDING_WENYUANGE_DESCRIPTION',
  'DISTRICT_CAMPUS', 'TECH_WRITING', 80, 'ADVISOR_SCIENCE',
  2, 1, 'GREATWORKSLOT_WRITING', 1, 0,
  0, 'TRAIT_LEADER_WENYUANGE'
);

INSERT OR REPLACE INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
VALUES ('BUILDING_WENYUANGE', 'BUILDING_LIBRARY');

INSERT OR REPLACE INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
VALUES ('BUILDING_WENYUANGE', 'YIELD_SCIENCE', 2);

INSERT OR REPLACE INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
VALUES ('BUILDING_WENYUANGE', 'GREAT_PERSON_CLASS_SCIENTIST', 1);

INSERT OR REPLACE INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
VALUES ('BUILDING_WENYUANGE', 'GREAT_PERSON_CLASS_WRITER', 1);

-- Project: Compile the Yongle Encyclopedia
INSERT OR REPLACE INTO Projects (
  ProjectType, Name, ShortName, Description, PrereqBuilding, Cost, CostProgressionModel,
  CostProgressionParam1, MaxPlayerInstances, AdvisorType
) VALUES (
  'PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_NAME',
  'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_SHORT_NAME', 'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_DESCRIPTION',
  'BUILDING_WENYUANGE', 200, 'COST_PROGRESSION_NONE',
  0, 1, 'ADVISOR_SCIENCE'
);

INSERT OR REPLACE INTO Project_GreatWorks (ProjectType, GreatWorkType)
VALUES ('PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'GREATWORK_YONGLE_ENCYCLOPEDIA');

-- Grant all technology boosts on project completion
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent)
SELECT 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType, 'MODIFIER_PLAYER_GRANT_TECHNOLOGY_BOOST', 1, 1
FROM Technologies;

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType, 'TechnologyType', TechnologyType
FROM Technologies;

INSERT OR REPLACE INTO ProjectCompletionModifiers (ProjectType, ModifierId)
SELECT 'PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType
FROM Technologies;

-- Great Work: Yongle Encyclopedia (Writing)
INSERT OR REPLACE INTO GreatWorks (
  GreatWorkType, GreatWorkClassType, GreatWorkObjectType, Name, Quote, Icon, Image, Tourism, Audio
) VALUES (
  'GREATWORK_YONGLE_ENCYCLOPEDIA', 'GREATWORKCLASS_WRITING', 'GREATWORKOBJECT_WRITING',
  'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_NAME', 'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_QUOTE',
  'ICON_GREATWORK_WRITING', 'WritersAtlas.dds', 0, 'PLAY_AUDIO_TOURISM'
);

INSERT OR REPLACE INTO GreatWorkYieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_CULTURE', 10);

INSERT OR REPLACE INTO GreatWorkYieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_SCIENCE', 100);

-- Great Work (Relic): Yongle Encyclopedia Fragment
INSERT OR REPLACE INTO GreatWorks (
  GreatWorkType, GreatWorkClassType, GreatWorkObjectType, Name, Quote, Icon, Image, Tourism, Audio, EraType
) VALUES (
  'GREATWORK_YONGLE_FRAGMENT', 'GREATWORKCLASS_RELIC', 'GREATWORKOBJECT_RELIC',
  'LOC_GREATWORK_YONGLE_FRAGMENT_NAME', 'LOC_GREATWORK_YONGLE_FRAGMENT_QUOTE',
  'ICON_GREATWORK_RELIC', 'RelicsAtlas.dds', 0, 'PLAY_AUDIO_TOURISM', 'ERA_MEDIEVAL'
);

INSERT OR REPLACE INTO GreatWorkYieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'YIELD_SCIENCE', 3);

INSERT OR REPLACE INTO GreatWorkYieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'YIELD_FAITH', 3);

-- Random tech eureka when acquiring the fragment
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent)
VALUES ('MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA', 'MODIFIER_PLAYER_GRANT_RANDOM_TECHNOLOGY_BOOST', 1, 1);

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES ('MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA', 'Amount', 1);

INSERT OR REPLACE INTO GreatWorkModifiers (GreatWorkType, ModifierId)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA');
