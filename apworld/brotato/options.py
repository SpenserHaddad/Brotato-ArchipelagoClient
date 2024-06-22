from dataclasses import dataclass

from Options import Choice, PerGameCommonOptions, Range, TextChoice

from .constants import (
    MAX_COMMON_UPGRADES,
    MAX_LEGENDARY_CRATE_DROP_GROUPS,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_LEGENDARY_UPGRADES,
    MAX_NORMAL_CRATE_DROP_GROUPS,
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
    range_start = 1
    range_end = NUM_WAVES

    display_name = "Waves per check"
    default = 10


class NumberCommonCrateDropLocations(Range):
    """The number of loot crate locations.

    This replaces the loot crate drops in-game with an Archipelago item which must be picked up.

    How the drops are made available and how many are needed to make a check are controlled by the next two settings.
    """

    range_start = 0
    range_end = MAX_NORMAL_CRATE_DROPS

    display_name = "Number of normal crate drop locations"
    default = 25


class NumberCommonCrateDropsPerCheck(Range):
    """The number of loot crates needed to check a location.

    1 means every loot crate pickup gives a check,
    2 means every other loot crate,
    etc.
    """

    range_start = 0
    range_end: int = MAX_NORMAL_CRATE_DROPS

    display_name: str = "Loot Crates per Check"


class NumberCommonCrateDropGroups(Range):
    """The number of groups to separate loot crate locations into.

    Once you check all the locations in a group, the randomizer will not drop more loot crate Archipelago items until you win more runs.

    The number of loot crate locations will be evenly split among the groups, and the groups will be evenly spread out over the number of wins you choose.

    Set to 1 to make all loot crate locations available from the start.
    """

    range_start = 1
    range_end: int = MAX_NORMAL_CRATE_DROP_GROUPS

    display_name: str = "Loot Crate Groups"
    default = 1


class NumberLegendaryCrateDropLocations(Range):
    """The number of legendary loot crate locations.

    This replaces the legendary loot crate drops in-game with an Archipelago item which must be picked up.

    How the drops are made available and how many are needed to make a check are controlled by the next two settings.
    """

    range_start = 0
    range_end: int = MAX_LEGENDARY_CRATE_DROPS

    display_name: str = "Number of legendary crate drop locations"
    default = 5


class NumberLegendaryCrateDropsPerCheck(Range):
    """The number of legendary loot crates needed to check a location.

    1 means every loot crate pickup gives a check, 2 means every other loot crate, etc.
    """

    range_start = 0
    range_end: int = MAX_NORMAL_CRATE_DROPS
    default = 1

    display_name: str = "Loot crates per check"


class NumberLegendaryCrateDropGroups(Range):
    """The number of groups to separate legendary loot crate locations into.

    Once you check all the locations in a group, the randomizer will not drop more legendary loot crate Archipelago items until you win more runs.

    The number of loot crate locations will be evenly split among the groups, and the groups will be evenly spread out over the number of wins you choose.

    Set to 1 to make all legendary loot crate locations available from the start.
    """

    range_start = 1
    range_end: int = MAX_LEGENDARY_CRATE_DROP_GROUPS
    default = 1
    display_name: str = "Loot Crate Groups"


class ItemWeights(Choice):
    """Distribution of item tiers when adding (Brotato) items to the (Archipelago) item pool.

    For every common crate drop location, a Brotato weapon/item will be added to the pool. This controls how the item
    tiers are chosen.

    Note that legendary crate drop locations will ALWAYS add a legendary item to the pool, which is in addition to any
    legendary items added by common crate locations.

    - Default: Use the game's normal distribution. Equivalent to setting the custom weights to 100/60/25/8.
    - Chaos: Each tier has a has a random weight.
    - Custom: Use the custom weight options below.
    """

    option_default = 0
    option_chaos = 1
    option_custom = 2


class CommonItemWeight(Range):
    """The weight of Common/Tier 1/White items in the pool."""

    range_start = 0
    range_end = 100

    display_name = "Common Items"
    default = 100


class UncommonItemWeight(Range):
    """The weight of Unommon/Tier 2/Blue items in the pool."""

    range_start = 0
    range_end = 100

    display_name = "Uncommon Items"
    default = 60


class RareItemWeight(Range):
    """The weight of Rare/Tier 3/Purple items in the pool."""

    range_start = 0
    range_end = 100

    display_name = "Rare Items"
    default = 60


class LegendaryItemWeight(Range):
    """The weight of Legendary/Tier 4/Red items in the pool.

    Note that this is for common crate drop locations only. An additional number of legendary items is also added for
    each legendary crate drop location.
    """

    range_start = 0
    range_end = 100

    display_name = "Legendary Items"
    default = 8


class NumberCommonUpgrades(Range):
    """The normal of level 1 upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_COMMON_UPGRADES

    display_name: str = "Number of level 1 upgrades"
    default = 15


class NumberUncommonUpgrades(Range):
    """The normal of level 2 upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_UNCOMMON_UPGRADES

    display_name: str = "Number of level 2 upgrades"
    default = 10


class NumberRareUpgrades(Range):
    """The normal of level 3 upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_RARE_UPGRADES

    display_name: str = "Number of level 3 upgrades"
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
    range_end: int = MAX_SHOP_SLOTS
    display_name: str = "Starting shop slots"
    default = 4


class NumberShopItems(Range):
    """The number of items to place in the shop"""

    range_start = 0
    range_end: int = MAX_SHOP_LOCATIONS_PER_TIER[ItemRarity.COMMON]
    display_name: str = "Shop items"
    default = 10


@dataclass
class BrotatoOptions(PerGameCommonOptions):
    num_victories: NumberRequiredWins
    starting_characters: StartingCharacters
    num_starting_characters: NumberStartingCharacters
    waves_per_drop: WavesPerCheck
    num_common_crate_drops: NumberCommonCrateDropLocations
    num_common_crate_drops_per_check: NumberCommonCrateDropsPerCheck
    num_common_crate_drop_groups: NumberCommonCrateDropGroups
    num_legendary_crate_drops: NumberLegendaryCrateDropLocations
    num_legendary_crate_drops_per_check: NumberLegendaryCrateDropsPerCheck
    num_legendary_crate_drop_groups: NumberLegendaryCrateDropGroups
    item_weight_mode: ItemWeights
    common_item_weight: CommonItemWeight
    uncommon_item_weight: UncommonItemWeight
    rare_item_weight: RareItemWeight
    legendary_item_weight: LegendaryItemWeight
    num_common_upgrades: NumberCommonUpgrades
    num_uncommon_upgrades: NumberUncommonUpgrades
    num_rare_upgrades: NumberRareUpgrades
    num_legendary_upgrades: NumberLegendaryUpgrades
    num_starting_shop_slots: StartingShopSlots
    num_shop_items: NumberShopItems
