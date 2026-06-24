#!/usr/bin/env python3
"""Unit tests for the pure geometry in eww/place.py (no GUI / no gi)."""
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "eww"))
from place import seed, clamp  # noqa: E402

# A representative output + the clock footprint.
OW, OH, W, H = 2400, 1500, 660, 360


class TestSeed(unittest.TestCase):
    """anchor + inward offset -> top-left pixel, matching eww :geometry semantics."""

    def test_top_left_is_offset_from_origin(self):
        self.assertEqual(seed("top left", 100, 50, OW, OH, W, H), (100, 50))

    def test_top_right_offsets_inward_from_right_edge(self):
        # 2400 - 120 - 660 = 1620
        self.assertEqual(seed("top right", 120, 320, OW, OH, W, H), (1620, 320))

    def test_center_right_is_vertically_centered(self):
        # x: 2400 - 60 - 660 = 1680 ; y: (1500-360)/2 = 570
        self.assertEqual(seed("center right", 60, 0, OW, OH, W, H), (1680, 570))

    def test_bottom_left_offsets_up_from_bottom(self):
        # y: 1500 - 0 - 360 = 1140
        self.assertEqual(seed("bottom left", 0, 0, OW, OH, W, H), (0, 1140))

    def test_center_single_token_is_dead_center(self):
        # x: (2400-660)/2 = 870 ; y: (1500-360)/2 = 570
        self.assertEqual(seed("center", 0, 0, OW, OH, W, H), (870, 570))

    def test_bottom_center_combines_h_center_and_bottom(self):
        # x: 870 + 10 = 880 ; y: 1500 - 20 - 360 = 1120
        self.assertEqual(seed("bottom center", 10, 20, OW, OH, W, H), (880, 1120))


class TestClamp(unittest.TestCase):
    """Keep the clock fully on-screen."""

    def test_inside_unchanged(self):
        self.assertEqual(clamp(100, 50, OW, OH, W, H), (100, 50))

    def test_negative_clamped_to_origin(self):
        self.assertEqual(clamp(-10, -5, OW, OH, W, H), (0, 0))

    def test_beyond_far_edge_clamped_to_max(self):
        # max x = 2400-660 = 1740 ; max y = 1500-360 = 1140
        self.assertEqual(clamp(5000, 5000, OW, OH, W, H), (1740, 1140))

    def test_output_narrower_than_clock_clamps_to_origin(self):
        self.assertEqual(clamp(300, 50, 400, 1500, W, H), (0, 50))


if __name__ == "__main__":
    unittest.main()
