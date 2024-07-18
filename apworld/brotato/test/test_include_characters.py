import random
from typing import List

from BaseClasses import Region

from ..constants import CHARACTER_REGION_TEMPLATE, CHARACTERS, DEFAULT_CHARACTERS
from ..items import ItemName
from . import BrotatoTestBase


class TestBrotatoIncludeCharacters(BrotatoTestBase):
    auto_construct = False

    def test_include_characters_can_fill(self):
        # Which characters we pick to include shouldn't matter, just the amount. But let's randomize who we pick each
        # time just in case.
        r = random.Random(0x7A70)
        for num_include_characters in range(1, len(CHARACTERS) + 1):
            with self.subTest(msg=f"{num_include_characters=}", n=num_include_characters):
                include_characters: List[str] = r.sample(CHARACTERS, k=num_include_characters)
                self.options = {"starting_characters": 1, "include_characters": include_characters}
                self.world_setup()
                self.test_fill()
                self.assertBeatable(True)

    def test_include_characters_ignores_invalid_values(self):
        valid_include_characters = CHARACTERS[:10]
        invalid_include_characters = ["Jigglypuff", "asdfdadfdasdf", "", "ireallywishihadhypothesisrn"]
        include_characters = {*valid_include_characters, *invalid_include_characters}
        self.options = {"starting_characters": 1, "include_characters": include_characters}
        self.world_setup()

        expected_regions = {CHARACTER_REGION_TEMPLATE.format(char=char) for char in valid_include_characters}

        character_regions = {
            r.name for r in self.multiworld.regions if r.player == self.player and r.name.startswith("In-Game")
        }

        self.assertSetEqual(expected_regions, character_regions)

    def test_include_characters_excluded_characters_do_not_have_regions(self):
        include_characters = CHARACTERS[:10]
        self.options = {"starting_characters": 1, "include_characters": include_characters}
        self.world_setup()

        player_regions: dict[str, Region] = {r.name: r for r in self.multiworld.regions if r.player == self.player}

        for character in CHARACTERS:
            character_region_name = CHARACTER_REGION_TEMPLATE.format(char=character)
            if character in include_characters:
                self.assertIn(character_region_name, player_regions)
            else:
                self.assertNotIn(character_region_name, player_regions)

    def test_include_characters_excludes_default_characters(self):
        include_characters = set(CHARACTERS)
        include_characters.remove("Brawler")
        expected_starting_characters = set(DEFAULT_CHARACTERS)
        expected_starting_characters.remove("Brawler")

        self.options = {"starting_characters": 0, "include_characters": include_characters}
        self.world_setup()

        player_precollected = self.multiworld.precollected_items[self.player]
        precollected_characters = {p.name for p in player_precollected if p.name in CHARACTERS}

        self.assertSetEqual(precollected_characters, expected_starting_characters)

    def test_include_characters_less_characters_than_wins_changes_goal(self):
        include_characters = set(DEFAULT_CHARACTERS)
        self.options = {"starting_characters": 1, "include_characters": include_characters, "wins_required": 30}
        self.world_setup()

        self.assertFalse(self.multiworld.has_beaten_game(self.multiworld.state))
        # Create a "Run Won" item for each character included, give them to the player, then check that we've "won"
        run_won_items = [self.world.create_item(ItemName.RUN_COMPLETE) for _ in include_characters]
        self.collect(run_won_items)
        self.assertTrue(self.multiworld.has_beaten_game(self.multiworld.state))
