from ..constants import BASE_GAME_CHARACTERS
from . import BrotatoTestBase


class TestBrotatoNumVictoriesOption(BrotatoTestBase):
    """Test edge cases related to the num_victories option."""

    def test_num_victories_clamped_to_number_of_characters(self):
        """Test that the number of victories is not more than the number of included characters.

        This prevents unwinnable situtations where there aren't enough characters to reach the goal with.

        We also check the output slot data to make sure the change, if made, propagates to it as well.
        """
        expected_final_num_victories_value = BASE_GAME_CHARACTERS.num_characters - 5
        include_characters = BASE_GAME_CHARACTERS.characters[:expected_final_num_victories_value]
        original_num_victories_value = BASE_GAME_CHARACTERS.num_characters

        options = {
            "num_victories": original_num_victories_value,
            "include_base_game_characters": include_characters,
        }

        self._run(options)

        final_num_victories_value = self.world.options.num_victories.value
        # Checking slot data here so we don't need to duplicate the test setup in multiple functions/files.
        slot_data_num_victories = self.world.fill_slot_data()["num_wins_needed"]

        self.assertEqual(expected_final_num_victories_value, final_num_victories_value)
        self.assertEqual(expected_final_num_victories_value, slot_data_num_victories)
