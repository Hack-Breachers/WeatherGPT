from app.providers.base import DisasterProvider
from app.providers.mock_data import MOCK_DISASTER_EVENTS


class MockDisasterProvider(DisasterProvider):

    def get_disaster_events(self):
        return MOCK_DISASTER_EVENTS
