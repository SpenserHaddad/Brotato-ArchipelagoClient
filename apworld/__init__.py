import logging
from typing import Any, Sequence

from BaseClasses import MultiWorld, Tutorial
from worlds.AutoWorld import WebWorld, World

from . import Options
from .Constants import DEFAULT_CHARACTERS, CHARACTERS, NUM_WAVES, UNLOCKABLE_CHARACTERS
from .Items import BrotatoItem, filler_items, ItemName, item_name_groups, item_name_to_id, item_table
from .Locations import location_name_to_id, location_name_groups
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

    option_definitions = Options.options
    game = "Brotato"
    web = BrotatoWeb()
    data_version = 0
    required_client_version = (0, 4, 2)

    item_name_to_id = item_name_to_id
    item_name_groups = item_name_groups

    _filler_items = filler_items

    location_name_to_id = location_name_to_id
    location_name_groups = location_name_groups

    waves_with_checks: Sequence[int]
    """Which waves will count as locations, derived from player options in generate_early"""

    def __init__(self, world: MultiWorld, player: int):
        super().__init__(world, player)

    def _get_option_value(self, option: str) -> Any:
        return getattr(self.multiworld, option)[self.player]

    def create_item(self, name: str | ItemName) -> BrotatoItem:
        if isinstance(name, ItemName):
            name = name.value
        return item_table[self.item_name_to_id[name]].to_item(self.player)

    def generate_early(self):
        waves_per_drop = self._get_option_value("waves_per_drop")
        # Ignore 0 value, but choosing a different start gives the wrong wave results
        self.waves_with_checks = list(range(0, NUM_WAVES + 1, waves_per_drop))[1:]

    def set_rules(self):
        num_required_victories = self._get_option_value("num_victories")
        self.multiworld.completion_condition[self.player] = lambda state: BrotatoLogic._brotato_has_run_wins(
            state, self.player, count=num_required_victories
        )

    def create_regions(self) -> None:
        create_regions(self.multiworld, self.player, self.waves_with_checks)

    def create_items(self):
        item_names: list[ItemName | str] = []

        for dc in DEFAULT_CHARACTERS:
            self.multiworld.push_precollected(self.create_item(dc))

        item_names += [c for c in item_name_groups["Characters"] if c in UNLOCKABLE_CHARACTERS]

        # Add an item to receive for each crate drop location, as backfill
        num_common_crate_drops = self._get_option_value("num_common_crate_drops")
        for _ in range(num_common_crate_drops):
            # TODO: Can be any item rarity, but need to choose a ratio. Check wiki for rates?
            item_names.append(ItemName.COMMON_ITEM)

        num_legendary_crate_drops = self._get_option_value("num_legendary_crate_drops")
        for _ in range(num_legendary_crate_drops):
            item_names.append(ItemName.LEGENDARY_ITEM)

        num_shop_items = self._get_option_value("num_shop_items")
        for _ in range(num_shop_items):
            pass

        itempool = [self.create_item(item_name) for item_name in item_names]

        total_locations = (
            num_common_crate_drops
            + num_legendary_crate_drops
            + (len(self.waves_with_checks) * len(CHARACTERS))
            # + self.multiworld.num_shop_items[self.player] # Not implemented yet
        )
        num_filler_items = total_locations - len(itempool)
        itempool += [self.create_filler() for _ in range(num_filler_items)]

        self.multiworld.itempool += itempool

        # Place "Run Complete" items at the Run Win event locations
        for loc in self.location_name_groups["Run Win Specific Character"]:
            item = self.create_item(ItemName.RUN_COMPLETE)
            self.multiworld.get_location(loc, self.player).place_locked_item(item)

    def generate_basic(self):
        pass

    def get_filler_item_name(self):
        return self.multiworld.random.choice(self._filler_items)

    def fill_slot_data(self) -> dict[str, Any]:
        return {
            "waves_with_checks": self.waves_with_checks,
            "num_wins_needed": int(self._get_option_value("num_victories")),
            "num_consumables": int(self._get_option_value("num_common_crate_drops")),
            "num_legendary_consumables": int(self._get_option_value("num_legendary_crate_drops")),
        }
