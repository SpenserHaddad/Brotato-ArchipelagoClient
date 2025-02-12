import logging
from collections import Counter
from dataclasses import asdict
from typing import Any, ClassVar, Dict, List, Literal, Set, Tuple, Union

from BaseClasses import Item, LocationProgressType, MultiWorld, Region, Tutorial
from Options import OptionError, OptionGroup
from worlds.AutoWorld import WebWorld, World

from . import options  # So we don't need to import every option class when defining option groups
from ._loot_crate_groups import BrotatoLootCrateGroup, build_loot_crate_groups
from .constants import (
    ABYSSAL_TERRORS_CHARACTERS,
    BASE_GAME_CHARACTERS,
    CHARACTER_REGION_TEMPLATE,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    DEFAULT_ITEM_WEIGHTS,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_SHOP_SLOTS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
    CharacterGroup,
    ItemRarity,
)
from .items import BrotatoItem, ItemName, filler_items, item_name_groups, item_name_to_id, item_table
from .locations import BrotatoLocation, BrotatoLocationBase, location_name_groups, location_name_to_id, location_table
from .options import (
    BrotatoOptions,
    CommonItemWeight,
    ItemWeights,
    LegendaryItemWeight,
    RareItemWeight,
    StartingCharacters,
    UncommonItemWeight,
)
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

    wave_per_game_item: Dict[int, List[int]]
    """The wave to use to generate each Brotato item received, by rarity. Stored as slot data.

    Brotato items are generated from a pool determined by the rarity (or tier) and the wave the item was found/bought.
    We want to emulate this behavior with the items we create here. When we generate the items to match the common loot
    crate drop locations, we also assign a wave to each item. When the client receives the next item for a certain
    rarity, it will lookup the next entry in the list for the rarity and use that as the wave when generating the
    values.

    We attempt to equally distribute the items over the 20 waves in a normal run, with a bias towards lower numbers.
    """

    common_loot_crate_groups: List[BrotatoLootCrateGroup]
    """Information about each common loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early().
    """

    legendary_loot_crate_groups: List[BrotatoLootCrateGroup]
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

        game_packs: dict[str, tuple[bool, set[str], CharacterGroup]] = {
            BASE_GAME_CHARACTERS.name: (True, self.options.include_base_game_characters.value, BASE_GAME_CHARACTERS),
            ABYSSAL_TERRORS_CHARACTERS.name: (
                self.options.enable_abyssal_terrors_dlc.value == self.options.enable_abyssal_terrors_dlc.option_true,
                self.options.include_abyssal_terrors_characters.value,
                ABYSSAL_TERRORS_CHARACTERS,
            ),
        }

        # Keep include characters in the defined order to make reading/debugging easier. Entries should all be valid.
        self._include_characters = []
        for pack_enabled, include_characters_from_pack, pack_characters in game_packs.values():
            if pack_enabled:
                characters_from_pack = [c for c in pack_characters.characters if c in include_characters_from_pack]
                self._include_characters += characters_from_pack

        starting_character_option = self.options.starting_characters.value
        if starting_character_option == StartingCharacters.option_default_all:  # Defaults from all game packs
            enabled_groups = [gp[2] for gp in game_packs.values() if gp[0]]
            self._starting_characters = self._get_valid_default_characters(enabled_groups)
        elif starting_character_option == StartingCharacters.option_random_all:
            enabled_groups = [gp[2] for gp in game_packs.values() if gp[0]]
            self._starting_characters = self._get_valid_random_characters(enabled_groups)
        elif starting_character_option == StartingCharacters.option_default_base_game:
            self._starting_characters = self._get_valid_default_characters([BASE_GAME_CHARACTERS])
        elif starting_character_option == StartingCharacters.option_random_base_game:
            self._starting_characters = self._get_valid_random_characters([BASE_GAME_CHARACTERS])
        elif starting_character_option == StartingCharacters.option_default_abyssal_terrors:
            if not game_packs[ABYSSAL_TERRORS_CHARACTERS.name][0]:
                raise OptionError("Abyssal Terrors DLC is not enabled in options.")
            self._starting_characters = self._get_valid_default_characters([ABYSSAL_TERRORS_CHARACTERS])
        elif starting_character_option == StartingCharacters.option_random_abyssal_terrors:
            if not game_packs[ABYSSAL_TERRORS_CHARACTERS.name][0]:
                raise OptionError("Abyssal Terrors DLC is not enabled in options.")
            self._starting_characters = self._get_valid_random_characters([ABYSSAL_TERRORS_CHARACTERS])
        else:
            raise RuntimeError("Unsupported option!")

        # Clamp the number of wins needed to goal to the number of included characters, so the game isn't unwinnable.
        # Note that we need to actually change the option value, not just clamp it, otherwise other parts of the world
        # will miss it. This has caused bugs in the past.
        self.options.num_victories.value = min(self.options.num_victories.value, len(self._include_characters))

        # Initialize the number of upgrades and items to include, then adjust as necessary below.
        self._upgrade_and_item_counts = {
            ItemName.COMMON_UPGRADE: self.options.num_common_upgrades.value,
            ItemName.UNCOMMON_UPGRADE: self.options.num_uncommon_upgrades.value,
            ItemName.RARE_UPGRADE: self.options.num_rare_upgrades.value,
            ItemName.LEGENDARY_UPGRADE: self.options.num_legendary_upgrades.value,
        }

        num_items_per_rarity: Counter[ItemName] = self._create_common_loot_crate_items()
        self._upgrade_and_item_counts.update(num_items_per_rarity.items())

        # Check that there's enough locations for all the items given in the options. If there isn't enough locations,
        # remove non-progression items (i.e. Brotato items and upgrades) until there's no more extra.
        # We already have an item for each common and legendary loot crate drop, as well as each run won location, so we
        # need a filler item for every wave complete location not covered by a character unlock, shop slot, or upgrade.
        num_wave_complete_locations = len(self.waves_with_checks) * len(self._include_characters)
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
            removable_items: Dict[ItemName, int] = self._upgrade_and_item_counts.copy()
            if sum(removable_items.values()) < num_items_to_remove:
                raise OptionError(
                    "Not enough locations for all progression items with given options. Most likely too many characters"
                    "were excluded by omitting them from 'Include Characters'. Add more characters and try again."
                )
            items_to_remove: List[ItemName] = self.random.sample(
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

    def fill_slot_data(self) -> Dict[str, Any]:
        # Define outside dict for readability
        spawn_normal_loot_crates = (
            self.options.spawn_normal_loot_crates.value == self.options.spawn_normal_loot_crates.option_true
        )
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
            "wave_per_game_item": self.wave_per_game_item,
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
            progress_type = LocationProgressType.EXCLUDED

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

    def _create_common_loot_crate_items(self) -> Counter[ItemName]:
        """Create a list of items corresponding to the common loot crate locations.

        This is intended ot be called by `create_items`, but it's split out because of its side effect (see below), and
        it's sort of involved.

        Creates a Brotato Common/Uncommon/Rare/Legendary item for each loot crate location, using the weights defined
        in the use options to randomly determine how many of each tier to create.

        This also has a side effect: it instantiates the `wave_per_game_item` field which is used to populate a slot
        data entry with the same name. This defines the wave to use when determining what item to create client-side. We
        do this here since we have the information readily available.
        """
        weights: Tuple[int, int, int, int]
        if self.options.item_weight_mode.value == ItemWeights.option_default:
            weights = DEFAULT_ITEM_WEIGHTS
        elif self.options.item_weight_mode.value == ItemWeights.option_chaos:
            # Ask each weight class for their bounds separately in case we ever make them different.
            weights = tuple(
                self.random.randint(weight.range_start, weight.range_end)
                for weight in [CommonItemWeight, UncommonItemWeight, RareItemWeight, LegendaryItemWeight]
            )  # type: ignore
        elif self.options.item_weight_mode.value == ItemWeights.option_custom:
            weights = (
                self.options.common_item_weight.value,
                self.options.uncommon_item_weight.value,
                self.options.rare_item_weight.value,
                self.options.legendary_item_weight.value,
            )
        else:
            raise ValueError(f"Unsupported item_weight_mode {self.options.item_weight_mode.value}.")

        item_names_to_rarity = {
            ItemName.COMMON_ITEM: ItemRarity.COMMON,
            ItemName.UNCOMMON_ITEM: ItemRarity.UNCOMMON,
            ItemName.RARE_ITEM: ItemRarity.RARE,
            ItemName.LEGENDARY_ITEM: ItemRarity.LEGENDARY,
        }
        items: List[ItemName] = self.random.choices(
            list(item_names_to_rarity.keys()),
            weights=weights,
            k=self.options.num_common_crate_drops.value,
        )

        # Create the wave each item should be generated with. In each rarity, increment the wave by one for each item,
        # looping over at 20 (the max number of waves in a run), then sort the result so we have an even distribution of
        # waves in increasing order.
        item_counts = Counter(items)

        # Include the legendary items added from legendary crate drop checks as well
        item_counts[ItemName.LEGENDARY_ITEM] = (
            item_counts.get(ItemName.LEGENDARY_ITEM, 0) + self.options.num_legendary_crate_drops.value
        )

        def generate_waves_per_item(num_items: int) -> List[int]:
            # Evenly distribute the items over 20 waves, then sort so items received are generated with steadily
            # increasing waves (aka they got steadily stronger).
            return sorted((i % 20) + 1 for i in range(num_items))

        # Use a default of 0 in case no items of a tier were created for whatever reason.
        self.wave_per_game_item: Dict[int, List[int]] = {
            rarity.value: generate_waves_per_item(item_counts.get(name, 0))
            for name, rarity in item_names_to_rarity.items()
        }

        return item_counts

    def _get_valid_default_characters(self, character_groups: list[CharacterGroup]) -> list[str]:
        return [c for cg in character_groups for c in cg.default_characters if c in self._include_characters]

    def _get_valid_random_characters(self, character_groups: list[CharacterGroup]) -> list[str]:
        valid_characters = [c for cg in character_groups for c in cg.characters if c in self._include_characters]
        # In case the number of included characters is less than the requested amount
        num_characters_to_choose = min(len(valid_characters), self.options.num_starting_characters.value)
        return self.random.sample(valid_characters, num_characters_to_choose)
