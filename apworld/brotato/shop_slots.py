from .constants import MAX_SHOP_SLOTS
from .options import NumberStartingShopLockButtons, StartingShopLockButtonsMode, StartingShopSlots


def get_num_shop_slot_and_lock_button_items(
    num_starting_slots: StartingShopSlots,
    lock_button_mode: StartingShopLockButtonsMode,
    num_starting_lock_buttons: NumberStartingShopLockButtons,
) -> tuple[int, int]:
    num_shop_slot_items: int = MAX_SHOP_SLOTS - num_starting_slots.value

    num_shop_lock_buttons: int
    match lock_button_mode.value:
        case StartingShopLockButtonsMode.option_all:
            num_shop_lock_buttons = 0
        case StartingShopLockButtonsMode.option_none:
            num_shop_lock_buttons = MAX_SHOP_SLOTS
        case StartingShopLockButtonsMode.option_custom:
            num_shop_lock_buttons = num_starting_lock_buttons.value
        case StartingShopLockButtonsMode.option_match_shop_slots:
            num_shop_lock_buttons = num_shop_slot_items
        case _:
            raise ValueError(f"Unknown starting shop lock button mode '{lock_button_mode}'.")
    return num_shop_slot_items, num_shop_lock_buttons
