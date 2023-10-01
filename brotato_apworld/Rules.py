from typing import Protocol

from ..AutoWorld import LogicMixin

from .Items import ItemName


class HasItem(Protocol):
    def has(self, item: str, player: int, count: int = 1) -> bool:
        ...


class BrotatoLogic(LogicMixin):
    def _brotato_has_character(self: HasItem, player: int, character: str) -> bool:
        return self.has(character, player)

    def _brotato_has_run_wins(self: HasItem, player: int, count: int) -> bool:
        return self.has(ItemName.RUN_COMPLETE.value, player, count=count)
