from __future__ import annotations

from Options import AssembleOptions, Range

from .Constants import (
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    MAX_SHOP_LOCATIONS_PER_TIER,
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


class WavesPerCheck(Range):
    """How many waves to win to receive a check. Smaller values mean more frequent checks."""

    range_start = 1
    range_end = NUM_WAVES

    display_name = "Waves per check"
    default = 10


class NumberCrateDropLocations(Range):
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


class NumberShopItems(Range):
    """The number of items to place in the shop"""

    range_start = 0
    range_end = MAX_SHOP_LOCATIONS_PER_TIER[ItemRarity.COMMON]
    display_name = "Shop items"
    default = 10


options: dict[str, AssembleOptions] = {
    "num_victories": NumberRequiredWins,
    "waves_per_drop": WavesPerCheck,
    "num_common_crate_drops": NumberCrateDropLocations,
    "num_legendary_crate_drops": NumberLegendaryCrateDropLocations,
    "num_shop_items": NumberShopItems,
}
