from dataclasses import dataclass
from typing import List


@dataclass(frozen=True)
class BrotatoLootCrateGroup:
    index: int
    num_crates: int
    wins_to_unlock: int


def build_loot_crate_groups(num_crates: int, num_groups: int, num_victories: int) -> List[BrotatoLootCrateGroup]:
    # If the options specify more crate drop groups than number of required wins, clamp to the number of wins. This
    # makes the math simpler and ensures all items are accessible by go mode. Someone probably wants the option to have
    # items after completing their goal, but we're going to pretend they don't exist until they ask.
    num_groups_actual = min(num_groups, num_victories)

    crates_allocated = 0
    wins_to_unlock_group = 0
    num_wins_to_unlock_group = max(num_victories // num_groups_actual, 1)
    crates_per_group, extra_crates = divmod(num_crates, num_groups_actual)
    loot_crate_groups: List[BrotatoLootCrateGroup] = []

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
