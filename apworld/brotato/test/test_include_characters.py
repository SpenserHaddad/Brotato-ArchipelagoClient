import random
from typing import List

from BaseClasses import PlandoOptions, Region
from Options import OptionError

from ..constants import BASE_GAME_CHARACTERS, CHARACTER_REGION_TEMPLATE
from ..items import ItemName
from ..options import StartingCharacters
from . import BrotatoTestBase
from .data_sets.characters import NON_ERROR_CASE_CHARACTER_TEST_DATA_SETS


class TestBrotatoIncludeCharacters(BrotatoTestBase):
    auto_construct = False

    def test_include_characters_can_fill(self):
        # Which characters we pick to include shouldn't matter, just the amount. But let's randomize who we pick each
        # time just in case.
        r = random.Random(0x7A70)
        for num_include_characters in range(1, BASE_GAME_CHARACTERS.num_characters + 1):
            with self.subTest(msg=f"{num_include_characters=}", n=num_include_characters):
                include_characters: List[str] = r.sample(BASE_GAME_CHARACTERS.characters, k=num_include_characters)
                self.options = {
                    "starting_characters": 1,
                    "include_characters": include_characters,
                    "waves_per_drop": 5,
                }
                self.world_setup()
                self.test_fill()
                self.assertBeatable(True)

    def test_include_characters_invalid_values_raises_exception(self):
        valid_include_characters = BASE_GAME_CHARACTERS.characters[:10]
        invalid_include_characters = [
            "Well-Rounded",
            "Bul",
            "Jigglypuff",
            "asdfdadfdasdf",
            "",
            "ireallywishihadhypothesisrn",
        ]

        for invalid_character in invalid_include_characters:
            with self.subTest(invalid_character=invalid_character):
                include_characters = {*valid_include_characters, invalid_character}
                self.options = {
                    "starting_characters": 1,
                    "include_base_game_characters": include_characters,
                }
                # The VerifyKeys mixin on OptionSet raises a bare Exception when it encounters an invalid key.
                self.world_setup()
                self.assertRaises(
                    OptionError,
                    self.world.options.include_base_game_characters.verify,
                    self.world,
                    self.world.player_name,
                    PlandoOptions.none,
                )

    def test_include_characters_excluded_characters_do_not_have_regions(self):
        include_characters = BASE_GAME_CHARACTERS.characters[:10]
        self.options = {
            "starting_characters": 1,
            "include_base_game_characters": include_characters,
        }
        self.world_setup()

        player_regions: dict[str, Region] = {r.name: r for r in self.multiworld.regions if r.player == self.player}

        for character in BASE_GAME_CHARACTERS.characters:
            character_region_name = CHARACTER_REGION_TEMPLATE.format(char=character)
            if character in include_characters:
                self.assertIn(character_region_name, player_regions)
            else:
                self.assertNotIn(character_region_name, player_regions)

    def test_include_characters_excludes_default_characters(self):
        """Test that excluded characters are not in the starting pool if they would be
        otherwise.

        Essentially testing that "starting_characters" and "include_*_characters"
        options interact as expected.
        """
        include_characters = set(BASE_GAME_CHARACTERS.characters)
        include_characters.remove("Brawler")
        expected_starting_characters = set(BASE_GAME_CHARACTERS.default_characters)
        expected_starting_characters.remove("Brawler")

        self.options = {
            "starting_characters": StartingCharacters.option_default_base_game,
            "include_base_game_characters": include_characters,
        }
        self.world_setup()

        player_precollected = self.multiworld.precollected_items[self.player]
        precollected_characters = {p.name for p in player_precollected if p.name in BASE_GAME_CHARACTERS.characters}

        self.assertSetEqual(precollected_characters, expected_starting_characters)

    def test_include_characters_less_characters_than_wins_changes_goal(self):
        include_characters = set(BASE_GAME_CHARACTERS.default_characters)
        self.options = {
            "starting_characters": 1,
            "include_base_game_characters": include_characters,
            "wins_required": 30,
        }
        self.world_setup()

        self.assertFalse(self.multiworld.has_beaten_game(self.multiworld.state))
        # Create a "Run Won" item for each character included, give them to the player, then check that we've "won"
        run_won_items = [self.world.create_item(ItemName.RUN_COMPLETE) for _ in include_characters]
        self.collect(run_won_items)
        self.assertTrue(self.multiworld.has_beaten_game(self.multiworld.state))

    def test_include_characters_regions_data_set(self):
        for data_set in self.data_set_subtests(NON_ERROR_CASE_CHARACTER_TEST_DATA_SETS):
            player_regions: dict[str, Region] = {r.name: r for r in self.multiworld.regions if r.player == self.player}

            for character in BASE_GAME_CHARACTERS.characters:
                character_region_name = CHARACTER_REGION_TEMPLATE.format(char=character)
                if character in data_set.valid_available_characters:
                    self.assertIn(character_region_name, player_regions)
                else:
                    self.assertNotIn(character_region_name, player_regions)
