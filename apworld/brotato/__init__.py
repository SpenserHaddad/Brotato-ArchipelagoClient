from __future__ import annotations

import logging
from typing import Any, List, Literal, Sequence

from BaseClasses import MultiWorld, Region, Tutorial
from worlds.AutoWorld import WebWorld, World
from worlds.generic.Rules import ItemRule, add_item_rule

from .Constants import (
    CHARACTERS,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    DEFAULT_CHARACTERS,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_SHOP_SLOTS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .Items import (
    BrotatoItem,
    ItemName,
    filler_items,
    item_name_groups,
    item_name_to_id,
    item_table,
)
from .Locations import BrotatoLocation, location_name_groups, location_name_to_id, location_table
from .Options import BrotatoOptions
from .Rules import create_has_character_rule, create_has_run_wins_rule, legendary_loot_crate_item_rule

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
    options: BrotatoOptions  # type: ignore
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
            num_starting_characters = self.options.num_starting_characters.value
            self._starting_characters = self.random.sample(CHARACTERS, num_starting_characters)

    def set_rules(self):
        num_required_victories = self.options.num_victories.value
        self.multiworld.completion_condition[self.player] = create_has_run_wins_rule(
            self.player, num_required_victories
        )

    def create_regions(self) -> None:
        menu_region = Region("Menu", self.player, self.multiworld)
        loot_crate_regions = self._create_loot_crate_regions(menu_region, "normal")
        legendary_crate_regions = self._create_loot_crate_regions(menu_region, "legendary")

        character_regions: list[Region] = []
        for character in CHARACTERS:
            character_region = self._create_character_region(menu_region, character)
            character_regions.append(character_region)

            # # Crates can be gotten with any character...
            # character_region.connect(crate_drop_region, f"Drop crates for {character}")
            # # ...but we need to make sure you don't go to another character's in-game before you have them.
            # crate_drop_region.connect(character_region, f"Exit drop crates for {character}", rule=has_character_rule)
            # character_regions.append(character_region)

        self.multiworld.regions.extend([menu_region, *loot_crate_regions, *legendary_crate_regions, *character_regions])

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

    def _create_character_region(self, parent_region: Region, character: str) -> Region:
        character_region = Region(f"In-Game ({character})", self.player, self.multiworld)
        character_run_won_location = location_table[RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)]
        character_region.locations.append(character_run_won_location.to_location(self.player, parent=character_region))

        character_wave_drop_location_names = [
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

    def _create_loot_crate_regions(
        self: BrotatoWorld, parent_region: Region, crate_type: Literal["normal", "legendary"]
    ) -> List[Region]:
        item_rule: ItemRule | None
        if crate_type == "normal":
            num_items = self.options.num_common_crate_drops.value
            num_groups_option_value = self.options.num_common_crate_drop_groups.value
            location_name_template = CRATE_DROP_LOCATION_TEMPLATE
            region_name_template = CRATE_DROP_GROUP_REGION_TEMPLATE
            item_rule = None
        else:
            num_items = self.options.num_legendary_crate_drops.value
            num_groups_option_value = self.options.num_legendary_crate_drop_groups.value
            location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
            region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
            item_rule = legendary_loot_crate_item_rule

        regions: List[Region] = []

        # If the options specify more crate drop groups than number of required wins, clamp to the number of wins. This
        # makes the math simpler and ensures all items are accessible by go mode. Someone probably wants the option to
        # have items after completing their goal, but we're going to pretend they don't exist until they ask.
        num_groups = min(self.options.num_victories.value, num_groups_option_value)

        num_wins_to_unlock_group = max(self.options.num_victories.value // num_groups, 1)
        items_per_group, extra_items = divmod(num_items, num_groups)
        crate_count = 0
        wins_to_unlock = 0
        for group_idx in range(1, num_groups + 1):
            crate_group_region = Region(region_name_template.format(num=group_idx), self.player, self.multiworld)
            items_in_group = min(items_per_group, num_items - crate_count)
            if extra_items > 0:
                # If the number of crates doesn't evenly divide into the number of groups, add 1 to each group until all
                # the extras are used. This ensures the groups are as even as possible. The extra is the remainder of
                # evenly dividing the number of items over the number of groups, so in the worst case every group but
                # the last will have an extra added to it.
                items_in_group += 1
                extra_items -= 1
            for _ in range(1, items_in_group + 1):
                crate_location_name = location_name_template.format(num=crate_count + 1)
                crate_location: BrotatoLocation = location_table[crate_location_name].to_location(
                    self.player, parent=crate_group_region
                )
                if item_rule is not None:
                    add_item_rule(crate_location, item_rule)

                crate_group_region.locations.append(crate_location)
                crate_count += 1

            crate_group_region_rule = create_has_run_wins_rule(self.player, wins_to_unlock)
            wins_to_unlock = min(wins_to_unlock + num_wins_to_unlock_group, self.options.num_victories.value)
            parent_region.connect(crate_group_region, name=crate_group_region.name, rule=crate_group_region_rule)
            regions.append(crate_group_region)

        return regions
