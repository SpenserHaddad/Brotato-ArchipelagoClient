from contextlib import contextmanager
from typing import Any, ClassVar

from test.bases import WorldTestBase

from .. import BrotatoWorld
from .data_sets.base import BrotatoTestDataSet


class BrotatoTestBase(WorldTestBase):
    game: ClassVar[str] = "Brotato"
    world: BrotatoWorld  # type: ignore  # pyright: ignore[reportIncompatibleVariableOverride]
    player: ClassVar[int] = 1

    @contextmanager
    def data_set_subtest(self, data_set: BrotatoTestDataSet, **kwargs: Any):  # pyright: ignore[reportAny, reportExplicitAny]
        with self.subTest(msg=data_set.test_name, **kwargs), self._run(data_set.options_dict):
            yield

    @contextmanager
    def _run(self, run_options: dict[str, Any]):  # pyright: ignore[reportExplicitAny]
        """Setup the world using the options from the dataset.

        We make this distinct from setUp() so tests can call this from subTests when
        iterating overt TEST_DATA_SETS.
        """
        original_options = self.options
        self.options: dict[str, Any] = {**original_options, **run_options}  # pyright: ignore[reportExplicitAny]
        try:
            self.setUp()
            yield
        finally:
            # self.tearDown()
            self.options = original_options
