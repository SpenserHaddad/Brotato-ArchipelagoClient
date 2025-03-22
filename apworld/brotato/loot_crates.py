from collections import Counter
from dataclasses import dataclass
from random import Random

from .constants import DEFAULT_ITEM_WEIGHTS, ItemRarity
from .items import ItemName
from .options import (
    CommonItemWeight,
    ItemWeights,
    LegendaryItemWeight,
    NumberCommonCrateDropLocations,
    NumberLegendaryCrateDropLocations,
    RareItemWeight,
    UncommonItemWeight,
)

ITEM_NAMES_TO_RARITY: dict[ItemName, ItemRarity] = {
    ItemName.COMMON_ITEM: ItemRarity.COMMON,
    ItemName.UNCOMMON_ITEM: ItemRarity.UNCOMMON,
    ItemName.RARE_ITEM: ItemRarity.RARE,
    ItemName.LEGENDARY_ITEM: ItemRarity.LEGENDARY,
}


def create_items_for_loot_crate_locations(
    num_common_crate_drops: NumberCommonCrateDropLocations,
    num_legendary_crate_drops: NumberLegendaryCrateDropLocations,
    item_weight_mode: ItemWeights,
    common_item_weight: CommonItemWeight,
    uncommon_item_weight: UncommonItemWeight,
    rare_item_weight: RareItemWeight,
    legendary_item_weight: LegendaryItemWeight,
    random: Random,
) -> dict[ItemName, int]:
    weights: tuple[int, int, int, int] = _get_weights_for_mode(
        item_weight_mode, common_item_weight, uncommon_item_weight, rare_item_weight, legendary_item_weight, random
    )
    common_items: list[ItemName] = random.choices(
        list(ITEM_NAMES_TO_RARITY.keys()), weights=weights, k=num_common_crate_drops.value
    )
    item_counts = Counter(common_items)

    # Each legendary crate location corresponds to a legendary item, just update the counter.
    item_counts[ItemName.LEGENDARY_ITEM] = item_counts.get(ItemName.LEGENDARY_ITEM, 0) + num_legendary_crate_drops.value
    return Counter(item_counts)


def get_wave_for_each_item(item_counts: dict[ItemName, int]) -> dict[int, list[int]]:
    """Create the wave each item should be generated with.

    In each item rarity tier, increment the wave by one for each item, looping over at 20 (the max number of waves in a
    run), then sort the result so we have an even distribution of waves in increasing order.

    Brotato generates items from a pool determined by the rarity (or tier) of the item and the wave the item was found
    or bought. We want to emulate this behavior with the items we create here, so items aren't just all from the weakest
    or strongest pool when given to the player. This determines the effective wave to use for each item when it's
    received. When the client receives the next item for a certain rarity, it will lookup the next entry in the list for
    the rarity and use that as the wave when generating the values.

    We attempt to equally distribute the items over the 20 waves in a normal run, with a bias towards lower numbers,
    since it's already too easy to get overpowered.
    """

    def generate_waves_per_item(num_items: int) -> list[int]:
        # Evenly distribute the items over 20 waves, then sort so items received are generated with steadily
        # increasing waves (aka they got steadily stronger).
        return sorted((i % 20) + 1 for i in range(num_items))

    # Use a default of 0 in case no items of a tier were created for whatever reason.
    return {
        rarity.value: generate_waves_per_item(item_counts.get(name, 0)) for name, rarity in ITEM_NAMES_TO_RARITY.items()
    }


def _get_weights_for_mode(
    item_weight_mode: ItemWeights,
    common_item_weight: CommonItemWeight,
    uncommon_item_weight: UncommonItemWeight,
    rare_item_weight: RareItemWeight,
    legendary_item_weight: LegendaryItemWeight,
    random: Random,
) -> tuple[int, int, int, int]:
    match item_weight_mode.value:
        case ItemWeights.option_default:
            return DEFAULT_ITEM_WEIGHTS
        case ItemWeights.option_chaos:
            # Ask each weight class for their bounds separately in case we ever make them different.
            return (
                random.randint(CommonItemWeight.range_start, CommonItemWeight.range_end),
                random.randint(UncommonItemWeight.range_start, UncommonItemWeight.range_end),
                random.randint(RareItemWeight.range_start, RareItemWeight.range_end),
                random.randint(LegendaryItemWeight.range_start, LegendaryItemWeight.range_end),
            )
        case ItemWeights.option_custom:
            return (
                common_item_weight.value,
                uncommon_item_weight.value,
                rare_item_weight.value,
                legendary_item_weight.value,
            )
        case _:
            raise ValueError(f"Unsupported item_weight_mode {item_weight_mode.value}.")


@dataclass(frozen=True)
class BrotatoLootCrateGroup:
    index: int
    num_crates: int
    wins_to_unlock: int


def build_loot_crate_groups(num_crates: int, num_groups: int, num_victories: int) -> list[BrotatoLootCrateGroup]:
    # If the options specify more crate drop groups than number of required wins, clamp to the number of wins. This
    # makes the math simpler and ensures all items are accessible by go mode. Someone probably wants the option to have
    # items after completing their goal, but we're going to pretend they don't exist until they ask.
    num_groups_actual = min(num_groups, num_victories)

    crates_allocated = 0
    wins_to_unlock_group = 0
    num_wins_to_unlock_group = max(num_victories // num_groups_actual, 1)
    crates_per_group, extra_crates = divmod(num_crates, num_groups_actual)
    loot_crate_groups: list[BrotatoLootCrateGroup] = []

    for group_count in range(1, num_groups_actual + 1):
        crates_in_group = min(crates_per_group, num_crates - crates_allocated)

        if extra_crates > 0:
            # If the number of crates doesn't evenly divide into the number of groups, add 1 to each group until all the
            # extras are used. This ensures the groups are as even as possible. The extra is the remainder of evenly
            # dividing the number of items over the number of groups, so in the worst case every group but the last will
            # have an extra added to it.
            crates_in_group += 1
            extra_crates -= 1

        crates_allocated += crates_in_group

        loot_crate_groups.append(
            BrotatoLootCrateGroup(
                index=group_count,
                num_crates=crates_in_group,
                wins_to_unlock=wins_to_unlock_group,
            )
        )
        # Set this for the next group now. This is the easiest way to ensure group 1 requires 0 victories.
        wins_to_unlock_group = min(wins_to_unlock_group + num_wins_to_unlock_group, num_victories)

    return loot_crate_groups
