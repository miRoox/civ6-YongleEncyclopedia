-- Yongle Encyclopedia core gameplay definitions

-- Types
INSERT INTO Types (Type, Kind) VALUES
  ('TRAIT_LEADER_WENYUANGE', 'KIND_TRAIT'),
  ('BUILDING_WENYUANGE', 'KIND_BUILDING'),
  ('PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'KIND_PROJECT'),
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'KIND_GREATWORK'),
  ('GREATWORK_YONGLE_FRAGMENT', 'KIND_GREATWORK');

-- Leader trait hookup
INSERT INTO Traits (TraitType, Name, Description)
VALUES ('TRAIT_LEADER_WENYUANGE', 'LOC_TRAIT_LEADER_WENYUANGE_NAME', 'LOC_TRAIT_LEADER_WENYUANGE_DESCRIPTION');

INSERT OR IGNORE INTO LeaderTraits (LeaderType, TraitType)
VALUES ('LEADER_YONGLE', 'TRAIT_LEADER_WENYUANGE');

-- Building: Wenyuan Pavilion (replaces Library for Yongle)
INSERT INTO Buildings (
  BuildingType, Name, Description, PrereqDistrict, PrereqTech, Cost, AdvisorType,
  CitizenSlots, Maintenance, PurchaseYield, ObsoleteEra,
  Housing, TraitType
) VALUES (
  'BUILDING_WENYUANGE', 'LOC_BUILDING_WENYUANGE_NAME', 'LOC_BUILDING_WENYUANGE_DESCRIPTION',
  'DISTRICT_CAMPUS', 'TECH_WRITING', 90, 'ADVISOR_SCIENCE',
  2, 1, 'YIELD_GOLD', 'NO_ERA',
  0, 'TRAIT_LEADER_WENYUANGE'
);

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
VALUES ('BUILDING_WENYUANGE', 'BUILDING_LIBRARY');

INSERT INTO Building_GreatWorks (BuildingType, GreatWorkSlotType, NumSlots)
VALUES ('BUILDING_WENYUANGE', 'GREATWORKSLOT_WRITING', 1);

INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
VALUES ('BUILDING_WENYUANGE', 'YIELD_SCIENCE', 2);

INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
VALUES ('BUILDING_WENYUANGE', 'GREAT_PERSON_CLASS_SCIENTIST', 1);

INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
VALUES ('BUILDING_WENYUANGE', 'GREAT_PERSON_CLASS_WRITER', 1);

-- Project: Compile the Yongle Encyclopedia
INSERT INTO Projects (
  ProjectType, Name, ShortName, Description, RequiredBuilding, Cost, CostProgressionModel,
  CostProgressionParam1, MaxPlayerInstances, AdvisorType
) VALUES (
  'PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_NAME',
  'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_SHORT_NAME', 'LOC_PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA_DESCRIPTION',
  'BUILDING_WENYUANGE', 200, 'NO_PROGRESSION_MODEL',
  0, 1, 'ADVISOR_SCIENCE'
);

-- INSERT INTO Project_GreatWorks (ProjectType, GreatWorkType)
-- VALUES ('PROJECT_COMPILE_YONGLE_ENCYCLOPEDIA', 'GREATWORK_YONGLE_ENCYCLOPEDIA');

-- Great Work: Yongle Encyclopedia (Writing)
INSERT INTO GreatWorks (
  GreatWorkType, GreatWorkObjectType, Name, Quote, Tourism
) VALUES (
  'GREATWORK_YONGLE_ENCYCLOPEDIA', 'GREATWORKOBJECT_WRITING',
  'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_NAME', 'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_QUOTE', 10,
);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_CULTURE', 10);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_SCIENCE', 100);

-- Grant all technology boosts on project completion
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly)
SELECT 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType, 'MODIFIER_PLAYER_GRANT_SPECIFIC_TECH_BOOST', 1, 1, 1
FROM Technologies;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType, 'TechType', TechnologyType
FROM Technologies;

INSERT INTO GreatWorkModifiers (GreatWorkType, ModifierId)
SELECT 'GREATWORK_YONGLE_ENCYCLOPEDIA', 'MODIFIER_YONGLE_ENCYCLOPEDIA_EUREKA_' || TechnologyType
FROM Technologies;

-- Great Work (Artifact): Yongle Encyclopedia Fragment
INSERT INTO GreatWorks (
  GreatWorkType, GreatWorkObjectType, Name, Quote, Tourism, EraType
) VALUES (
  'GREATWORK_YONGLE_FRAGMENT', 'GREATWORKOBJECT_ARTIFACT',
  'LOC_GREATWORK_YONGLE_FRAGMENT_NAME', 'LOC_GREATWORK_YONGLE_FRAGMENT_QUOTE', 2, 'ERA_RENAISSANCE'
);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'YIELD_SCIENCE', 10);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'YIELD_CULTURE', 1);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'YIELD_FAITH', 3);

-- Random tech eureka when acquiring the fragment
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly)
VALUES ('MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA', 'MODIFIER_PLAYER_GRANT_RANDOM_TECHNOLOGY_BOOST_BY_ERA', 1, 1, 1);

INSERT INTO ModifierArguments (ModifierId, Name, Value)
VALUES ('MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA', 'Amount', 5);

INSERT INTO GreatWorkModifiers (GreatWorkType, ModifierId)
VALUES ('GREATWORK_YONGLE_FRAGMENT', 'MODIFIER_YONGLE_FRAGMENT_RANDOM_EUREKA');
