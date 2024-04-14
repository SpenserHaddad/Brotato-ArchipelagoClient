from test.bases import WorldTestBase
from typing import ClassVar

from .. import BrotatoWorld


class BrotatoTestBase(WorldTestBase):
    game = "Brotato"
    world: BrotatoWorld  # type: ignore
    player: ClassVar[int] = 1
