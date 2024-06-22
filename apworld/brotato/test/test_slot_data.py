from . import BrotatoTestBase


class TestBrotatoSlotData(BrotatoTestBase):
    options = {
        # Only set options that are referenced by slot_data
        "num_victories": 10,
        "starting_characters": 0,
        "waves_per_drop": 2,
        "num_common_crate_drops_per_check": 2,
        "num_common_crate_drop_groups": 5,
        "num_legendary_crate_drops_per_check": 1,
        "num_legendary_crate_drop_groups": 2,
        "num_starting_shop_slots": 1,
        # Use custom item weights so we know that there are exactly 50 common items and 20 legendary items in the
        # itempool when we check the item_waves.
        "item_weight_mode": 2,
        "num_common_crate_drops": 50,
        "num_legendary_crate_drops": 20,
        "common_item_weight": 1,
        "uncommon_item_weight": 0,
        "rare_item_weight": 0,
        "legendary_item_weight": 0,
    }

    def test_slot_data_num_wins_needed(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_wins_needed"], 10)

    def test_slot_data_num_starting_shop_slots(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_starting_shop_slots"], 1)

    def test_slot_data_num_common_crate_locations(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_common_crate_locations"], 50)

    def test_slot_data_num_common_crate_drops_per_check(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_common_crate_drops_per_check"], 2)

    def test_slot_data_num_legendary_crate_locations(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_legendary_crate_locations"], 20)

    def test_slot_data_num_legendary_crate_drops_per_check(self):
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["num_legendary_crate_drops_per_check"], 1)

    def test_slot_data_wave_per_game_item(self):
        slot_data = self.world.fill_slot_data()
        # 3 common items per wave for wave 1-10, then 2 items per wave for waves 11-20.
        expected_common_wave_per_item = [
            1,
            1,
            1,
            2,
            2,
            2,
            3,
            3,
            3,
            4,
            4,
            4,
            5,
            5,
            5,
            6,
            6,
            6,
            7,
            7,
            7,
            8,
            8,
            8,
            9,
            9,
            9,
            10,
            10,
            10,
            11,
            11,
            12,
            12,
            13,
            13,
            14,
            14,
            15,
            15,
            16,
            16,
            17,
            17,
            18,
            18,
            19,
            19,
            20,
            20,
        ]
        self.assertEqual(
            slot_data["wave_per_game_item"],
            {
                0: expected_common_wave_per_item,
                1: [],
                2: [],
                # There are 20 legendary crate drop locations, so one wave per location.
                3: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
            },
        )
