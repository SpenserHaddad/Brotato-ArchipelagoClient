from ..constants import CHARACTER_REGION_TEMPLATE, CHARACTERS, DEFAULT_CHARACTERS
from ..items import ItemName
from . import BrotatoTestBase


class TestBrotatoIncludeCharacters(BrotatoTestBase):
    auto_construct = False

    def test_include_characters_ignores_invalid_values(self):
        valid_include_characters = CHARACTERS[:10]
        invalid_include_characters = ["Jigglypuff", "asdfdadfdasdf", "", "ireallywishihadhypothesisrn"]
        include_characters = {*valid_include_characters, *invalid_include_characters}
        self.options = {
            "starting_characters": 1,
            "include_characters": include_characters,
        }
        self.world_setup()

        expected_regions = {CHARACTER_REGION_TEMPLATE.format(char=char) for char in valid_include_characters}

        character_regions = {
            r.name for r in self.multiworld.regions if r.player == self.player and r.name.startswith("In-Game")
        }

        self.assertSetEqual(expected_regions, character_regions)

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

        self.assertBeatable(False)
        # Create a "Run Won" item for each character included, give them to the player, then check that we've "won"
        run_won_items = [self.world.create_item(ItemName.RUN_COMPLETE) for _ in include_characters]
        self.collect(run_won_items)
        self.assertBeatable(True)
