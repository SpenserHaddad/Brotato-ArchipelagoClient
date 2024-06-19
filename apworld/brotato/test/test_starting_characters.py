from typing import Optional, Sequence

from ..constants import CHARACTERS, DEFAULT_CHARACTERS
from ..items import item_name_groups
from . import BrotatoTestBase

_character_items = item_name_groups["Characters"]


class TestBrotatoStartingCharacters(BrotatoTestBase):
    def _run_and_check(
        self,
        num_characters: int,
        custom_starting_characters: bool = True,
        expected_characters: Optional[Sequence[str]] = None,
    ):
        # Create world with relevant options
        self.options = {
            "starting_characters": int(custom_starting_characters),
            "num_starting_characters": num_characters,
        }
        self.world_setup()

        # Get precollected items
        player_id = self.multiworld.player_ids[0]
        player_precollected = self.multiworld.precollected_items[player_id]
        precollected_characters = [p for p in player_precollected if p.name in _character_items]

        # Check that the number of starting characters is correct
        assert len(precollected_characters) == num_characters

        # Check that we have exactly some characters. This works best for testing the default characters, it's flakier
        # for others since we rely on the seed and random() calls to be consistent.
        if expected_characters is not None:
            assert (
                len(expected_characters) == num_characters
            ), "Test configuration error, num_characters does not match len(expected_characters)."
            for ec in expected_characters:
                expected_item = self.multiworld.worlds[player_id].create_item(ec)
                assert expected_item in precollected_characters

    def test_default_starting_characters(self):
        self._run_and_check(
            num_characters=len(DEFAULT_CHARACTERS),
            custom_starting_characters=False,
            expected_characters=DEFAULT_CHARACTERS,
        )

    # TODO: Probably can't use pytest.paramterize, is there a better way?
    def test_custom_starting_characters_1(self):
        self._run_and_check(num_characters=1)

    def test_custom_starting_characters_5(self):
        self._run_and_check(num_characters=5)

    def test_custom_starting_characters_15(self):
        self._run_and_check(num_characters=5)

    def test_custom_starting_characters_max(self):
        self._run_and_check(num_characters=len(CHARACTERS), expected_characters=CHARACTERS)
