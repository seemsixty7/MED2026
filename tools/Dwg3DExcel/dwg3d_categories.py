"""Suggested categories for the Dwg3D block library (shared by the export script)."""
import re

# (category, regex on the file name) - first match wins.
RULES = [
    ("Letters/Text", r"LETR|texttest"),
    ("Transformers", r"transformer|xfmr|vantran|kva|CA202003EN|northerntran"),
    ("Cable Tray", r"tray|trenwa|cablehanger|channeltrayhold"),
    ("Unistrut/Supports", r"unistrut|strut|channelelbow|beamclamp|cornclamp|c-clamp|stanchion(?!.*light)|jboxmount|supportmember|opclip|shelfpin"),
    ("Detectors/Gas/Flame", r"detector|detect|gas|flame|detronics|x3301|uvdet|honeywellxnx|motiondet|pirecl"),
    ("Cameras", r"camera|pelco|ptz"),
    ("Horns/PA/Antennas", r"horn|pastation|paga|antenna|transmitter|strobe|foghorn"),
    ("Stations/Push Buttons", r"buttonstation|pushstation|button|estop|stopstation|hoastation"),
    ("Grounding/Lightning", r"ground|gnd|lightning|cadweld|harger|burndy|arrestor|3DLUG|ringterminal|clickbond"),
    ("Lighting", r"light|led|flood|fluorescent|highbay|wallpack|pendant|lamp"),
    ("Receptacles/Switches", r"recept|plug|switch|swict|swicth|weld|disconnect|photocell"),
    ("Junction Boxes/Enclosures", r"jbox|jb\d|jb-|-jb|junction|hawke|hoffman|pullbox|box|scully|skully|skyllu|enclosure|bubc|bubf"),
    ("Conduit Fittings", r"\bLB|3DLB|EYS|ECD|UNY|fitting|sealinghub|gland|roxtec|meyershub|slipfitter|3DT[A-J]\b|3DTB[A-J]?\b|3DT[A-J]$|3DTB[A-J]?$"),
    ("Panels/Racks", r"panel(?!.*solar)|rack|skid|vfd|softstart|squared|flexset|pdc|burnermanagement|mcc|controlpanel"),
    ("Power Equipment", r"gen\d|generac|generator|ats|solar|heater|motor|pump|compressor|flowmeter|rosemount|tank|heattrace|exhaust|louver|acwall|pulley|dodge"),
    ("Hardware/Fasteners", r"bolt|nut|washer|stud|zert|hilti|pin|terminalblock"),
    ("Structural", r"beam|angle|flange|profile|w8x|stair|pole|extrusion|plate"),
    ("People/Misc", r"\bman\b|3D MAN|MAN-1|lifering|studycube|work|sketch|deleted"),
]

CATEGORIES = [
    "Transformers", "Lighting", "Junction Boxes/Enclosures", "Cable Tray", "Unistrut/Supports",
    "Conduit Fittings", "Detectors/Gas/Flame", "Cameras", "Stations/Push Buttons", "Horns/PA/Antennas",
    "Receptacles/Switches", "Panels/Racks", "Power Equipment", "Hardware/Fasteners", "Grounding/Lightning",
    "Structural", "Letters/Text", "People/Misc",
]


def suggest(file_name: str) -> str:
    stem = re.sub(r"\.dwg$", "", file_name.split("\\")[-1], flags=re.I)
    for cat, rx in RULES:
        if re.search(rx, stem, flags=re.I):
            return cat
    return ""
