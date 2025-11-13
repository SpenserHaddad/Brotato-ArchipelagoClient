from dataclasses import dataclass
from itertools import product
from typing import Any

from ...constants import MAX_SHOP_SLOTS
from ...options import StartingShopLockButtonsMode
from .base import BrotatoTestDataSet


@dataclass(frozen=True)
class ShopSlotsTestCase(BrotatoTestDataSet):
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

    @property
    def test_name(self) -> str:
        props = {
            "num_starting_shop_slots": self.num_starting_shop_slots,
            "lock_button_mode": self.lock_button_mode,
            "num_starting_lock_buttons": self.num_starting_lock_buttons,
            "expected_num_starting_lock_buttons": self.expected_num_starting_lock_buttons,
        }
        return ", ".join(f"{k}={v}" for k, v in props.items())

    @property
    def options_dict(self) -> dict[str, Any]:
        return {
            "num_starting_shop_slots": self.num_starting_shop_slots,
            "shop_lock_buttons_mode": self.lock_button_mode.value,
            "num_starting_lock_buttons": self.expected_num_starting_lock_buttons,
        }


SHOP_SLOT_TEST_DATA_SETS: list[ShopSlotsTestCase] = []

for num_shop_slots, num_lock_buttons in product(range(MAX_SHOP_SLOTS + 1), range(MAX_SHOP_SLOTS + 1)):
    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_all),
            num_starting_lock_buttons=num_lock_buttons,
            # option_all: Starting lock buttons should always be 4
            expected_num_starting_lock_buttons=MAX_SHOP_SLOTS,
        )
    )

    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_none),
            num_starting_lock_buttons=num_lock_buttons,
            # option_none: Starting lock buttons should always be 0
            expected_num_starting_lock_buttons=0,
        )
    )

    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_match_shop_slots),
            num_starting_lock_buttons=num_lock_buttons,
            # option_match_shop_slots: Starting lock buttons should disregard num_lock_buttons
            expected_num_starting_lock_buttons=num_shop_slots,
        )
    )

    SHOP_SLOT_TEST_DATA_SETS.append(
        ShopSlotsTestCase(
            num_starting_shop_slots=num_shop_slots,
            lock_button_mode=StartingShopLockButtonsMode(StartingShopLockButtonsMode.option_custom),
            num_starting_lock_buttons=num_lock_buttons,
            # option_custom: Starting lock buttons should match num_starting_lock_buttons
            expected_num_starting_lock_buttons=num_lock_buttons,
        )
    )
