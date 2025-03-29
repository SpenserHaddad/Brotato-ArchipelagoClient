import itertools
import math
from random import Random

from .items import ItemName, item_name_groups


def create_items_from_weights(
    num_items: int,
    random: Random,
    common_item_weight: int,
    uncommon_item_weight: int,
    rare_item_weight: int,
    legendary_item_weight: int,
    common_upgrade_weight: int,
    uncommon_upgrade_weight: int,
    rare_upgrade_weight: int,
    legendary_upgrade_weight: int,
    gold_weight: int,
    xp_weight: int,
) -> list[ItemName]:
    gold_items = [ItemName(g) for g in sorted(item_name_groups["Gold"])]
    xp_items = [ItemName(x) for x in sorted(item_name_groups["XP"])]
    gold_item_weights = _create_weights_for_item_group(gold_weight, gold_items)
    xp_item_weights = _create_weights_for_item_group(xp_weight, xp_items)
    item_name_to_weight: dict[ItemName, int] = {
        ItemName.COMMON_ITEM: common_item_weight,
        ItemName.UNCOMMON_ITEM: uncommon_item_weight,
        ItemName.RARE_ITEM: rare_item_weight,
        ItemName.LEGENDARY_ITEM: legendary_item_weight,
        ItemName.COMMON_UPGRADE: common_upgrade_weight,
        ItemName.UNCOMMON_UPGRADE: uncommon_upgrade_weight,
        ItemName.RARE_UPGRADE: rare_upgrade_weight,
        ItemName.LEGENDARY_UPGRADE: legendary_upgrade_weight,
        **gold_item_weights,
        **xp_item_weights,
    }
    return random.sample(list(item_name_to_weight.keys()), num_items, counts=item_name_to_weight.values())


def _create_weights_for_item_group(weight: int, group: list[ItemName]) -> dict[ItemName, int]:
    base_weight, base_extra = divmod(weight, len(group))

    base_extra = math.ceil(base_extra)
    item_weights: dict[ItemName, int] = {item: base_weight for item in group}
    while base_extra > 0:
        for item in itertools.cycle(item_weights):
            item_weights[item] += 1
            base_extra -= 1
    return item_weights
