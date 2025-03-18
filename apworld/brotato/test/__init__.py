from copy import deepcopy
from typing import ClassVar, Iterable

from test.bases import WorldTestBase

from .. import BrotatoWorld
from .data_sets.base import BrotatoTestDataSet


class BrotatoTestBase(WorldTestBase):
    game = "Brotato"
    world: BrotatoWorld  # type: ignore
    player: ClassVar[int] = 1

    def data_set_subtests(self, data_set: Iterable[BrotatoTestDataSet]):
        """Iterate over data sets and create a separate test case for each.

        Handles creating the subTest, and applying the options to the test class and then tearing them down so
        class-level options aren't overwritten between subTests, which can lead to tests because they're expected
        options aren't set.
        """
        for ds in data_set:
            with self.subTest(msg=ds.test_name()):
                self._run(ds.options_dict)
                yield ds

    def _run(self, options: dict):
        """Setup the world using the options from the dataset.

        We make this distinct from setUp() so tests can call this from subTests when
        iterating overt TEST_DATA_SETS.
        """
        original_options = deepcopy(self.options)
        try:
            self.options.update(options)
            self.world_setup()
        finally:
            # Make sure we don't override class-level options between tests
            self.options = deepcopy(original_options)
