-- Yongle Encyclopedia core gameplay definitions

-- Types
INSERT INTO Types (Type, Kind) VALUES,
  ('GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'KIND_GREAT_PERSON_INDIVIDUAL'),
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'KIND_GREATWORK'),
  ('GREATWORK_YONGLE_FRAGMENT', 'KIND_GREATWORK');

-- Great Person: Xie Jin, grants the Yongle Encyclopedia
INSERT INTO GreatPersonIndividuals (
  GreatPersonIndividualType, Name, GreatPersonClassType, EraType, Gender, ActionRequiresOwnedTile
) VALUES (
  'GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'LOC_GREAT_PERSON_INDIVIDUAL_XIE_JIN_NAME',
  'GREAT_PERSON_CLASS_WRITER', 'ERA_RENAISSANCE', 'GREATPERSON_GENDER_MALE', 1
);

-- INSERT INTO GreatPersonIndividualActionModifiers (GreatPersonIndividualType, ModifierId)
-- VALUES ('GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'MODIFIER_XIE_JIN_CREATE_YONGLE_ENCYCLOPEDIA');

-- INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly)
-- VALUES ('MODIFIER_XIE_JIN_CREATE_YONGLE_ENCYCLOPEDIA', 'MODIFIER_PLAYER_CREATE_GREAT_WORK', 1, 1, 1);

-- INSERT INTO ModifierArguments (ModifierId, Name, Value)
-- VALUES ('MODIFIER_XIE_JIN_CREATE_YONGLE_ENCYCLOPEDIA', 'GreatWorkType', 'GREATWORK_YONGLE_ENCYCLOPEDIA');

-- Great Work: Yongle Encyclopedia (Writing)
INSERT INTO GreatWorks (
  GreatWorkType, GreatPersonIndividualType, GreatWorkObjectType, Name, Quote, Tourism
) VALUES (
  'GREATWORK_YONGLE_ENCYCLOPEDIA', 'GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'GREATWORKOBJECT_WRITING',
  'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_NAME', 'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_QUOTE', 10
);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_CULTURE', 10);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange)
VALUES ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_SCIENCE', 100);

-- Grant all technology boosts on great work acquisition
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
