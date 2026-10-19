"""Validate against a real Civ VI database copy; never modifies game caches."""
import argparse
import os
from pathlib import Path
import sqlite3
import xml.etree.ElementTree as ET
import zlib

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "YongleEncyclopedia"
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
ENCYCLOPEDIA = "GREATWORK_YONGLE_ENCYCLOPEDIA"
FRAGMENT = "GREATWORK_ARTIFACT_36433025"


def make_hash(value):
    """Firaxis type hashes are complemented CRC32 stored as signed int32."""
    value = zlib.crc32(value.encode("utf-8")) ^ 0xFFFFFFFF
    return value if value < 0x80000000 else value - 0x100000000


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gameplay-db", type=Path, default=Path(os.environ.get("LOCALAPPDATA", "")) /
                        "Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite")
    parser.add_argument("--game-dir", type=Path, default=Path(
        "C:/Program Files (x86)/Steam/steamapps/common/Sid Meier's Civilization VI"))
    parser.add_argument("--built-mod", type=Path, help="Optional ModBuddy output directory")
    parser.add_argument("--replace-existing", action="store_true",
                        help="Remove this mod's current rows from the in-memory copy before testing SQL")
    args = parser.parse_args()

    # Check both project membership and action registration, including CDATA.
    project = ET.parse(MOD / "YongleEncyclopedia.civ6proj").getroot()
    content = {row.attrib["Include"].replace("\\", "/")
               for row in project.findall("m:ItemGroup/m:Content", NS)}
    for name in content:
        assert (MOD / name).is_file(), f"Missing project content: {name}"
    actions = ET.fromstring(project.find(".//m:InGameActionData", NS).text)
    for action_type, filename in [
        ("UpdateDatabase", "Gameplay/YongleEncyclopedia_Gameplay.sql"),
        ("UpdateText", "Text/YongleEncyclopedia_Text.xml"),
        ("UpdateIcons", "Icons/YongleEncyclopedia_Icons.xml"),
        ("AddGameplayScripts", "Scripts/YongleEncyclopedia.lua"),
        ("AddUserInterfaces", "UI/YongleEncyclopedia_UI.xml"),
        ("ImportFiles", "UI/YongleEncyclopedia_UI.lua"),
    ]:
        assert filename in content
        assert actions.find(f"{action_type}/File").text == filename
    assert actions.find("UpdateArt/File").text == "(Mod Art Dependency File)"

    source = sqlite3.connect(args.gameplay_db.resolve().as_uri() + "?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    source.close()
    # Python SQLite lacks the engine callback used by OnTypeInsert. Verify the
    # implementation against this cache before registering it on the copy.
    assert all(make_hash(name) == value for name, value in db.execute("SELECT Type,Hash FROM Types"))
    db.create_function("Make_Hash", 1, make_hash)
    if args.replace_existing:
        # Only the disposable memory database is changed, never the game cache.
        for table in ["GreatWork_YieldChanges", "GreatWorks"]:
            db.execute(f"DELETE FROM {table} WHERE GreatWorkType IN (?,?)", (ENCYCLOPEDIA, FRAGMENT))
        db.execute("DELETE FROM GreatPersonIndividuals WHERE GreatPersonIndividualType=?",
                   ("GREAT_PERSON_INDIVIDUAL_XIE_JIN",))
        db.execute("DELETE FROM Types WHERE Type IN (?,?,?)",
                   (ENCYCLOPEDIA, FRAGMENT, "GREAT_PERSON_INDIVIDUAL_XIE_JIN"))
        db.commit()
    assert not db.execute("SELECT 1 FROM Types WHERE Type='GREAT_PERSON_INDIVIDUAL_XIE_JIN'").fetchone(), (
        "Use a DebugGameplay.sqlite from a game without this mod enabled")
    baseline_errors = set(db.execute("PRAGMA foreign_key_check"))
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript((MOD / "Gameplay/YongleEncyclopedia_Gameplay.sql").read_text(encoding="utf-8"))
    assert not (set(db.execute("PRAGMA foreign_key_check")) - baseline_errors)
    person = db.execute("SELECT GreatPersonClassType, EraType, Gender, ActionCharges FROM "
                        "GreatPersonIndividuals WHERE GreatPersonIndividualType='GREAT_PERSON_INDIVIDUAL_XIE_JIN'").fetchone()
    assert person == ("GREAT_PERSON_CLASS_WRITER", "ERA_RENAISSANCE", "M", 0)
    assert db.execute("SELECT COUNT(*) FROM GreatWorks WHERE "
                      "GreatPersonIndividualType='GREAT_PERSON_INDIVIDUAL_XIE_JIN'").fetchone()[0] == 1
    for work, tourism, yields in [
        (ENCYCLOPEDIA, 10, {"YIELD_CULTURE": 10, "YIELD_SCIENCE": 500}),
        (FRAGMENT, 2, {"YIELD_SCIENCE": 50, "YIELD_CULTURE": 1, "YIELD_FAITH": 3}),
    ]:
        assert db.execute("SELECT Tourism FROM GreatWorks WHERE GreatWorkType=?", (work,)).fetchone()[0] == tourism
        assert dict(db.execute("SELECT YieldType,YieldChange FROM GreatWork_YieldChanges "
                               "WHERE GreatWorkType=?", (work,))) == yields
    assert db.execute("SELECT EraType FROM GreatWorks WHERE GreatWorkType=?", (FRAGMENT,)).fetchone()[0] == "ERA_RENAISSANCE"
    assert (int(FRAGMENT.removeprefix("GREATWORK_ARTIFACT_")) - 1) % 25 + 1 == 25

    text = ET.parse(MOD / "Text/YongleEncyclopedia_Text.xml").getroot()
    translations = {}
    for group, language in [("BaseGameText", "en_US"), ("LocalizedText", None)]:
        for row in text.findall(group + "/Row"):
            key = (language or row.attrib["Language"], row.attrib["Tag"])
            assert key not in translations, f"Duplicate localization: {key}"
            translations[key] = row.attrib["Text"]
    for locale in ["en_US", "zh_Hans_CN"]:
        for (tag,) in db.execute("SELECT Name FROM GreatWorks WHERE GreatWorkType IN (?,?) "
                                "UNION SELECT Quote FROM GreatWorks WHERE GreatWorkType IN (?,?) "
                                "UNION SELECT Name FROM GreatPersonIndividuals WHERE "
                                "GreatPersonIndividualType='GREAT_PERSON_INDIVIDUAL_XIE_JIN'",
                                (ENCYCLOPEDIA, FRAGMENT, ENCYCLOPEDIA, FRAGMENT)):
            assert (locale, tag) in translations, f"Missing translation: {locale} {tag}"

    art = ET.parse(MOD / "ArtDefs/Yongle_GreatPeople.artdef").getroot()
    writer = art.find("m_RootCollections/Element/Element")
    assert writer.find("m_Name").attrib["text"] == "GREAT_PERSON_INDIVIDUAL_XIE_JIN"
    references = {v.find("m_ParamName").attrib["text"]: v.find("m_ElementName").attrib["text"]
                  for v in writer.findall("m_Fields/m_Values/Element") if v.find("m_ElementName") is not None}
    assert references["ProxyUnit"] == "UNIT_GREAT_WRITER_MALE"
    assert references["Era"] == "ERA_RENAISSANCE"
    specification = ET.parse(MOD / "YongleEncyclopedia.Art.xml").getroot()
    for row in specification.findall("artConsumers/Element/relativeArtDefPaths/Element"):
        assert (MOD / "ArtDefs" / row.attrib["text"]).is_file()

    icons = ET.parse(MOD / "Icons/YongleEncyclopedia_Icons.xml").getroot()
    atlases = {}
    for path in (args.game_dir / "Base/Assets/UI/Icons").glob("*.xml"):
        for row in ET.parse(path).findall("IconTextureAtlases/Row"):
            atlases.setdefault(row.attrib["Name"], []).append(row.attrib)
    for row in icons.findall("IconDefinitions/Row"):
        atlas = atlases[row.attrib["Atlas"]]
        for size in atlas:
            assert int(row.attrib["Index"]) < int(size["IconsPerRow"]) * int(size["IconsPerColumn"])
    for work in [ENCYCLOPEDIA, FRAGMENT]:
        assert icons.find(f"IconDefinitions/Row[@Name='ICON_{work}']") is not None

    if args.built_mod:
        built = args.built_mod
        manifest = ET.parse(built / "YongleEncyclopedia.modinfo").getroot()
        for name in content:
            if not name.startswith("ArtDefs/"):
                assert (built / name).read_bytes() == (MOD / name).read_bytes(), f"Stale packaged file: {name}"
        for row in manifest.findall("Files/File") + manifest.findall("InGameActions/*/File"):
            assert (built / row.text).is_file(), f"Missing packaged file: {row.text}"
        dependency = ET.parse(built / "YongleEncyclopedia.dep").getroot()
        paths = [e.attrib["text"] for e in dependency.findall(
            "SystemDependencies/Element/ArtDefDependencyPaths/Element")]
        assert "Yongle_GreatPeople.artdef" in paths
        for path in paths:
            assert (built / "ArtDefs" / path).is_file()
    print("PASS: real gameplay database, foreign keys, yields, localization, icons, art and project/package references")


if __name__ == "__main__":
    main()
