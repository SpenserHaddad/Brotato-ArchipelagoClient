import logging
from dataclasses import asdict
from itertools import cycle
from math import ceil
from typing import Any, ClassVar, Dict, List, Literal, Sequence, Set, Tuple, Union

from BaseClasses import MultiWorld, Region, Tutorial
from worlds.AutoWorld import WebWorld, World
from worlds.generic.Rules import add_item_rule

from ._loot_crate_groups import BrotatoLootCrateGroup, build_loot_crate_groups
from .constants import (
    CHARACTERS,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    DEFAULT_CHARACTERS,
    ITEM_RARITY_WEIGHTS,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_SHOP_SLOTS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
    ItemRarity,
)
from .items import (
    BrotatoItem,
    ItemName,
    filler_items,
    item_name_groups,
    item_name_to_id,
    item_table,
)
from .locations import BrotatoLocation, BrotatoLocationBase, location_name_groups, location_name_to_id, location_table
from .options import BrotatoOptions
from .rules import create_has_character_rule, create_has_run_wins_rule, legendary_loot_crate_item_rule

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
    theme: str = "dirt"


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
    required_client_version: Tuple[int, int, int] = (0, 4, 2)

    item_name_to_id: ClassVar[Dict[str, int]] = item_name_to_id
    item_name_groups: ClassVar[Dict[str, Set[str]]] = item_name_groups

    _filler_items: List[str] = filler_items
    _starting_characters: List[str]

    location_name_to_id: ClassVar[Dict[str, int]] = location_name_to_id
    location_name_groups: ClassVar[Dict[str, Set[str]]] = location_name_groups

    waves_with_checks: Sequence[int]
    """Which waves will count as locations.

    Calculated from player options in generate_early.
    """

    common_loot_crate_groups: Sequence[BrotatoLootCrateGroup]
    """Information about each common loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early.
    """

    legendary_loot_crate_groups: Sequence[BrotatoLootCrateGroup]
    """Information about each legendary loot crate group, i.e. how many crates it has and how many wins it needs.

    Calculated from player options in generate_early.
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

        character_option = self.options.starting_characters.value
        if character_option == 0:  # Default
            self._starting_characters = list(DEFAULT_CHARACTERS)
        else:
            num_starting_characters = self.options.num_starting_characters.value
            self._starting_characters = self.random.sample(CHARACTERS, num_starting_characters)

    def set_rules(self) -> None:
        num_required_victories = self.options.num_victories.value
        self.multiworld.completion_condition[self.player] = create_has_run_wins_rule(
            self.player, num_required_victories
        )

    def create_regions(self) -> None:
        menu_region = Region("Menu", self.player, self.multiworld)
        loot_crate_regions = self._create_regions_for_loot_crate_groups(menu_region, "normal")
        legendary_crate_regions = self._create_regions_for_loot_crate_groups(menu_region, "legendary")

        character_regions: List[Region] = []
        for character in CHARACTERS:
            character_region = self._create_character_region(menu_region, character)
            character_regions.append(character_region)

            # # Crates can be gotten with any character...
            # character_region.connect(crate_drop_region, f"Drop crates for {character}")
            # # ...but we need to make sure you don't go to another character's in-game before you have them.
            # crate_drop_region.connect(character_region, f"Exit drop crates for {character}", rule=has_character_rule)
            # character_regions.append(character_region)

        self.multiworld.regions.extend([menu_region, *loot_crate_regions, *legendary_crate_regions, *character_regions])

    def create_items(self) -> None:
        item_names: List[Union[ItemName, str]] = []

        for c in self._starting_characters:
            self.multiworld.push_precollected(self.create_item(c))

        item_names += [c for c in item_name_groups["Characters"] if c not in self._starting_characters]

        # Add an item to receive for each common crate drop location. Try to match the distribution of
        # common/uncommon/rare/legendary items as we can infer from the game itself.
        num_common_crate_drops = self.options.num_common_crate_drops.value
        # Use ceiling to bias towards having more items than less. We'll handle overflow next.
        items_per_rarity: Dict[ItemRarity, int] = {
            rarity: ceil(rarity_pct * num_common_crate_drops) for rarity, rarity_pct in ITEM_RARITY_WEIGHTS.items()
        }

        item_rarity_cycle = cycle(items_per_rarity.keys())
        while sum(items_per_rarity.values()) > num_common_crate_drops:
            # Remove extra items from the distribution, going from Common -> Legendary, so we keep the ratio as close to
            # the desired as possible while biasing towards more rarer items (because that's more fun).
            rarity_to_decrement_next = next(item_rarity_cycle)
            current_count = items_per_rarity[rarity_to_decrement_next]
            items_per_rarity[rarity_to_decrement_next] = max(current_count - 1, 0)

        for rarity, items_to_make in items_per_rarity.items():
            if rarity == ItemRarity.COMMON:
                item_name = ItemName.COMMON_ITEM
            elif rarity == ItemRarity.UNCOMMON:
                item_name = ItemName.UNCOMMON_ITEM
            elif rarity == ItemRarity.RARE:
                item_name = ItemName.RARE_ITEM
            elif rarity == ItemRarity.LEGENDARY:
                item_name = ItemName.LEGENDARY_ITEM
            else:
                raise ValueError(f"Unknown item rarity {rarity}.")

            for _ in range(items_to_make):
                item_names.append(item_name)

        num_legendary_crate_drops = self.options.num_legendary_crate_drops.value
        for _ in range(num_legendary_crate_drops):
            item_names.append(ItemName.LEGENDARY_ITEM)

        num_common_upgrades = self.options.num_common_upgrades.value
        item_names += [ItemName.COMMON_UPGRADE] * num_common_upgrades

        num_uncommon_upgrades = self.options.num_uncommon_upgrades.value
        item_names += [ItemName.UNCOMMON_UPGRADE] * num_uncommon_upgrades

        num_rare_upgrades = self.options.num_rare_upgrades.value
        item_names += [ItemName.RARE_UPGRADE] * num_rare_upgrades

        num_legendary_upgrades = self.options.num_legendary_upgrades.value
        item_names += [ItemName.LEGENDARY_UPGRADE] * num_legendary_upgrades

        num_starting_shop_slots = self.options.num_starting_shop_slots.value
        num_shop_slot_items = max(MAX_SHOP_SLOTS - num_starting_shop_slots, 0)
        item_names += [ItemName.SHOP_SLOT] * num_shop_slot_items

        for _ in range(self.options.num_shop_items):
            pass

        itempool = [self.create_item(item_name) for item_name in item_names]

        total_locations = (
            num_common_crate_drops + num_legendary_crate_drops + (len(self.waves_with_checks) * len(CHARACTERS))
        )
        num_filler_items = total_locations - len(itempool)
        itempool += [self.create_filler() for _ in range(num_filler_items)]

        self.multiworld.itempool += itempool

        # Place "Run Won" items at the Run Win event locations
        for loc in self.location_name_groups["Run Win Specific Character"]:
            item: BrotatoItem = self.create_item(ItemName.RUN_COMPLETE)
            self.multiworld.get_location(loc, self.player).place_locked_item(item)

    def generate_basic(self) -> None:
        pass

    def get_filler_item_name(self) -> str:
        return self.random.choice(self._filler_items)

    def fill_slot_data(self) -> Dict[str, Any]:
        return {
            "waves_with_checks": self.waves_with_checks,
            "num_wins_needed": self.options.num_victories.value,
            "num_starting_shop_slots": self.options.num_starting_shop_slots.value,
            "num_common_crate_locations": self.options.num_common_crate_drops.value,
            "num_common_crate_drops_per_check": self.options.num_common_crate_drops_per_check.value,
            "common_crate_drop_groups": [asdict(g) for g in self.common_loot_crate_groups],
            "num_legendary_crate_locations": self.options.num_legendary_crate_drops.value,
            "num_legendary_crate_drops_per_check": self.options.num_legendary_crate_drops_per_check.value,
            "legendary_crate_drop_groups": [asdict(g) for g in self.legendary_loot_crate_groups],
        }

    def _create_character_region(self, parent_region: Region, character: str) -> Region:
        character_region: Region = Region(f"In-Game ({character})", self.player, self.multiworld)
        character_run_won_location: BrotatoLocationBase = location_table[
            RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
        ]
        character_region.locations.append(character_run_won_location.to_location(self.player, parent=character_region))

        character_wave_drop_location_names: List[str] = [
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=character) for w in self.waves_with_checks
        ]
        character_region.locations.extend(
            location_table[loc].to_location(self.player, parent=character_region)
            for loc in character_wave_drop_location_names
        )

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
            item_rule = None
        else:
            loot_crate_groups = self.legendary_loot_crate_groups
            location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
            region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
            item_rule = legendary_loot_crate_item_rule

        regions: List[Region] = []
        crate_count = 1

        for group_idx, group in enumerate(loot_crate_groups, start=1):
            group_region = Region(region_name_template.format(num=group_idx), self.player, self.multiworld)
            for _ in range(1, group.num_crates + 1):
                crate_location_name = location_name_template.format(num=crate_count)
                crate_location: BrotatoLocation = location_table[crate_location_name].to_location(
                    self.player, parent=group_region
                )
                if item_rule is not None:
                    add_item_rule(crate_location, item_rule)

                group_region.locations.append(crate_location)
                crate_count += 1

            group_region_rule = create_has_run_wins_rule(self.player, group.wins_to_unlock)
            parent_region.connect(group_region, name=group_region.name, rule=group_region_rule)
            regions.append(group_region)

        return regions
