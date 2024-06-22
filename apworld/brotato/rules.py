from BaseClasses import CollectionState, Item, ItemClassification
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


def legendary_loot_crate_item_rule(item: Item) -> bool:
    """Prevent progression items from being placed at legendary loot crate drops.

    This can cause some very slow/painful BKs if not set

    TODO: Ideally we would make the locations EXCLUDED, but that causes fill problems.
    """
    return item.classification not in (
        ItemClassification.progression,
        ItemClassification.progression_skip_balancing,
    )
