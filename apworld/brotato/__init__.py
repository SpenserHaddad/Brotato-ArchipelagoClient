import logging
from dataclasses import asdict
from typing import Any, ClassVar

from BaseClasses import Item, MultiWorld, Region, Tutorial
from Options import OptionError, OptionGroup
from worlds.AutoWorld import WebWorld, World

from . import options  # So we don't need to import every option class when defining option groups
from .characters import get_available_and_starting_characters
from .constants import (
    MAX_SHOP_SLOTS,
    RUN_COMPLETE_LOCATION_TEMPLATE,
)
from .items import BrotatoItem, ItemName, filler_items, item_name_groups, item_name_to_id, item_table
from .locations import location_name_groups, location_name_to_id
from .loot_crates import (
    BrotatoLootCrateGroup,
    build_loot_crate_groups,
    create_items_for_loot_crate_locations,
    get_wave_for_each_item,
)
from .options import (
    BrotatoOptions,
)
from .regions import create_regions
from .rules import create_has_run_wins_rule
from .shop_slots import get_num_shop_slot_and_lock_button_items
from .waves import get_waves_with_checks

logger = logging.getLogger("Brotato")


class BrotatoWeb(WebWorld):
    # TODO: Add actual tutorial!
    tutorials = [
        Tutorial(
            "Multiworld Setup Guide",
            "A guide to setting up the Brotato randomizer connected to an Archipelago Multiworld",
            "English",
            "setup_en.md",
            "setup/en",
            ["RampagingHippy"],
        )
    ]
    theme = "dirt"
    rich_text_options_doc = True

    option_groups = [
        OptionGroup(
            "Loot Crates",
            [
                options.SpawnNormalLootCrates,
                options.NumberCommonCrateDropLocations,
                options.NumberCommonCrateDropsPerCheck,
                options.NumberCommonCrateDropGroups,
                options.NumberLegendaryCrateDropLocations,
                options.NumberLegendaryCrateDropsPerCheck,
                options.NumberLegendaryCrateDropGroups,
            ],
        ),
        OptionGroup(
            "Item Rewards",
            [
                options.ItemWeights,
                options.CommonItemWeight,
                options.UncommonItemWeight,
                options.RareItemWeight,
                options.LegendaryItemWeight,
            ],
        ),
        OptionGroup(
            "Upgrades",
            [
                options.NumberCommonUpgrades,
                options.NumberUncommonUpgrades,
                options.NumberRareUpgrades,
                options.NumberLegendaryUpgrades,
            ],
        ),
        OptionGroup(
            "Shop Slots",
            [options.StartingShopSlots, options.StartingShopLockButtonsMode, options.NumberStartingShopLockButtons],
        ),
        OptionGroup(
            "Abyssal Terrors DLC",
            [options.EnableAbyssalTerrorsDLC, options.IncludeAbyssalTerrorsCharacters],
        ),
    ]


class BrotatoWorld(World):
    """
    Brotato is a top-down arena shooter roguelite where you play a potato wielding up to
    6 weapons at a time to fight off hordes of aliens. Choose from a variety of traits
    and items to create unique builds and survive until help arrives.
    """

    options_dataclass = BrotatoOptions
    options: BrotatoOptions  # type: ignore
    game: ClassVar[str] = "Brotato"
    web = BrotatoWeb()
    data_version = 0
    required_client_version: tuple[int, int, int] = (0, 5, 0)

    item_name_to_id: ClassVar[dict[str, int]] = item_name_to_id
    item_name_groups: ClassVar[dict[str, set[str]]] = item_name_groups

    _filler_items: list[str] = filler_items
    _starting_characters: list[str]
    _include_characters: list[str]
    """The characters whose locations (wave/run complete) may have progression and useful items.

    This is derived from options.include_characters.

    This is a distinct list from the options value because:

    * We want to sanitize the list to make sure typos or other errors don't cause bugs down the road.
    * We want to keep things in character definition order for readability by using a list instead of a set.
    """

    location_name_to_id: ClassVar[dict[str, int]] = location_name_to_id
    location_name_groups: ClassVar[dict[str, set[str]]] = location_name_groups

    num_shop_slot_items: int
    num_shop_lock_button_items: int

    waves_with_checks: list[int]
    """Which waves will count as locations.

    Calculated from player options in generate_early.
    """

    common_loot_crate_groups: list[BrotatoLootCrateGroup]
    """Information about each common loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early().
    """

    legendary_loot_crate_groups: list[BrotatoLootCrateGroup]
    """Information about each legendary loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early().
    """

    _upgrade_and_item_counts: dict[ItemName, int]
    """Amount of each upgrade tier and Brotato item to add to the item pool.

    Calculated from player options in generate_early(). The counts may be less than the actual amount requested if there
    is not enough locations for them all (which can happen if too many characters are excluded from having progression
    items), in which case items from here will be randomly removed until they fit.
    """

    _num_filler_items: int
    """The number of filler items to create. Calculated in generate_early()."""

    def __init__(self, world: MultiWorld, player: int) -> None:
        super().__init__(world, player)

    def create_item(self, name: str | ItemName) -> BrotatoItem:
        if isinstance(name, ItemName):
            name = name.value
        return item_table[self.item_name_to_id[name]].to_item(self.player)

    def generate_early(self) -> None:
        # Determine needed values from the options
        self.waves_with_checks = get_waves_with_checks(self.options.waves_per_drop)

        self._include_characters, self._starting_characters = get_available_and_starting_characters(
            self.options.include_base_game_characters.value,
            bool(self.options.enable_abyssal_terrors_dlc.value),
            self.options.include_abyssal_terrors_characters.value,
            self.options.starting_characters,
            self.options.num_starting_characters.value,
            self.options.num_characters.value,
            self.random,
        )

        # Clamp the number of wins needed to goal to the number of included characters, so the game isn't unwinnable.
        # Note that we need to actually change the option value, not just clamp it, otherwise other parts of the world
        # will miss it. This has caused bugs in the past.
        self.options.num_victories.value = min(self.options.num_victories.value, len(self._include_characters))

        # Thought: if num victories is clamped, do some of the groups become unreachable?
        self.common_loot_crate_groups = build_loot_crate_groups(
            self.options.num_common_crate_drops.value,
            self.options.num_common_crate_drop_groups.value,
            self.options.num_victories.value,
        )
        self.legendary_loot_crate_groups = build_loot_crate_groups(
            self.options.num_legendary_crate_drops.value,
            self.options.num_legendary_crate_drop_groups.value,
            self.options.num_victories.value,
        )

        self.num_shop_slot_items, self.num_shop_lock_button_items = get_num_shop_slot_and_lock_button_items(
            self.options.num_starting_shop_slots,
            self.options.shop_lock_buttons_mode,
            self.options.num_starting_lock_buttons,
        )

        num_total_locations = sum(
            [
                # Wave complete checks
                len(self.waves_with_checks) * len(self._include_characters),
                # Run won
                len(self._include_characters),
                # Common and legendary crate drops
                self.options.num_common_crate_drops.value,
                self.options.num_legendary_crate_drops.value,
            ]
        )

        num_required_items = sum(
            [
                # Each character, and each run won item for each character
                2 * len(self._include_characters),
                self.num_shop_slot_items,
                self.num_shop_lock_button_items,
            ]
        )

        num_nonessential_items = num_total_locations - num_required_items

        # Initialize the number of upgrades and items to include, then adjust as necessary below.
        self._upgrade_and_item_counts = {
            ItemName.COMMON_UPGRADE: self.options.common_upgrade_weight.value,
            ItemName.UNCOMMON_UPGRADE: self.options.uncommon_upgrade_weight.value,
            ItemName.RARE_UPGRADE: self.options.rare_upgrade_weight.value,
            ItemName.LEGENDARY_UPGRADE: self.options.legendary_upgrade_weight.value,
        }

        num_items_per_rarity: dict[ItemName, int] = create_items_for_loot_crate_locations(
            self.options.num_common_crate_drops,
            self.options.num_legendary_crate_drops,
            self.options.item_weight_mode,
            self.options.common_item_weight,
            self.options.uncommon_item_weight,
            self.options.rare_item_weight,
            self.options.legendary_item_weight,
            self.random,
        )
        self._upgrade_and_item_counts.update(num_items_per_rarity.items())

        # Check that there's enough locations for all the items given in the options. If there isn't enough locations,
        # remove non-progression items (i.e. Brotato items and upgrades) until there's no more extra.
        # We already have an item for each common and legendary loot crate drop, as well as each run won location, so we
        # need a filler item for every wave complete location not covered by a character unlock, shop slot, or upgrade.
        num_wave_complete_locations = len(self.waves_with_checks) * len(self._include_characters)

        # The number of locations available, not including the "Run Won" locations, which always have "Run Won" items.
        num_locations = num_wave_complete_locations + self.options.num_common_crate_drops.value
        num_claimed_locations = (
            (len(self._include_characters) - len(self._starting_characters))  # For each character unlock
            + self.num_shop_slot_items
            + self.num_shop_lock_button_items
            + sum(self._upgrade_and_item_counts.values())
        )
        num_unclaimed_locations = num_locations - num_claimed_locations
        if num_unclaimed_locations < 0:
            # Too many items for the number of locations we have. Randomly remove items, upgrades, and excluded
            # characters to make space for the progression items (characters and shop slots).
            num_items_to_remove = abs(num_unclaimed_locations)
            removable_items: dict[ItemName, int] = self._upgrade_and_item_counts.copy()
            if sum(removable_items.values()) < num_items_to_remove:
                raise OptionError(
                    "Not enough locations for all progression items with given options. Most likely too many characters"
                    "were excluded by omitting them from 'Include Characters'. Add more characters and try again."
                )
            items_to_remove: list[ItemName] = self.random.sample(
                list(removable_items.keys()), num_items_to_remove, counts=list(removable_items.values())
            )
            for item_to_remove in items_to_remove:
                self._upgrade_and_item_counts[item_to_remove] -= 1
        self._num_filler_items = max(num_unclaimed_locations, 0) + self.options.num_legendary_crate_drops.value

    def set_rules(self) -> None:
        self.multiworld.completion_condition[self.player] = create_has_run_wins_rule(
            self.player, self.options.num_victories.value
        )

    def create_regions(self) -> None:
        def create_region(region_name: str) -> Region:
            return Region(region_name, self.player, self.multiworld)

        regions: list[Region] = create_regions(
            create_region,
            self._include_characters,
            self.waves_with_checks,
            self.common_loot_crate_groups,
            self.legendary_loot_crate_groups,
        )

        self.multiworld.regions.extend(regions)

    def create_items(self) -> None:
        item_pool: list[BrotatoItem | Item] = []

        for character in self._include_characters:
            character_item: BrotatoItem = self.create_item(character)
            if character in self._starting_characters:
                self.multiworld.push_precollected(character_item)
            else:
                item_pool.append(character_item)

        # Create an item for each (Brotato) item and upgrade. These counts are determined in generate_early().
        for item_name, item_count in self._upgrade_and_item_counts.items():
            item_pool += [self.create_item(item_name) for _ in range(item_count)]

        item_pool += [self.create_item(ItemName.SHOP_SLOT) for _ in range(self.num_shop_slot_items)]
        item_pool += [self.create_item(ItemName.SHOP_LOCK_BUTTON) for _ in range(self.num_shop_lock_button_items)]
        item_pool += [self.create_filler() for _ in range(self._num_filler_items)]

        self.multiworld.itempool += item_pool

    def pre_fill(self) -> None:
        # Place "Run Won" items at the Run Win event locations
        for character in self._include_characters:
            item: BrotatoItem = self.create_item(ItemName.RUN_COMPLETE)
            run_won_location = RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
            self.multiworld.get_location(run_won_location, self.player).place_locked_item(item)

    def get_filler_item_name(self) -> str:
        return self.random.choice(self._filler_items)

    def fill_slot_data(self) -> dict[str, Any]:
        # Define outside dict for readability
        spawn_normal_loot_crates = (
            self.options.spawn_normal_loot_crates.value == self.options.spawn_normal_loot_crates.option_true
        )
        wave_per_loot_crate_item = get_wave_for_each_item(self._upgrade_and_item_counts)
        return {
            "waves_with_checks": self.waves_with_checks,
            "num_wins_needed": self.options.num_victories.value,
            "gold_reward_mode": self.options.gold_reward_mode.value,
            "xp_reward_mode": self.options.xp_reward_mode.value,
            "enable_enemy_xp": self.options.enable_enemy_xp.value == self.options.enable_enemy_xp.option_true,
            "num_starting_shop_slots": self.options.num_starting_shop_slots.value,
            "num_starting_shop_lock_buttons": (MAX_SHOP_SLOTS - self.num_shop_lock_button_items),
            "spawn_normal_loot_crates": spawn_normal_loot_crates,
            "num_common_crate_locations": self.options.num_common_crate_drops.value,
            "num_common_crate_drops_per_check": self.options.num_common_crate_drops_per_check.value,
            "common_crate_drop_groups": [asdict(g) for g in self.common_loot_crate_groups],
            "num_legendary_crate_locations": self.options.num_legendary_crate_drops.value,
            "num_legendary_crate_drops_per_check": self.options.num_legendary_crate_drops_per_check.value,
            "legendary_crate_drop_groups": [asdict(g) for g in self.legendary_loot_crate_groups],
            "wave_per_game_item": wave_per_loot_crate_item,
            "enable_abyssal_terrors_dlc": self.options.enable_abyssal_terrors_dlc.value,
        }
