from __future__ import annotations

import logging
from typing import Any, Sequence

from BaseClasses import MultiWorld, Tutorial
from worlds.AutoWorld import WebWorld, World

from .Constants import CHARACTERS, DEFAULT_CHARACTERS, MAX_SHOP_SLOTS, NUM_WAVES
from .Items import (
    BrotatoItem,
    ItemName,
    filler_items,
    item_name_groups,
    item_name_to_id,
    item_table,
)
from .Locations import location_name_groups, location_name_to_id
from .Options import BrotatoOptions
from .Regions import create_regions
from .Rules import BrotatoLogic

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


class BrotatoWorld(World):
    """
    Brotato is a top-down arena shooter roguelite where you play a potato wielding up to
    6 weapons at a time to fight off hordes of aliens. Choose from a variety of traits
    and items to create unique builds and survive until help arrives.
    """

    options_dataclass = BrotatoOptions
    options: BrotatoOptions
    game = "Brotato"
    web = BrotatoWeb()
    data_version = 0
    required_client_version = (0, 4, 2)

    item_name_to_id = item_name_to_id
    item_name_groups = item_name_groups

    _filler_items = filler_items
    _starting_characters: list[str]

    location_name_to_id = location_name_to_id
    location_name_groups = location_name_groups

    waves_with_checks: Sequence[int]
    """Which waves will count as locations, derived from player options in generate_early"""

    def __init__(self, world: MultiWorld, player: int):
        super().__init__(world, player)

    def create_item(self, name: str | ItemName) -> BrotatoItem:
        if isinstance(name, ItemName):
            name = name.value
        return item_table[self.item_name_to_id[name]].to_item(self.player)

    def generate_early(self):
        waves_per_drop = self.options.waves_per_drop.value
        # Ignore 0 value, but choosing a different start gives the wrong wave results
        self.waves_with_checks = list(range(0, NUM_WAVES + 1, waves_per_drop))[1:]
        character_option = self.options.starting_characters.value
        if character_option == 0:  # Default
            self._starting_characters = list(DEFAULT_CHARACTERS)
        else:
            num_starting_characters = self.options.num_starting_characters
            self._starting_characters = self.random.sample(CHARACTERS, num_starting_characters)

    def set_rules(self):
        num_required_victories = self.options.num_victories.value
        self.multiworld.completion_condition[self.player] = lambda state: BrotatoLogic._brotato_has_run_wins(
            state, self.player, count=num_required_victories
        )

    def create_regions(self) -> None:
        create_regions(self.multiworld, self.player, self.options, self.waves_with_checks)

    def create_items(self):
        item_names: list[ItemName | str] = []

        for c in self._starting_characters:
            self.multiworld.push_precollected(self.create_item(c))

        item_names += [c for c in item_name_groups["Characters"] if c not in self._starting_characters]

        # Add an item to receive for each crate drop location, as backfill
        num_common_crate_drops = self.options.num_common_crate_drops.value
        for _ in range(num_common_crate_drops):
            # TODO: Can be any item rarity, but need to choose a ratio. Check wiki for rates?
            item_names.append(ItemName.COMMON_ITEM)

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
            item = self.create_item(ItemName.RUN_COMPLETE)
            self.multiworld.get_location(loc, self.player).place_locked_item(item)

    def generate_basic(self):
        pass

    def get_filler_item_name(self):
        return self.random.choice(self._filler_items)

    def fill_slot_data(self) -> dict[str, Any]:
        return {
            "waves_with_checks": self.waves_with_checks,
            "num_wins_needed": self.options.num_victories.value,
            "num_consumables": self.options.num_common_crate_drops.value,
            "num_starting_shop_slots": self.options.num_starting_shop_slots.value,
            "num_legendary_consumables": self.options.num_legendary_crate_drops.value,
        }
