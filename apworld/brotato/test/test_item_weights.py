from random import Random
from unittest import TestCase

from Options import OptionError, Range

from .. import options
from ..item_weights import create_items_from_weights
from ..items import ItemName, item_name_groups


class TestBrotatoItemWeights(TestCase):
    """Check that custom item weights are respected by setting weights for all but one item tier to 0 and confirming
    only items of that tier are made.

    It would be nice to test more option combinations, but there doesn't seem to be a good way to do so without
    patching self.world.random, which makes the test tautological.
    """

    def test_all_weights_zero_except_one(self):
        num_items = 100
        option_to_expected_items: dict[type[Range], ItemName | list[ItemName]] = {
            options.CommonItemWeight: ItemName.COMMON_ITEM,
            options.UncommonItemWeight: ItemName.UNCOMMON_ITEM,
            options.RareItemWeight: ItemName.RARE_ITEM,
            options.LegendaryItemWeight: ItemName.LEGENDARY_ITEM,
            options.CommonUpgradeWeight: ItemName.COMMON_UPGRADE,
            options.UncommonUpgradeWeight: ItemName.UNCOMMON_UPGRADE,
            options.RareUpgradeWeight: ItemName.RARE_UPGRADE,
            options.LegendaryUpgradeWeight: ItemName.LEGENDARY_UPGRADE,
            options.GoldWeight: [ItemName(name) for name in item_name_groups["Gold"]],
            options.XpWeight: [ItemName(name) for name in item_name_groups["XP"]],
        }
        for active_weight, expected_items in option_to_expected_items.items():
            with self.subTest(active_weight=active_weight):
                weights = [opt(1) if opt is active_weight else opt(0) for opt in option_to_expected_items.keys()]
                # We put the order of the dictionary keys in the same order as the expected arguments. Not pretty, but
                # good enough without doing weird typing stuff.
                item_names = create_items_from_weights(num_items, Random(0x12345), *weights)  # type: ignore
                total_items = sum(item_names.values())
                if not isinstance(expected_items, list):
                    expected_items = [expected_items]
                self.assertEqual(total_items, num_items)
                for item_name in item_names:
                    self.assertIn(item_name, expected_items)

    def test_pair_of_weights_scale_properly(self):
        item_names = create_items_from_weights(
            100,
            Random(0x34567),
            options.CommonItemWeight(20),
            options.UncommonItemWeight(0),
            options.RareItemWeight(0),
            options.LegendaryItemWeight(0),
            options.CommonUpgradeWeight(10),  # Note that this is half of the weight for common items
            options.UncommonUpgradeWeight(0),
            options.RareUpgradeWeight(0),
            options.LegendaryUpgradeWeight(0),
            options.GoldWeight(0),
            options.XpWeight(0),
        )

        total_items = sum(item_names.values())
        self.assertEqual(total_items, 100)
        self.assertSetEqual(set(item_names.keys()), {ItemName.COMMON_ITEM, ItemName.COMMON_UPGRADE})
        item_count = item_names[ItemName.COMMON_ITEM]
        upgrade_count = item_names[ItemName.COMMON_UPGRADE]

        # We can't actually guarantee that item_count = 2 * upgrade_count, but with a sample size of 100 we should be
        # able to guarantee that item_count > upgrade_count.
        self.assertGreater(item_count, upgrade_count)

    def test_all_weights_zero_raises_error(self):
        with self.assertRaises(OptionError):
            create_items_from_weights(
                100,
                Random(0x34567),
                options.CommonItemWeight(0),
                options.UncommonItemWeight(0),
                options.RareItemWeight(0),
                options.LegendaryItemWeight(0),
                options.CommonUpgradeWeight(0),
                options.UncommonUpgradeWeight(0),
                options.RareUpgradeWeight(0),
                options.LegendaryUpgradeWeight(0),
                options.GoldWeight(0),
                options.XpWeight(0),
            )
