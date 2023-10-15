from __future__ import annotations

from Options import AssembleOptions, Range, TextChoice

from .Constants import (
    MAX_COMMON_UPGRADES,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_LEGENDARY_UPGRADES,
    MAX_NORMAL_CRATE_DROPS,
    MAX_RARE_UPGRADES,
    MAX_SHOP_LOCATIONS_PER_TIER,
    MAX_SHOP_SLOTS,
    MAX_UNCOMMON_UPGRADES,
    NUM_CHARACTERS,
    NUM_WAVES,
    ItemRarity,
)


class NumberRequiredWins(Range):
    """The number of characters you must complete runs with to win."""

    range_start = 1
    range_end = NUM_CHARACTERS

    display_name = "Number of runs required"
    default = 10


class StartingCharacters(TextChoice):
    """Determines your set of starting characters.

    Default: Start with Well Rounded, Brawler, Crazy, Ranger and Mage.

    Shuffle: Start with a random selection of characters.
    """

    option_default_characters = 0
    option_random_characters = 1

    display_name = "Starting characters"
    default = 0


class NumberStartingCharacters(Range):
    """The number of random characters to start with. Ignored if starting characters is set to 'Default'."""

    range_start = 1
    range_end = NUM_CHARACTERS

    display_name = "Number of starting characters"
    default = 5


class WavesPerCheck(Range):
    """How many waves to win to receive a check. Smaller values mean more frequent checks."""

    # We'd make the start 1, but the number of items sent when the game is released is
    # so large that the resulting ReceivedItems command is bigger than Godot 3.5's
    # hard-coded WebSocket buffer can fit, meaning the engine silently drops it.
    range_start = 2
    range_end = NUM_WAVES

    display_name = "Waves per check"
    default = 10


class NumberCommonCrateDropLocations(Range):
    """
    The first <count> normal crate drops will be AP locations.
    """

    range_start = 0
    range_end = MAX_NORMAL_CRATE_DROPS

    display_name = "Number of normal crate drop locations"
    default = 25


class NumberLegendaryCrateDropLocations(Range):
    """
    The first <count> legendary crate drops will be AP locations.
    """

    range_start = 0
    range_end = MAX_LEGENDARY_CRATE_DROPS

    display_name = "Number of legendary crate drop locations"
    default = 5


class NumberCommonUpgrades(Range):
    """The normal of level 1 upgrades to include in the item pool."""

    range_start = 0
    range_end = MAX_COMMON_UPGRADES

    display_name = "Number of level 1 upgrades"
    default = 15


class NumberUncommonUpgrades(Range):
    """The normal of level 2 upgrades to include in the item pool."""

    range_start = 0
    range_end = MAX_UNCOMMON_UPGRADES

    display_name = "Number of level 2 upgrades"
    default = 10


class NumberRareUpgrades(Range):
    """The normal of level 3 upgrades to include in the item pool."""

    range_start = 0
    range_end = MAX_RARE_UPGRADES

    display_name = "Number of level 3 upgrades"
    default = 5


class NumberLegendaryUpgrades(Range):
    """The normal of level 4 upgrades to include in the item pool."""

    range_start = 0
    range_end = MAX_LEGENDARY_UPGRADES

    display_name = "Number of level 4 upgrades"
    default = 5


class StartingShopSlots(Range):
    """How many slot the shop begins with. Missing slots are added as items."""

    range_start = 0
    range_end = MAX_SHOP_SLOTS
    display_name = "Starting shop slots"
    default = 4


class NumberShopItems(Range):
    """The number of items to place in the shop"""

    range_start = 0
    range_end = MAX_SHOP_LOCATIONS_PER_TIER[ItemRarity.COMMON]
    display_name = "Shop items"
    default = 10


options: dict[str, AssembleOptions] = {
    "num_victories": NumberRequiredWins,
    "starting_characters": StartingCharacters,
    "num_starting_characters": NumberStartingCharacters,
    "waves_per_drop": WavesPerCheck,
    "num_common_crate_drops": NumberCommonCrateDropLocations,
    "num_legendary_crate_drops": NumberLegendaryCrateDropLocations,
    "num_common_upgrades": NumberCommonUpgrades,
    "num_uncommon_upgrades": NumberUncommonUpgrades,
    "num_rare_upgrades": NumberRareUpgrades,
    "num_legendary_upgrades": NumberLegendaryUpgrades,
    "num_starting_shop_slots": StartingShopSlots,
    # "num_shop_items": NumberShopItems,
}
