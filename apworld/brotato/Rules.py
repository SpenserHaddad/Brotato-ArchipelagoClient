from BaseClasses import CollectionState

from ..AutoWorld import LogicMixin
from .Items import ItemName


class BrotatoLogic(LogicMixin):
    def _brotato_has_character(self: CollectionState, player: int, character: str) -> bool:
        return self.has(character, player)

    def _brotato_has_run_wins(self: CollectionState, player: int, count: int) -> bool:
        return self.has(ItemName.RUN_COMPLETE.value, player, count=count)
