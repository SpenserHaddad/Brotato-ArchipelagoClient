from ..options import StartingShopLockButtonsMode
from ..waves import get_wave_for_each_item
from . import BrotatoTestBase
from .data_sets.shop_slots import SHOP_SLOT_TEST_DATA_SETS


class TestBrotatoSlotData(BrotatoTestBase):
    run_default_tests = False  # type:ignore

    options = {
        # Only set options that are referenced by slot_data
        "num_victories": 10,
        # Include 10 characters so we know exactly what the "characters" field will have.
        "num_characters": 10,
        "include_base_game_characters": [
            "Well Rounded",
            "Brawler",
            "Crazy",
            "Ranger",
            "Mage",
            "Chunky",
            "Old",
            "Lucky",
            "Mutant",
            "Generalist",
        ],
        "include_abyssal_terrors_characters": [],
        "starting_characters": 1,
        "waves_per_drop": 2,
        "num_common_crate_drops_per_check": 2,
        "num_common_crate_drop_groups": 5,
        "num_legendary_crate_drops_per_check": 1,
        "num_legendary_crate_drop_groups": 2,
        "num_starting_shop_slots": 1,
        "shop_lock_buttons_mode": StartingShopLockButtonsMode.option_custom,
        "num_starting_lock_buttons": 2,
        "num_common_crate_drops": 20,
        "num_legendary_crate_drops": 0,
        # Set the weights so only common items are made, to properly test item wave entry
        "common_item_weight": 1,
        "uncommon_item_weight": 0,
        "rare_item_weight": 0,
        "legendary_item_weight": 0,
        "common_upgrade_weight": 0,
        "uncommon_upgrade_weight": 0,
        "rare_upgrade_weight": 0,
        "legendary_upgrade_weight": 0,
        "gold_weight": 0,
        "xp_weight": 0,
    }

    def test_slot_data_num_wins_needed(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_wins_needed"], 10)

    def test_slot_data_num_starting_shop_slots(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_starting_shop_slots"], 1)

    def test_slot_data_starting_shop_lock_buttons(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                slot_data = self.world.fill_slot_data()
                self.assertEqual(
                    slot_data["num_starting_shop_lock_buttons"], test_case.expected_num_starting_lock_buttons
                )

    def test_slot_data_num_common_crate_locations(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_common_crate_locations"], 20)

    def test_slot_data_num_common_crate_drops_per_check(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_common_crate_drops_per_check"], 2)

    def test_slot_data_num_legendary_crate_locations(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_legendary_crate_locations"], 0)

    def test_slot_data_num_legendary_crate_drops_per_check(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_legendary_crate_drops_per_check"], 1)

    def test_slot_data_wave_per_game_item(self):
        slot_data = self.world.fill_slot_data()
        # Testing get_wave_for_each_item is done elsewhere, we just want to see that the slot data matches.
        expected_wave_per_item = get_wave_for_each_item(self.world.nonessential_item_counts)
        self.assertEqual(slot_data["wave_per_game_item"], expected_wave_per_item)

    def test_slot_data_characters(self):
        slot_data = self.world.fill_slot_data()
        expected_characters: list[str] = [
            "Well Rounded",
            "Brawler",
            "Crazy",
            "Ranger",
            "Mage",
            "Chunky",
            "Old",
            "Lucky",
            "Mutant",
            "Generalist",
        ]
        self.assertCountEqual(slot_data["characters"], expected_characters)
