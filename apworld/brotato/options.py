from dataclasses import dataclass

from Options import Choice, OptionSet, PerGameCommonOptions, Range, Toggle

from .constants import (
    ABYSSAL_TERRORS_CHARACTERS,
    BASE_GAME_CHARACTERS,
    MAX_COMMON_UPGRADES,
    MAX_LEGENDARY_CRATE_DROP_GROUPS,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_LEGENDARY_UPGRADES,
    MAX_NORMAL_CRATE_DROP_GROUPS,
    MAX_NORMAL_CRATE_DROPS,
    MAX_RARE_UPGRADES,
    MAX_SHOP_SLOTS,
    MAX_UNCOMMON_UPGRADES,
    NUM_WAVES,
    TOTAL_NUM_CHARACTERS,
)


class NumberRequiredWins(Range):
    """The number of runs you need to win to complete your goal.

    Each win must be done with a different character.
    """

    range_start = 1
    range_end = TOTAL_NUM_CHARACTERS

    default = 10
    display_name = "Wins Required"


class StartingCharacters(Choice):
    """Determines your set of starting characters.

    Characters omitted from "Include Characters" will not be included regardless of this option.

    If a DLC option is chosen but the DLC is not enabled, an error will be raised during generation.

    * Default All: Start with the default characters from the base game and all enabled DLCs.
    * Random All: Start with random characters chosen from the base game and all enabled DLCs.
    * Default Base Game: Start with Well Rounded, Brawler, Crazy, Ranger and Mage.
    * Random Base Game: Start with random characters from the base game only.
    * Default Abyssal Terrors: Start with Sailor, Curious, Builder, Captain, and Creature.
    * Random Abyssal Terrors: Start with random characters from the Abyssal Terrors DLC.
    """

    option_default_all = 0
    option_random_all = 1
    option_default_base_game = 2
    option_random_base_game = 3
    option_default_abyssal_terrors = 4
    option_random_abyssal_terrors = 5

    default = 0
    display_name = "Starting Characters"


class NumberStartingCharacters(Range):
    """The number of random characters to start with.

    This is ignored if "Starting Characters" is set to any of the "Default <x>" options, and is clamped to the maximum
    number of characters in the enabled DLCs.
    """

    range_start = 1
    range_end = TOTAL_NUM_CHARACTERS

    default = 5
    display_name = "Number of Starting Characters"


class IncludeBaseGameCharacters(OptionSet):
    """Which base game characters to include for checks.

    Characters not listed here will not be available to play. There will be no item to unlock them, and there will be
    no run or wave complete checks associated with them.
    """

    default = frozenset(BASE_GAME_CHARACTERS.characters)
    display_name = "Include Base Game Characters"
    valid_keys = BASE_GAME_CHARACTERS.characters


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


class GoldRewardMode(Choice):
    """Chooses how gold rewards are given.

    #. One Time: Gold items are only given once, in either the current run or the next run after receiving the item.
    #. All Every Time: The total amount of gold received is given to the player at the start of every run. Since gold is
       a filler item, this can lead to the game being "won" very easily early on in larger multiworlds.
    """

    option_one_time = 0
    option_all_every_time = 1

    default = 0
    display_name = "Gold Reward Mode"


class XpRewardMode(Choice):
    """Chooses how XP rewards are given.

    #. One Time: XP items are only given once, in either the current run or the next run after receiving the item.
    #. All Every Time: The total amount of XP received is given to the player at the start of every run.
    """

    option_one_time = 0
    option_all_every_time = 1

    default = 0
    display_name = "XP Reward Mode"


class EnableEnemyXp(Toggle):
    """Sets enemies will give XP or not.

    If disabled, enemies will not give XP. The only XP will be from XP items in the multiworld. Upgrades will be from
    leveling up and upgrade items received.
    """

    display_name = "Enable Enemy XP"


class SpawnNormalLootCrates(Toggle):
    """Sets whether loot crates can still spawn when connected to a multiworld.

    If off, then the only consumables that spawn will be the health items and the Archipelago drop item. No regular or
    legendary loot crates will spawn.

    If on, then loot crates will still spawn when there are no available Archipelago drops. See 'Loot Crate Groups' for
    details.
    """

    display_name = "Spawn Normal Loot Crates"


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
    """The weight of Uncommon/Tier 2/Blue items in the pool."""

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


class StartingShopLockButtonsMode(Choice):
    """Add the "Lock" buttons in the shop as items.

    Missing buttons will be disabled until they are received as items.

    The button and shop slot are different items, so it's possible to receive the button without the shop.

    * All: Start with all lock buttons enabled (vanilla behavior).
    * None: Start with no lock buttons enabled at start.
    * Match shop slots: Start with the same number of lock buttons as shop slots.
    * Custom: Choose the number to start with using "Number of Lock Buttons".
    """

    option_all = 0
    option_none = 1
    option_match_shop_slots = 2
    option_custom = 3

    default = 2
    display_name = "Starting Shop Lock Buttons"


class NumberStartingShopLockButtons(Range):
    """The number of "Lock" buttons in the shop to start with.

    Missing buttons will not be usable until they are received as items.

    The button and shop slot are different items, so it's possible to receive the button without the shop.
    """

    range_start = 0
    range_end = MAX_SHOP_SLOTS

    default = 0
    display_name = "Number of Lock Buttons"


class EnableAbyssalTerrorsDLC(Toggle):
    """Enable options which require the "Abyssal Terrors" DLC.

    Currently, this only enables adding the checks for all the DLC characters.
    """

    display_name = "Enable Abyssal Terrors DLC"


class IncludeAbyssalTerrorsCharacters(OptionSet):
    """Which characters from the "Abyssal Terrors" DLC to include for checks.

    Characters not listed here will not be available to play. There will be no item to unlock them, and there will be
    no run or wave complete checks associated with them.

    Does nothing if "Enable Abyssal Terrors DLC" is not set.
    """

    default = frozenset(ABYSSAL_TERRORS_CHARACTERS.characters)
    display_name = "Include Abyssal Terrors Characters"
    valid_keys = ABYSSAL_TERRORS_CHARACTERS.characters


@dataclass
class BrotatoOptions(PerGameCommonOptions):
    num_victories: NumberRequiredWins
    starting_characters: StartingCharacters
    include_base_game_characters: IncludeBaseGameCharacters
    num_starting_characters: NumberStartingCharacters
    waves_per_drop: WavesPerCheck
    gold_reward_mode: GoldRewardMode
    xp_reward_mode: XpRewardMode
    enable_enemy_xp: EnableEnemyXp
    spawn_normal_loot_crates: SpawnNormalLootCrates
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
    shop_lock_buttons_mode: StartingShopLockButtonsMode
    num_starting_lock_buttons: NumberStartingShopLockButtons
    enable_abyssal_terrors_dlc: EnableAbyssalTerrorsDLC
    include_abyssal_terrors_characters: IncludeAbyssalTerrorsCharacters
