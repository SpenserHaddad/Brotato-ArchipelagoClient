"""Define test data for various Brotato unit tests.

Test data consists of a set of options to create the test World with, and various expected results.

Test classes can create subtests which run on each data set to check that generation works for different option
combinations.

Currently, the test data sets are focused on testing the crate drop region creation and access rules, but there's no
reason it couldn't be expanded to handle more in the future.
"""

from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional, Tuple, Union

from ...constants import (
    BASE_GAME_CHARACTERS,
    MAX_LEGENDARY_CRATE_DROP_GROUPS,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROP_GROUPS,
    MAX_NORMAL_CRATE_DROPS,
)
from .base import BrotatoTestDataSet


@dataclass(frozen=True)
class BrotatoLootCrateTestOptions:
    """Subset of the full options that we want to control for the test, with defaults.

    This avoids needing to specify all the options for the dataclass, and makes using it in the tests slightly more
    concise.
    """

    num_common_crate_drops: int
    num_common_crate_drop_groups: int
    num_legendary_crate_drops: int
    num_legendary_crate_drop_groups: int
    num_victories: int = 30


@dataclass(frozen=True)
class BrotatoLootCrateTestExpectedResults:
    # An int value means all regions have the same number of crates.
    # A tuple of ints means region "Crate Group {i}" has number of crates in index [i]
    num_common_crate_regions: int
    common_crates_per_region: Union[int, Tuple[int, ...]]
    num_legendary_crate_regions: int
    legendary_crates_per_region: Union[int, Tuple[int, ...]]
    wins_required_per_common_region: Tuple[int, ...]
    wins_required_per_legendary_region: Tuple[int, ...]

    def __post_init__(self):
        """Validate the expected results to make sure the fields are consistent.

        Currently, this just means checking that the expected number of regions matches the number of entries in the
        crates per region fields.
        """

        if isinstance(self.common_crates_per_region, tuple):
            num_common_crate_regions = len(self.common_crates_per_region)
            if num_common_crate_regions != self.num_common_crate_regions:
                raise ValueError(
                    f"common_crates_per_region has {num_common_crate_regions} entries, expected "
                    f"{self.num_common_crate_regions}."
                )

        if len(self.wins_required_per_common_region) != self.num_common_crate_regions:
            num_win_entries = len(self.wins_required_per_common_region)
            raise ValueError(
                f"wins_required_per_common_region has {num_win_entries} entries, expected "
                f"{self.num_common_crate_regions}."
            )

        if isinstance(self.legendary_crates_per_region, tuple):
            num_legendary_crate_regions = len(self.legendary_crates_per_region)
            if num_legendary_crate_regions != self.num_legendary_crate_regions:
                raise ValueError(
                    f"legendary_crates_per_region has {num_legendary_crate_regions} entries, expected "
                    f"{self.num_legendary_crate_regions}."
                )

        if len(self.wins_required_per_legendary_region) != self.num_legendary_crate_regions:
            num_win_entries = len(self.wins_required_per_legendary_region)
            raise ValueError(
                f"wins_required_per_legendary_region has {num_win_entries} entries, expected "
                f"{self.num_legendary_crate_regions}."
            )


@dataclass(frozen=True)
class BrotatoLootCrateTestDataSet(BrotatoTestDataSet):
    options: BrotatoLootCrateTestOptions
    expected_results: BrotatoLootCrateTestExpectedResults
    description: Optional[str] = None

    def test_name(self) -> str:
        options_str = ", ".join(
            [
                f"CD={self.options.num_common_crate_drops}",
                f"CG={self.options.num_common_crate_drop_groups}",
                f"LD={self.options.num_legendary_crate_drops}",
                f"LG={self.options.num_legendary_crate_drop_groups}",
                f"NV={self.options.num_victories}",
            ]
        )
        if self.description:
            name = f"{options_str} ({self.description})"
        else:
            name = options_str

        return name

    @property
    def options_dict(self) -> Dict[str, Any]:
        return asdict(self.options)


TEST_DATA_SETS: List[BrotatoLootCrateTestDataSet] = [
    BrotatoLootCrateTestDataSet(
        description="Easily divisible, common and legendary same (25 crates)",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=25,
            num_common_crate_drop_groups=5,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=5,
            common_crates_per_region=5,
            num_legendary_crate_regions=5,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 6, 12, 18, 24),
            wins_required_per_legendary_region=(0, 6, 12, 18, 24),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Easily divisible, common and legendary same (30 crates)",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=30,
            num_common_crate_drop_groups=6,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=6,
            common_crates_per_region=5,
            num_legendary_crate_regions=6,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 5, 10, 15, 20, 25),
            wins_required_per_legendary_region=(0, 5, 10, 15, 20, 25),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Easily divisible, common and legendary are different",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=20,
            num_common_crate_drop_groups=2,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=2,
            common_crates_per_region=10,
            num_legendary_crate_regions=6,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 15),
            wins_required_per_legendary_region=(0, 5, 10, 15, 20, 25),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Unequal groups",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=16,
            num_common_crate_drop_groups=3,
            num_legendary_crate_drops=16,
            num_legendary_crate_drop_groups=3,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=3,
            common_crates_per_region=(6, 5, 5),
            num_legendary_crate_regions=3,
            legendary_crates_per_region=(6, 5, 5),
            wins_required_per_common_region=(0, 10, 20),
            wins_required_per_legendary_region=(0, 10, 20),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Unequal groups, common and legendary are different",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=35,
            num_common_crate_drop_groups=15,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            # Five "3's" and ten "2's", because the drops don't evenly divide into the groups
            num_common_crate_regions=15,
            common_crates_per_region=tuple(([3] * 5) + ([2] * 10)),
            num_legendary_crate_regions=5,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(
                0,
                2,
                4,
                6,
                8,
                10,
                12,
                14,
                16,
                18,
                20,
                22,
                24,
                26,
                28,
            ),
            wins_required_per_legendary_region=(0, 6, 12, 18, 24),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Max possible groups and crates, more groups than req. wins, no DLC",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=MAX_NORMAL_CRATE_DROPS,
            num_common_crate_drop_groups=MAX_NORMAL_CRATE_DROP_GROUPS,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=MAX_LEGENDARY_CRATE_DROP_GROUPS,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            # The number of groups will be set to 30 (default # of wins) when generated.
            num_common_crate_regions=30,
            common_crates_per_region=tuple(([2] * 20) + ([1] * 10)),
            num_legendary_crate_regions=30,
            legendary_crates_per_region=tuple(([2] * 20) + ([1] * 10)),
            # Every win will unlock a new crate drop group.
            wins_required_per_common_region=tuple(range(30)),
            wins_required_per_legendary_region=tuple(range(30)),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Max wins, one crate per character, one group per character, no DLC",
        options=BrotatoLootCrateTestOptions(
            num_victories=BASE_GAME_CHARACTERS.num_characters,
            num_common_crate_drops=BASE_GAME_CHARACTERS.num_characters,
            # Assign one group per character, so each win makes more crates accessible.
            num_common_crate_drop_groups=BASE_GAME_CHARACTERS.num_characters,
            num_legendary_crate_drops=BASE_GAME_CHARACTERS.num_characters,
            num_legendary_crate_drop_groups=BASE_GAME_CHARACTERS.num_characters,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=BASE_GAME_CHARACTERS.num_characters,
            common_crates_per_region=tuple([1] * BASE_GAME_CHARACTERS.num_characters),
            num_legendary_crate_regions=BASE_GAME_CHARACTERS.num_characters,
            legendary_crates_per_region=tuple([1] * BASE_GAME_CHARACTERS.num_characters),
            # Every win will unlock a new crate drop group.
            wins_required_per_common_region=tuple(range(BASE_GAME_CHARACTERS.num_characters)),
            wins_required_per_legendary_region=tuple(range(BASE_GAME_CHARACTERS.num_characters)),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Max number of crates, one group",
        options=BrotatoLootCrateTestOptions(
            num_victories=BASE_GAME_CHARACTERS.num_characters,
            num_common_crate_drops=MAX_NORMAL_CRATE_DROPS,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=50,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=50,
            # All the crates should be in the first group which is unlocked by default.
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="1 crate and 1 group",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=1,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=1,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=1,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=1,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="2 crates, 1 group",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=2,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=2,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=2,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=2,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    BrotatoLootCrateTestDataSet(
        description="Max number of crates, 1 common group, 2 legendary groups",
        options=BrotatoLootCrateTestOptions(
            num_common_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=2,
        ),
        expected_results=BrotatoLootCrateTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=50,
            num_legendary_crate_regions=2,
            legendary_crates_per_region=25,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0, 15),
        ),
    ),
]
