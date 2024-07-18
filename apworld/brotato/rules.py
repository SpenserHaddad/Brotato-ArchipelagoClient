from BaseClasses import CollectionState
from worlds.generic.Rules import CollectionRule

from .items import ItemName


def create_has_run_wins_rule(player: int, count: int) -> CollectionRule:
    def has_wins(state: CollectionState) -> bool:
        return state.has(ItemName.RUN_COMPLETE.value, player, count)

    return has_wins


def create_has_character_rule(player: int, character: str) -> CollectionRule:
    def char_region_access_rule(state: CollectionState):
        return state.has(character, player)

    return char_region_access_rule
