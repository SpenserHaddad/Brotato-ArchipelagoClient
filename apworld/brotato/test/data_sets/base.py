from abc import ABC, abstractmethod
from typing import Any


class BrotatoTestDataSet(ABC):
    @property
    @abstractmethod
    def test_name(self) -> str:
        pass

    @property
    @abstractmethod
    def options_dict(self) -> dict[str, Any]:
        pass
