from app.providers.base import DisasterProvider
from app.providers.gdacs_provider import GDACSProvider


def get_disaster_provider() -> DisasterProvider:
    return GDACSProvider()
