-- Great Writers create their linked works. ActionCharges=0 is intentional:
-- the engine counts GreatWorks rather than generic action charges.
INSERT INTO Types (Type, Kind) VALUES
  ('GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'KIND_GREAT_PERSON_INDIVIDUAL'),
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'KIND_GREATWORK'),
  ('GREATWORK_ARTIFACT_36433025', 'KIND_GREATWORK');

INSERT INTO GreatPersonIndividuals (
  GreatPersonIndividualType, Name, GreatPersonClassType, EraType, Gender,
  ActionCharges, ActionRequiresOwnedTile, ActionEffectTextOverride
) VALUES (
  'GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'LOC_GREAT_PERSON_INDIVIDUAL_XIE_JIN_NAME',
  'GREAT_PERSON_CLASS_WRITER', 'ERA_RENAISSANCE', 'M', 0, 1,
  'LOC_GREAT_PERSON_INDIVIDUAL_XIE_JIN_DESCRIPTION'
);

INSERT INTO GreatWorks (
  GreatWorkType, GreatWorkObjectType, GreatPersonIndividualType, Name, Quote, Tourism
) VALUES (
  'GREATWORK_YONGLE_ENCYCLOPEDIA', 'GREATWORKOBJECT_WRITING',
  'GREAT_PERSON_INDIVIDUAL_XIE_JIN', 'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_NAME',
  'LOC_GREATWORK_YONGLE_ENCYCLOPEDIA_QUOTE', 10
);

-- Vanilla GreatWorkShowcase parses artifacts as GREATWORK_ARTIFACT_<number>
-- and selects ARTIFACT_1..25 by modulo. This ID reuses ARTIFACT_25 without
-- replacing a base artifact or requiring a replacement UI script.
-- EraType puts the fragment in the Renaissance archaeological artifact pool.
INSERT INTO GreatWorks (
  GreatWorkType, GreatWorkObjectType, Name, Quote, Tourism, EraType
) VALUES (
  'GREATWORK_ARTIFACT_36433025', 'GREATWORKOBJECT_ARTIFACT',
  'LOC_GREATWORK_YONGLE_FRAGMENT_1_NAME', 'LOC_GREATWORK_YONGLE_FRAGMENT_1_QUOTE',
  2, 'ERA_RENAISSANCE'
);

INSERT INTO GreatWork_YieldChanges (GreatWorkType, YieldType, YieldChange) VALUES
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_CULTURE', 10),
  ('GREATWORK_YONGLE_ENCYCLOPEDIA', 'YIELD_SCIENCE', 500),
  ('GREATWORK_ARTIFACT_36433025', 'YIELD_SCIENCE', 50),
  ('GREATWORK_ARTIFACT_36433025', 'YIELD_CULTURE', 1),
  ('GREATWORK_ARTIFACT_36433025', 'YIELD_FAITH', 3);

-- Acquisition effects run in Scripts/YongleEncyclopedia.lua. GreatWorkModifiers
-- are persistent ownership effects, not a reliable once-per-acquisition hook.
