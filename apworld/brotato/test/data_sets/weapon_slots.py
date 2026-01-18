from dataclasses import dataclass
from typing import Any

from .base import BrotatoTestDataSet


@dataclass(frozen=True)
class WeaponSlotsTestCase(BrotatoTestDataSet):
    num_starting_weapon_slots: int
    expected_num_weapon_slot_items: int

    @property
    def test_name(self) -> str:
        return (
            f"num_starting_weapon_slots={self.num_starting_weapon_slots}, "
            f"expected_num_weapon_slot_items={self.expected_num_weapon_slot_items}"
        )

    @property
    def options_dict(self) -> dict[str, Any]:
        return {"num_starting_weapon_slots": self.num_starting_weapon_slots}


# Brute force the combinations for readability (this is overengineered enough already)
WEAPON_SLOT_TEST_DATA_SETS: list[WeaponSlotsTestCase] = [
    WeaponSlotsTestCase(num_starting_weapon_slots=1, expected_num_weapon_slot_items=5),
    WeaponSlotsTestCase(num_starting_weapon_slots=2, expected_num_weapon_slot_items=4),
    WeaponSlotsTestCase(num_starting_weapon_slots=3, expected_num_weapon_slot_items=3),
    WeaponSlotsTestCase(num_starting_weapon_slots=4, expected_num_weapon_slot_items=2),
    WeaponSlotsTestCase(num_starting_weapon_slots=5, expected_num_weapon_slot_items=1),
    WeaponSlotsTestCase(num_starting_weapon_slots=6, expected_num_weapon_slot_items=0),
]
