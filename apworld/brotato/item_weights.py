import itertools
import math
from collections import Counter
from random import Random

from Options import OptionError

from . import options
from .items import ItemName, item_name_groups


def create_items_from_weights(
    num_items: int,
    random: Random,
    common_item_weight: options.CommonItemWeight,
    uncommon_item_weight: options.UncommonItemWeight,
    rare_item_weight: options.RareItemWeight,
    legendary_item_weight: options.LegendaryItemWeight,
    common_upgrade_weight: options.CommonUpgradeWeight,
    uncommon_upgrade_weight: options.UncommonUpgradeWeight,
    rare_upgrade_weight: options.RareUpgradeWeight,
    legendary_upgrade_weight: options.LegendaryUpgradeWeight,
    gold_weight: options.GoldWeight,
    xp_weight: options.XpWeight,
) -> dict[ItemName, int]:
    gold_items = [ItemName(g) for g in sorted(item_name_groups["Gold"])]
    xp_items = [ItemName(x) for x in sorted(item_name_groups["XP"])]
    gold_item_weights = _create_weights_for_item_group(gold_weight.value, gold_items)
    xp_item_weights = _create_weights_for_item_group(xp_weight.value, xp_items)
    item_name_to_weight: dict[ItemName, int] = {
        ItemName.COMMON_ITEM: common_item_weight.value,
        ItemName.UNCOMMON_ITEM: uncommon_item_weight.value,
        ItemName.RARE_ITEM: rare_item_weight.value,
        ItemName.LEGENDARY_ITEM: legendary_item_weight.value,
        ItemName.COMMON_UPGRADE: common_upgrade_weight.value,
        ItemName.UNCOMMON_UPGRADE: uncommon_upgrade_weight.value,
        ItemName.RARE_UPGRADE: rare_upgrade_weight.value,
        ItemName.LEGENDARY_UPGRADE: legendary_upgrade_weight.value,
        **gold_item_weights,
        **xp_item_weights,
    }

    try:
        chosen_items = random.choices(
            list(item_name_to_weight.keys()), weights=list(item_name_to_weight.values()), k=num_items
        )
    except ValueError as ve:
        # The Python docs state that random.choices raises a ValueError if all weights are zero.
        raise OptionError("At least one item weight must be >0") from ve
    return Counter(chosen_items)


def _create_weights_for_item_group(weight: int, group: list[ItemName]) -> dict[ItemName, int]:
    base_weight, base_extra = divmod(weight, len(group))

    base_extra = math.ceil(base_extra)
    item_weights: dict[ItemName, int] = {item: base_weight for item in group}
    for _, item in zip(range(base_extra), itertools.cycle(item_weights)):
        item_weights[item] += 1
    return item_weights
