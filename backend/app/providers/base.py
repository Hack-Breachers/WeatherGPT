from abc import ABC, abstractmethod
from typing import Any


class DisasterProvider(ABC):

    @abstractmethod
    def get_disaster_events(self) -> list[dict[str, Any]]:
        pass
