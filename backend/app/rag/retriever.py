from pathlib import Path
import json


PROTOCOLS_DIR = Path(__file__).parent / "protocols"


def _load_protocols():
    """Load all valid safety protocols from the protocols directory."""
    protocols = []

    for file_path in PROTOCOLS_DIR.glob("*.json"):
        try:
            if file_path.stat().st_size == 0:
                continue

            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            if isinstance(data, list):
                protocols.extend(data)

        except (json.JSONDecodeError, OSError):
            continue

    return protocols


def get_verified_emergency_numbers(
    protocols: list,
    user_intent: str | None = None,
) -> list:
    """
    Extract emergency numbers only from protocols relevant
    to the current emergency context.
    """

    if user_intent != "EMERGENCY":
        return []

    numbers = []

    for protocol in protocols:
        protocol_hazards = {
            str(hazard).upper()
            for hazard in protocol.get("hazard_types", [])
        }

        if "EMERGENCY" not in protocol_hazards:
            continue

        for item in protocol.get("emergency_numbers", []):
            number = item.get("number")

            if number and number not in numbers:
                numbers.append(number)

    return numbers

def retrieve_rag_context(
    query: str,
    verified_hazards: list | None = None,
    user_intent: str | None = None,
) -> str:
    
    """
    Retrieve safety knowledge ONLY for hazards verified by
    the Risk Engine.

    The user's query does not determine which hazard protocol
    is retrieved.
    """

    protocols = _load_protocols()

    verified_hazards = verified_hazards or []

    active_hazards = {
        str(hazard.get("type", "")).upper()
        for hazard in verified_hazards
        if isinstance(hazard, dict)
    }
        # Emergency requests are handled separately from weather hazards.
    # An emergency reported by the user does not need to be detected
    # by the weather Risk Engine.
    if user_intent == "EMERGENCY":
        active_hazards.add("EMERGENCY")

    selected = []

    for protocol in protocols:
        protocol_hazards = {
            str(hazard).upper()
            for hazard in protocol.get("hazard_types", [])
        }

        if active_hazards.intersection(protocol_hazards):
            selected.append(protocol)

    # Remove duplicate protocol IDs.
    unique = []
    seen = set()

    for protocol in selected:
        protocol_id = protocol.get("id")

        if protocol_id not in seen:
            seen.add(protocol_id)
            unique.append(protocol)

    if not unique:
        return (
            "No specific safety protocol is currently verified "
            "for the detected hazards."
        )

    context_parts = []

    for protocol in unique:
        context_parts.append(
            f"VERIFIED SAFETY SOURCE: "
            f"{protocol.get('source', 'Unknown')}\n"
            f"APPLIES TO: "
            f"{', '.join(protocol.get('hazard_types', []))}\n"
            f"SAFETY INSTRUCTIONS: "
            f"{protocol.get('content', '')}"
        )

    return "\n\n".join(context_parts)