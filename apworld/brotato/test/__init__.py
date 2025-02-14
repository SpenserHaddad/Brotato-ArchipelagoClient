from typing import ClassVar

from test.bases import WorldTestBase

from .. import BrotatoWorld
from .data_sets.loot_crates import TEST_DATA_SETS


class BrotatoTestBase(WorldTestBase):
    game = "Brotato"
    world: BrotatoWorld  # type: ignore
    player: ClassVar[int] = 1

    def _test_data_set_subtests(self):
        for test_data in TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data.options_dict)
                yield test_data

    def _run(self, options: dict):
        """Setup the world using the options from the dataset.

        We make this distinct from setUp() so tests can call this from subTests when
        iterating overt TEST_DATA_SETS.
        """
        self.options.update(options)
        self.world_setup()
