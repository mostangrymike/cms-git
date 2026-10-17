"""Offline tests for the fixed-command, direct-screen CP QUERY LINKS tool."""
import unittest
from unittest.mock import Mock

from zvm_link_query import LinkQuery, link_query_command
from zvm_mcp import Session
from test_zvm_mcp import FakeEmulator, buffer, screen


class PagingEmulator(FakeEmulator):
    def __init__(self, paged=True):
        super().__init__(screen("Ready;"))
        self.buffer = buffer({0: "20", 1759: "00", 1899: "20"})
        self.queued = ""
        self.paged = paged
        self.page = 0
        self.rows = screen("Ready;")

    def exec_command(self, action):
        text = action.decode()
        if text.startswith('String("'):
            self.queued = text[8:-2]
        elif text == "Enter":
            self.assert_query()
            if self.page == 0:
                self.page = 1
                self.rows = screen("Ready;", "")
                self.rows[8] = self.queued.ljust(80)
                self.rows[9] = "USERA 0191 W".ljust(80)
                self.rows[23] = "MORE..." if self.paged else "Ready; T=0.01/0.01"
                if not self.paged:
                    self.rows[10] = "Ready; T=0.01/0.01".ljust(80)
            elif self.page == 1 and self.paged:
                self.page = 2
                self.rows = screen("Ready;", "")
                self.rows[8] = self.queued.ljust(80)
                self.rows[9] = "USERB 0192 W".ljust(80)
                self.rows[10] = "Ready; T=0.02/0.02".ljust(80)
        elif text == "Clear" and self.page == 1:
            self.page = 2
            self.rows = screen("Ready;", "")
            self.rows[8] = self.queued.ljust(80)
            self.rows[9] = "USERB 0192 W".ljust(80)
            self.rows[10] = "Ready; T=0.02/0.02".ljust(80)
        result = super().exec_command(action)
        if text == "Snap(Status)":
            result.data = [b"U F U C(127.0.0.1) I 2 24 80 22 0 0x0 -"]
        return result

    def assert_query(self):
        assert self.queued == "CP QUERY LINKS 191", self.queued


class LinkQueryTests(unittest.TestCase):
    def test_command_accepts_only_a_three_digit_hex_address(self):
        self.assertEqual(link_query_command("19a"), "CP QUERY LINKS 19A")
        for value in ("*", "0191", "19", "191; CP IPL CMS", " cp query links 191 "):
            with self.subTest(value=value), self.assertRaises(ValueError):
                link_query_command(value)

    def test_disabled_and_invalid_queries_never_connect(self):
        factory = Mock(side_effect=AssertionError("must remain offline"))
        session = Session(factory=factory)
        self.assertFalse(session.link_query.query("191")["ok"])
        session.allow_query_links = True
        for value in ("*", "0191", "191; CP IPL CMS"):
            self.assertFalse(session.link_query.query(value)["ok"])
        factory.assert_not_called()

    def test_direct_query_captures_all_pages_and_waits_for_ready_boundary(self):
        fake = PagingEmulator()
        session = Session(factory=lambda: fake, allow_query_links=True)
        session.connect("0200@")
        result = session.link_query.query("191")
        self.assertTrue(result["ok"], result)
        self.assertEqual(result["command"], "CP QUERY LINKS 191")
        self.assertEqual(result["page_count"], 2)
        self.assertTrue(result["output_complete"])
        self.assertTrue(result["completion_observed"])
        self.assertIsNone(result["cms_command_complete"])
        self.assertFalse(result["replacement_safe"])
        self.assertFalse(result["link_query_is_lock"])
        self.assertEqual(sum(call == "Enter" for call in fake.calls), 2)
        self.assertFalse(any("Transfer(" in call for call in fake.calls))
        session.disconnect()

    def test_unpaged_query_requires_echo_and_ready_after_output(self):
        fake = PagingEmulator(paged=False)
        session = Session(factory=lambda: fake, allow_query_links=True)
        session.connect("0200@")
        result = session.link_query.query("191")
        self.assertTrue(result["ok"], result)
        self.assertEqual(result["page_count"], 1)
        session.disconnect()


if __name__ == "__main__":
    unittest.main()
