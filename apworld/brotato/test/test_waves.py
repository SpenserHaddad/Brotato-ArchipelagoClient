from unittest import TestCase

from ..options import WavesPerCheck
from ..waves import get_wave_for_each_item, get_waves_with_checks


class TestWavesWithChecks(TestCase):
    def test_get_waves_with_checks(self):
        # There's only 20 valid values for "Waves per Check" option, so we can test every possible value here.
        waves_with_checks_pairs: list[tuple[int, list[int]]] = [
            (
                1,
                [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
            ),
            (2, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]),
            (3, [3, 6, 9, 12, 15, 18]),
            (4, [4, 8, 12, 16, 20]),
            (5, [5, 10, 15, 20]),
            (6, [6, 12, 18]),
            (7, [7, 14]),
            (8, [8, 16]),
            (9, [9, 18]),
            (10, [10, 20]),
            (11, [11]),
            (12, [12]),
            (13, [13]),
            (14, [14]),
            (15, [15]),
            (16, [16]),
            (17, [17]),
            (18, [18]),
            (19, [19]),
            (20, [20]),
        ]

        for waves_per_check, expected_waves_with_checks in waves_with_checks_pairs:
            with self.subTest(waves_per_check=waves_per_check):
                waves_with_checks = get_waves_with_checks(WavesPerCheck(waves_per_check))
                self.assertListEqual(waves_with_checks, expected_waves_with_checks)


class TestGetWaveForEachItem(TestCase):
    def test_get_wave_for_each_item(self):
        pass
