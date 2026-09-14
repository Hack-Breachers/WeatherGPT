from typing import Literal


Intent = Literal[
    "THUNDERSTORM",
    "CYCLONE",
    "HEAVY_RAIN",
    "FLOOD",
    "HEAT",
    "EMERGENCY",
    "GENERAL_WEATHER",
]


INTENT_KEYWORDS = {
    "EMERGENCY": [
        "help",
        "emergency",
        "sos",
        "trapped",
        "stranded",
        "rescue",
        "save me",
        "danger",
    ],

    "CYCLONE": [
        "cyclone",
        "cyclonic",
        "cyclonic storm",
        "landfall",
        "storm surge",
    ],

    "THUNDERSTORM": [
        "thunderstorm",
        "thunder",
        "lightning",
        "hail",
        "squall",
    ],

    "HEAVY_RAIN": [
        "heavy rain",
        "heavy rainfall",
        "rainfall",
        "raining",
        "rain",
        "downpour",
    ],

    "FLOOD": [
        "flood",
        "flooding",
        "inundation",
        "waterlogging",
        "water logged",
        "underpass",
    ],

    "HEAT": [
        "heat",
        "heatwave",
        "heat wave",
        "hot",
        "extremely hot",
        "very hot",
        "temperature",
        "heat stress",
        "dehydration",
    ],
}


def detect_intent(query: str) -> Intent:
    """
    Determine the primary topic of the user's question.

    This is deterministic and does not use the LLM.
    """

    query_lower = query.lower().strip()

    # Emergency gets highest priority.
    for keyword in INTENT_KEYWORDS["EMERGENCY"]:
        if keyword in query_lower:
            return "EMERGENCY"

    # Check more specific hazards before generic weather terms.
    priority_order = [
        "CYCLONE",
        "THUNDERSTORM",
        "FLOOD",
        "HEAVY_RAIN",
        "HEAT",
    ]

    for intent in priority_order:
        for keyword in INTENT_KEYWORDS[intent]:
            if keyword in query_lower:
                return intent

    return "GENERAL_WEATHER"