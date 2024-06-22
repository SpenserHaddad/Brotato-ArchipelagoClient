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
    MAX_SHOP_SLOTS,
    MAX_UNCOMMON_UPGRADES,
    NUM_CHARACTERS,
    NUM_WAVES,
)


class NumberRequiredWins(Range):
    """The number of runs you need to win to complete your goal.

    Each win must be done with a different character.
    """

    range_start = 1
    range_end = NUM_CHARACTERS

    default = 10
    display_name = "Wins Required"


class StartingCharacters(TextChoice):
    """Determines your set of starting characters.

    * Default: Start with Well Rounded, Brawler, Crazy, Ranger and Mage.
    * Shuffle: Start with a random selection of characters.
    """

    option_default_characters = 0
    option_random_characters = 1

    default = 0
    display_name = "Starting Characters"


class NumberStartingCharacters(Range):
    """The number of random characters to start with. Ignored if starting characters is set to 'Default'."""

    range_start = 1
    range_end = NUM_CHARACTERS

    default = 5
    display_name = "Number of Starting Characters"


class WavesPerCheck(Range):
    """How many waves to win to receive a check.

    1 means every wave is a check, 2 means every other wave, etc.
    """

    # We'd make the start 1, but the number of items sent when the game is released is
    # so large that the resulting ReceivedItems command is bigger than Godot 3.5's
    # hard-coded WebSocket buffer can fit, meaning the engine silently drops it.
    range_start = 1
    range_end = NUM_WAVES

    default = 10
    display_name = "Waves Per Check"


class NumberCommonCrateDropLocations(Range):
    """Replaces the in-game loot crate drops with an Archipelago item which must be picked up to generate a check.

    How the drops are made available and how many are needed to make a check are controlled by the next two settings.
    """

    range_start = 0
    range_end = MAX_NORMAL_CRATE_DROPS

    default = 25
    display_name = "Loot Crate Locations"


class NumberCommonCrateDropsPerCheck(Range):
    """The number of common loot crates which need to be picked up to count as a check.

    1 means every crate is a check, 2 means every other crate, etc.
    """

    range_start = 1
    range_end: int = MAX_NORMAL_CRATE_DROPS

    default = 2
    display_name: str = "Crate Pickup Step"


class NumberCommonCrateDropGroups(Range):
    """The number of groups to separate loot crate locations into.

    Once you check all the locations in a group, the randomizer will not drop more loot crate Archipelago items until
    you win more runs.

    The number of loot crate locations will be evenly split among the groups, and the groups will be evenly spread out
    over the number of wins you choose.

    Set to 1 to make all loot crate locations available from the start.
    """

    range_start = 1
    range_end: int = MAX_NORMAL_CRATE_DROP_GROUPS

    default = 1
    display_name: str = "Loot Crate Groups"


class NumberLegendaryCrateDropLocations(Range):
    """Replaces the in-game legendary loot crate drops with an Archipelago item which must be picked up to generate a
    check.

    How the drops are made available and how many are needed to make a check are controlled by the next two settings.
    """

    range_start = 0
    range_end: int = MAX_LEGENDARY_CRATE_DROPS

    default = 5
    display_name: str = "Legendary Loot Crate Locations"


class NumberLegendaryCrateDropsPerCheck(Range):
    """The number of legendary loot crates which need to be picked up to count as a check.

    1 means every crate is a check, 2 means every other crate, etc.
    """

    range_start = 1
    range_end: int = MAX_NORMAL_CRATE_DROPS

    default = 1
    display_name: str = "Legendary Loot Crate Pickup Step"


class NumberLegendaryCrateDropGroups(Range):
    """The number of groups to separate legendary loot crate locations into.

    Once you check all the locations in a group, the randomizer will not drop more legendary loot crate Archipelago
    items until you win more runs.

    The number of loot crate locations will be evenly split among the groups, and the groups will be evenly spread out
    over the number of wins you choose.

    Set to 1 to make all legendary loot crate locations available from the start.
    """

    range_start = 1
    range_end: int = MAX_LEGENDARY_CRATE_DROP_GROUPS

    default = 1
    display_name: str = "Legendary Loot Crate Groups"


class ItemWeights(Choice):
    """Distribution of item tiers when adding (Brotato) items to the (Archipelago) item pool.

    For every common crate drop location, a Brotato weapon/item will be added to the pool. This controls how the item
    tiers are chosen.

    Note that legendary crate drop locations will ALWAYS add a legendary item to the pool, which is in addition to any
    legendary items added by common crate locations.

    * Default: Use the game's normal distribution. Equivalent to setting the custom weights to 100/60/25/8.
    * Chaos: Each tier has a has a random weight.
    * Custom: Use the custom weight options below.
    """

    option_default = 0
    option_chaos = 1
    option_custom = 2

    display_name = "Item Weights"


class CommonItemWeight(Range):
    """The weight of Common/Tier 1/White items in the pool."""

    range_start = 0
    range_end = 100

    default = 100
    display_name = "Common Items"


class UncommonItemWeight(Range):
    """The weight of Unommon/Tier 2/Blue items in the pool."""

    range_start = 0
    range_end = 100

    default = 60
    display_name = "Uncommon Items"


class RareItemWeight(Range):
    """The weight of Rare/Tier 3/Purple items in the pool."""

    range_start = 0
    range_end = 100

    default = 25
    display_name = "Rare Items"


class LegendaryItemWeight(Range):
    """The weight of Legendary/Tier 4/Red items in the pool.

    Note that this is for common crate drop locations only. An additional number of legendary items is also added for
    each legendary crate drop location.
    """

    range_start = 0
    range_end = 100

    default = 8
    display_name = "Legendary Items"


class NumberCommonUpgrades(Range):
    """The number of Common/Tier 1/White upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_COMMON_UPGRADES

    default = 15
    display_name: str = "Common Upgrades"


class NumberUncommonUpgrades(Range):
    """The number of Uncommon/Tier 2/Blue upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_UNCOMMON_UPGRADES

    default = 10
    display_name: str = "Uncommon Upgrades"


class NumberRareUpgrades(Range):
    """The number of Rare/Tier 3/Purple upgrades to include in the item pool."""

    range_start = 0
    range_end: int = MAX_RARE_UPGRADES

    default = 5
    display_name: str = "Rare Upgrades"


class NumberLegendaryUpgrades(Range):
    """The number of Legendary/Tier 4/Red upgrades to include in the item pool."""

    range_start = 0
    range_end = MAX_LEGENDARY_UPGRADES

    default = 5
    display_name = "Legendary Upgrades"


class StartingShopSlots(Range):
    """How many slot the shop begins with. Missing slots are added as items."""

    range_start = 0
    range_end: int = MAX_SHOP_SLOTS

    default = 4
    display_name: str = "Starting Shop Slots"


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
