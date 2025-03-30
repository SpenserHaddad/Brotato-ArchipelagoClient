import logging
from dataclasses import asdict
from typing import Any, ClassVar, Dict, List, Literal, Set, Tuple, Union

from BaseClasses import Item, LocationProgressType, MultiWorld, Region, Tutorial
from Options import OptionGroup
from worlds.AutoWorld import WebWorld, World

from . import options  # So we don't need to import every option class when defining option groups
from ._loot_crate_groups import BrotatoLootCrateGroup, build_loot_crate_groups
from .characters import get_available_and_starting_characters
from .constants import (
    CHARACTER_REGION_TEMPLATE,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_SHOP_SLOTS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
    CharacterGroup,
    ItemRarity,
)
from .item_weights import create_items_from_weights
from .items import BrotatoItem, ItemName, filler_items, item_name_groups, item_name_to_id, item_table
from .locations import BrotatoLocation, BrotatoLocationBase, location_name_groups, location_name_to_id, location_table
from .options import BrotatoOptions
from .rules import create_has_character_rule, create_has_run_wins_rule

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
            "Shop Slots",
            [options.StartingShopSlots, options.StartingShopLockButtonsMode, options.NumberStartingShopLockButtons],
        ),
        OptionGroup(
            "Item Weights",
            [
                options.CommonItemWeight,
                options.UncommonItemWeight,
                options.RareItemWeight,
                options.LegendaryItemWeight,
                options.CommonUpgradeWeight,
                options.UncommonUpgradeWeight,
                options.RareUpgradeWeight,
                options.LegendaryUpgradeWeight,
                options.GoldWeight,
                options.XpWeight,
            ],
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
    required_client_version: Tuple[int, int, int] = (0, 5, 0)

    item_name_to_id: ClassVar[Dict[str, int]] = item_name_to_id
    item_name_groups: ClassVar[Dict[str, Set[str]]] = item_name_groups

    _filler_items: List[str] = filler_items
    _starting_characters: List[str]
    _include_characters: List[str]
    """The characters whose locations (wave/run complete) may have progression and useful items.

    This is derived from options.include_characters.

    This is a distinct list from the options value because:

    * We want to sanitize the list to make sure typos or other errors don't cause bugs down the road.
    * We want to keep things in character definition order for readability by using a list instead of a set.
    """

    location_name_to_id: ClassVar[Dict[str, int]] = location_name_to_id
    location_name_groups: ClassVar[Dict[str, Set[str]]] = location_name_groups

    num_shop_slot_items: int
    num_shop_lock_button_items: int

    waves_with_checks: List[int]
    """Which waves will count as locations.

    Calculated from player options in generate_early.
    """

    common_loot_crate_groups: List[BrotatoLootCrateGroup]
    """Information about each common loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early().
    """

    legendary_loot_crate_groups: List[BrotatoLootCrateGroup]
    """Information about each legendary loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early().
    """

    nonessential_item_counts: dict[ItemName, int]
    """The names and counts of the items in the pool that aren't characters, shop slots, or shop locks.

    This includes the (Brotato) items, upgrades, gold and XP drops, which are populated from the respective weight
    options to fill all locations not taken by the aforementioned items.

    These are "nonessential" because they aren't strictly necessary for completion, like character items, or incredibly
    useful with a strict cap, like the shop slots and locks. There's probably a better name for this, but I can't think
    of it at the time of writing.

    These are determined in generate_early() instead of create_items() so we can use the amount of them to determine
    combat logic.
    """

    def __init__(self, world: MultiWorld, player: int) -> None:
        super().__init__(world, player)

    def create_item(self, name: Union[str, ItemName]) -> BrotatoItem:
        if isinstance(name, ItemName):
            name = name.value
        return item_table[self.item_name_to_id[name]].to_item(self.player)

    def generate_early(self) -> None:
        waves_per_drop = self.options.waves_per_drop.value
        # Ignore 0 value, but choosing a different start gives the wrong wave results
        self.waves_with_checks = list(range(0, NUM_WAVES + 1, waves_per_drop))[1:]

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

        # Check that there's enough locations for all the items given in the options. If there isn't enough locations,
        # remove non-progression items (i.e. Brotato items and upgrades) until there's no more extra.
        # We already have an item for each common and legendary loot crate drop, as well as each run won location, so we
        # need a filler item for every wave complete location not covered by a character unlock, shop slot, or upgrade.
        self.num_shop_slot_items = max(MAX_SHOP_SLOTS - self.options.num_starting_shop_slots.value, 0)
        if self.options.shop_lock_buttons_mode.value == self.options.shop_lock_buttons_mode.option_all:
            # Start with all lock buttons enabled, so no items
            self.num_shop_lock_button_items = 0
        elif self.options.shop_lock_buttons_mode.value == self.options.shop_lock_buttons_mode.option_none:
            self.num_shop_lock_button_items = MAX_SHOP_SLOTS
        elif self.options.shop_lock_buttons_mode.value == self.options.shop_lock_buttons_mode.option_match_shop_slots:
            self.num_shop_lock_button_items = self.num_shop_slot_items
        else:
            # Custom option, use other option for value
            self.num_shop_lock_button_items = max(MAX_SHOP_SLOTS - self.options.num_starting_lock_buttons.value, 0)

        # The number of locations available, not including the "Run Won" locations, which always have "Run Won" items.
        num_locations = sum(
            [
                len(self._include_characters),  # Run Won Locations
                len(self._include_characters) * len(self.waves_with_checks),  # Wave Complete Locations
                self.options.num_common_crate_drops.value,
                self.options.num_legendary_crate_drops.value,
            ]
        )

        num_essential_items = sum(
            [
                len(self._include_characters),  # Run Won Items
                len(self._include_characters) - len(self._starting_characters),  # The character items
                self.num_shop_slot_items,
                self.num_shop_lock_button_items,
            ]
        )

        num_filler_items = max(num_locations - num_essential_items, 0)
        self.nonessential_item_counts = create_items_from_weights(
            num_filler_items,
            self.random,
            self.options.common_item_weight,
            self.options.uncommon_item_weight,
            self.options.rare_item_weight,
            self.options.legendary_item_weight,
            self.options.common_upgrade_weight,
            self.options.uncommon_upgrade_weight,
            self.options.rare_upgrade_weight,
            self.options.legendary_upgrade_weight,
            self.options.gold_weight,
            self.options.xp_weight,
        )

    def set_rules(self) -> None:
        self.multiworld.completion_condition[self.player] = create_has_run_wins_rule(
            self.player, self.options.num_victories.value
        )

    def create_regions(self) -> None:
        menu_region = Region("Menu", self.player, self.multiworld)
        loot_crate_regions = self._create_regions_for_loot_crate_groups(menu_region, "normal")
        legendary_crate_regions = self._create_regions_for_loot_crate_groups(menu_region, "legendary")

        character_regions: List[Region] = []
        for character in self._include_characters:
            character_region = self._create_character_region(menu_region, character)
            character_regions.append(character_region)

        self.multiworld.regions.extend(
            [
                menu_region,
                *loot_crate_regions,
                *legendary_crate_regions,
                *character_regions,
            ]
        )

    def create_items(self) -> None:
        item_pool: List[BrotatoItem | Item] = []

        for character in self._include_characters:
            character_item: BrotatoItem = self.create_item(character)
            if character in self._starting_characters:
                self.multiworld.push_precollected(character_item)
            else:
                item_pool.append(character_item)

        # Create an item for each nonessential item. These are determined in generate_early().
        for item_name, item_count in self.nonessential_item_counts.items():
            item_pool += [self.create_item(item_name) for _ in range(item_count)]

        item_pool += [self.create_item(ItemName.SHOP_SLOT) for _ in range(self.num_shop_slot_items)]
        item_pool += [self.create_item(ItemName.SHOP_LOCK_BUTTON) for _ in range(self.num_shop_lock_button_items)]

        self.multiworld.itempool += item_pool

    def pre_fill(self) -> None:
        # Place "Run Won" items at the Run Win event locations
        for character in self._include_characters:
            item: BrotatoItem = self.create_item(ItemName.RUN_COMPLETE)
            run_won_location = RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
            self.multiworld.get_location(run_won_location, self.player).place_locked_item(item)

    def get_filler_item_name(self) -> str:
        return self.random.choice(self._filler_items)

    def fill_slot_data(self) -> Dict[str, Any]:
        # Define outside dict for readability
        spawn_normal_loot_crates = (
            self.options.spawn_normal_loot_crates.value == self.options.spawn_normal_loot_crates.option_true
        )
        wave_per_game_item = self._get_wave_per_game_item(self.nonessential_item_counts)
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
            "wave_per_game_item": wave_per_game_item,
            "enable_abyssal_terrors_dlc": self.options.enable_abyssal_terrors_dlc.value,
        }

    def _create_character_region(self, parent_region: Region, character: str) -> Region:
        character_region: Region = Region(
            CHARACTER_REGION_TEMPLATE.format(char=character), self.player, self.multiworld
        )
        character_run_won_location: BrotatoLocationBase = location_table[
            RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
        ]
        character_region.locations.append(character_run_won_location.to_location(self.player, parent=character_region))

        for wave in self.waves_with_checks:
            wave_complete_location_name = WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=wave, char=character)
            wave_complete_location = location_table[wave_complete_location_name].to_location(
                self.player, parent=character_region
            )
            character_region.locations.append(wave_complete_location)

        has_character_rule = create_has_character_rule(self.player, character)
        parent_region.connect(
            character_region,
            f"Start Game ({character})",
            rule=has_character_rule,
        )
        return character_region

    def _create_regions_for_loot_crate_groups(
        self, parent_region: Region, crate_type: Literal["normal", "legendary"]
    ) -> List[Region]:
        if crate_type == "normal":
            loot_crate_groups = self.common_loot_crate_groups
            location_name_template = CRATE_DROP_LOCATION_TEMPLATE
            region_name_template = CRATE_DROP_GROUP_REGION_TEMPLATE
            progress_type = LocationProgressType.DEFAULT
        else:
            loot_crate_groups = self.legendary_loot_crate_groups
            location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
            region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
            progress_type = LocationProgressType.DEFAULT

        regions: List[Region] = []
        crate_count = 1

        for group_idx, group in enumerate(loot_crate_groups, start=1):
            group_region = Region(region_name_template.format(num=group_idx), self.player, self.multiworld)
            for _ in range(1, group.num_crates + 1):
                crate_location_name = location_name_template.format(num=crate_count)
                crate_location: BrotatoLocation = location_table[crate_location_name].to_location(
                    self.player, parent=group_region
                )
                crate_location.progress_type = progress_type

                group_region.locations.append(crate_location)
                crate_count += 1

            group_region_rule = create_has_run_wins_rule(self.player, group.wins_to_unlock)
            parent_region.connect(group_region, name=group_region.name, rule=group_region_rule)
            regions.append(group_region)

        return regions

    def _get_valid_default_characters(self, character_groups: list[CharacterGroup]) -> list[str]:
        return [c for cg in character_groups for c in cg.default_characters if c in self._include_characters]

    def _get_valid_random_characters(self, character_groups: list[CharacterGroup]) -> list[str]:
        valid_characters = [c for cg in character_groups for c in cg.characters if c in self._include_characters]
        # In case the number of included characters is less than the requested amount
        num_characters_to_choose = min(len(valid_characters), self.options.num_starting_characters.value)
        return self.random.sample(valid_characters, num_characters_to_choose)

    def _get_wave_per_game_item(self, item_counts: dict[ItemName, int]) -> dict[int, list[int]]:
        """Determine the wave to use to generate each Brotato item received, by rarity.

        Intended to be stored as slot data, which is why we use the (integer) enum values instead of the enums
        themselves.

        Brotato items are generated from a pool determined by the rarity (or tier) and the wave the item was
        found/bought. We want to emulate this behavior with the items we create here. When we generate the items to
        match the common loot crate drop locations, we also assign a wave to each item. When the client receives the
        next item for a certain rarity, it will lookup the next entry in the list for the rarity and use that as the
        wave when generating the values.

        We attempt to equally distribute the items over the 20 waves in a normal run, with a bias towards lower numbers,
        since it's already too easy to get overpowered in this.
        """

        item_names_to_rarity = {
            ItemName.COMMON_ITEM: ItemRarity.COMMON,
            ItemName.UNCOMMON_ITEM: ItemRarity.UNCOMMON,
            ItemName.RARE_ITEM: ItemRarity.RARE,
            ItemName.LEGENDARY_ITEM: ItemRarity.LEGENDARY,
        }

        def generate_waves_per_item(num_items: int) -> list[int]:
            # Evenly distribute the items over 20 waves, then sort so items received are generated with steadily
            # increasing waves (aka they got steadily stronger).
            return sorted((i % NUM_WAVES) + 1 for i in range(num_items))

        wave_per_item: dict[int, list[int]] = {}
        for item_name, item_rarity in item_names_to_rarity.items():
            wave_per_item[item_rarity.value] = generate_waves_per_item(item_counts[item_name])
        return wave_per_item
