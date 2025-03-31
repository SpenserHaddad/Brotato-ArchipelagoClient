import random
from contextlib import AbstractContextManager, nullcontext

import pytest

from test.bases import TestBase

from ..characters import get_available_and_starting_characters
from .data_sets.characters import (
    CHARACTER_TEST_DATA_SETS,
    NON_ERROR_CHARACTER_TEST_DATA_SETS,
)


class TestBrotatoCharacterOptions(TestBase):
    """Tests to ensure that we correctly determine the included and starting characters from options.

    This differs from `test_include_characters` and `test_starting_characters` in that it focuses on checking that the
    output from `get_available_and_starting_characters` is correct, rather than checking that the generated items,
    locations, etc. are correct.
    """

    def test_get_available_and_starting_characters_data_sets_correct_results(self):
        for data_set in CHARACTER_TEST_DATA_SETS:
            with self.subTest(data_set=data_set):
                error_checker: AbstractContextManager
                if data_set.expected_exception is not None:
                    error_checker = self.assertRaises(data_set.expected_exception)
                else:
                    error_checker = nullcontext()

                with error_checker:
                    available_characters, starting_characters = get_available_and_starting_characters(
                        data_set.include_base_game_characters,
                        data_set.enable_abyssal_terrors_dlc,
                        data_set.include_abyssal_terrors_characters,
                        data_set.starting_characters_mode,
                        data_set.num_starting_characters,
                        data_set.num_include_characters,
                        random.Random(0x7A70),
                    )

                    # We don't know for certain which characters were selected, so we settle for checking that they're
                    # a subset of the expected collection
                    assert set(starting_characters) <= data_set.valid_starting_characters
                    assert set(available_characters) <= data_set.valid_available_characters

    def test_get_available_and_starting_characters_data_sets_reproducible_results(self):
        for data_set in NON_ERROR_CHARACTER_TEST_DATA_SETS:
            with self.subTest(data_set=data_set):
                available_characters, starting_characters = get_available_and_starting_characters(
                    data_set.include_base_game_characters,
                    data_set.enable_abyssal_terrors_dlc,
                    data_set.include_abyssal_terrors_characters,
                    data_set.starting_characters_mode,
                    data_set.num_starting_characters,
                    data_set.num_include_characters,
                    random.Random(0x7A70),
                )

                for _ in range(2):
                    repeat_available_characters, repeat_starting_characters = get_available_and_starting_characters(
                        data_set.include_base_game_characters,
                        data_set.enable_abyssal_terrors_dlc,
                        data_set.include_abyssal_terrors_characters,
                        data_set.starting_characters_mode,
                        data_set.num_starting_characters,
                        data_set.num_include_characters,
                        random.Random(0x7A70),
                    )
                    assert starting_characters == repeat_starting_characters
                    assert available_characters == repeat_available_characters
