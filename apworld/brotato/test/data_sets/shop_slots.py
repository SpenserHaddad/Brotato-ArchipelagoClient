from dataclasses import dataclass
from itertools import product

from ...constants import MAX_SHOP_SLOTS
from ...options import StartingShopLockButtonsMode


@dataclass(frozen=True)
class ShopSlotsTestCase:
    num_starting_shop_slots: int
    lock_button_mode: StartingShopLockButtonsMode
    num_starting_lock_buttons: int
    expected_num_starting_lock_buttons: int

    @property
    def expected_num_shop_slot_items(self) -> int:
        return MAX_SHOP_SLOTS - self.num_starting_shop_slots

    @property
    def expected_num_lock_button_items(self) -> int:
        return MAX_SHOP_SLOTS - self.expected_num_starting_lock_buttons


SHOP_SLOT_TEST_DATA_SETS: list[ShopSlotsTestCase] = []

for num_shop_slots, num_lock_buttons in product(range(MAX_SHOP_SLOTS + 1), range(MAX_SHOP_SLOTS + 1)):
    # all should always be 4
    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_all),
            num_starting_lock_buttons=num_lock_buttons,
            expected_num_starting_lock_buttons=MAX_SHOP_SLOTS,
        )
    )

    # none should always be 0
    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_none),
            num_starting_lock_buttons=num_lock_buttons,
            expected_num_starting_lock_buttons=0,
        )
    )

    # match_shop_slots should disregard num_lock_buttons
    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_match_shop_slots),
            num_starting_lock_buttons=num_lock_buttons,
            expected_num_starting_lock_buttons=num_shop_slots,
        )
    )

    # custom should ignore num_slots
    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_custom),
            num_starting_lock_buttons=num_lock_buttons,
            expected_num_starting_lock_buttons=num_lock_buttons,
        )
    )
