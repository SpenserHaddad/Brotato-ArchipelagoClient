import unittest

from ..options import NumWaveCaps
from ..wave_caps import get_wave_cap_info


class TestBrotatoWaveCaps(unittest.TestCase):
    def test_get_wave_cap_info_option_one(self):
        option = NumWaveCaps(1)
        expected_wave_access = {
            0: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        }
        num_items, wave_access = get_wave_cap_info(option)
        self.assertEqual(num_items, 0)
        for num_items_needed, waves_accessible in wave_access.items():
            expected_waves_accessible = expected_wave_access[num_items_needed]
            self.assertListEqual(list(waves_accessible), expected_waves_accessible)

    def test_get_wave_cap_info_option_two(self):
        option = NumWaveCaps(2)
        expected_wave_access = {
            0: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            1: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        }
        num_items, wave_access = get_wave_cap_info(option)
        self.assertEqual(num_items, 1)
        for num_items_needed, waves_accessible in wave_access.items():
            expected_waves_accessible = expected_wave_access[num_items_needed]
            self.assertListEqual(list(waves_accessible), expected_waves_accessible)

    def test_get_wave_cap_info_option_four(self):
        option = NumWaveCaps(4)
        expected_wave_access = {
            0: [1, 2, 3, 4, 5],
            1: [6, 7, 8, 9, 10],
            2: [11, 12, 13, 14, 15],
            3: [16, 17, 18, 19, 20],
        }
        num_items, wave_access = get_wave_cap_info(option)
        self.assertEqual(num_items, 3)
        for num_items_needed, waves_accessible in wave_access.items():
            expected_waves_accessible = expected_wave_access[num_items_needed]
            self.assertListEqual(list(waves_accessible), expected_waves_accessible)
