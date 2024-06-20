from collections import Counter
from typing import Dict

from worlds.brotato.items import BrotatoItem

from ..items import ItemName
from . import BrotatoTestBase


class TestBrotatoItems(BrotatoTestBase):
    auto_construct = False

    def test_create_items_loot_crate_drops_correct_distribution(self):
        num_checks_and_expected_items: Dict[int, Dict[ItemName, int]] = {
            1: {ItemName.COMMON_ITEM: 0, ItemName.UNCOMMON_ITEM: 0, ItemName.RARE_ITEM: 0, ItemName.LEGENDARY_ITEM: 1},
            5: {ItemName.COMMON_ITEM: 2, ItemName.UNCOMMON_ITEM: 1, ItemName.RARE_ITEM: 1, ItemName.LEGENDARY_ITEM: 1},
            10: {ItemName.COMMON_ITEM: 4, ItemName.UNCOMMON_ITEM: 3, ItemName.RARE_ITEM: 2, ItemName.LEGENDARY_ITEM: 1},
            12: {ItemName.COMMON_ITEM: 5, ItemName.UNCOMMON_ITEM: 4, ItemName.RARE_ITEM: 2, ItemName.LEGENDARY_ITEM: 1},
            18: {ItemName.COMMON_ITEM: 8, ItemName.UNCOMMON_ITEM: 6, ItemName.RARE_ITEM: 3, ItemName.LEGENDARY_ITEM: 1},
            20: {
                ItemName.COMMON_ITEM: 10,
                ItemName.UNCOMMON_ITEM: 6,
                ItemName.RARE_ITEM: 3,
                ItemName.LEGENDARY_ITEM: 1,
            },
            23: {
                ItemName.COMMON_ITEM: 11,
                ItemName.UNCOMMON_ITEM: 6,
                ItemName.RARE_ITEM: 4,
                ItemName.LEGENDARY_ITEM: 2,
            },
            25: {
                ItemName.COMMON_ITEM: 12,
                ItemName.UNCOMMON_ITEM: 7,
                ItemName.RARE_ITEM: 4,
                ItemName.LEGENDARY_ITEM: 2,
            },
            30: {
                ItemName.COMMON_ITEM: 14,
                ItemName.UNCOMMON_ITEM: 9,
                ItemName.RARE_ITEM: 5,
                ItemName.LEGENDARY_ITEM: 2,
            },
            37: {
                ItemName.COMMON_ITEM: 18,
                ItemName.UNCOMMON_ITEM: 11,
                ItemName.RARE_ITEM: 6,
                ItemName.LEGENDARY_ITEM: 2,
            },
            40: {
                ItemName.COMMON_ITEM: 20,
                ItemName.UNCOMMON_ITEM: 12,
                ItemName.RARE_ITEM: 6,
                ItemName.LEGENDARY_ITEM: 2,
            },
            50: {
                ItemName.COMMON_ITEM: 24,
                ItemName.UNCOMMON_ITEM: 15,
                ItemName.RARE_ITEM: 8,
                ItemName.LEGENDARY_ITEM: 3,
            },
        }
        for total_checks, expected_items_per_rarity in num_checks_and_expected_items.items():
            with self.subTest(msg=f"{total_checks} crate drops"):
                # Sanity check that our test case doesn't have a math error
                self.assertEqual(
                    total_checks,
                    sum(expected_items_per_rarity.values()),
                    msg="Invalid test, number of expected crates does not equal number of total checks.",
                )

                # Set num_legendary_crate_drops to 0 so the only legendary items created are from the the logic tested.
                self._run({"num_common_crate_drops": total_checks, "num_legendary_crate_drops": 0})

                item_counts = Counter(self.multiworld.itempool)

                for item_name, expected_item_count in expected_items_per_rarity.items():
                    # Create a dummy item that we can use to index into the counter. This saves us the effort of trying
                    # to build the item name from the base item name and player name.
                    ref_item: BrotatoItem = self.world.create_item(item_name)
                    item_count: int = item_counts[ref_item]
                    self.assertEqual(expected_item_count, item_count)
