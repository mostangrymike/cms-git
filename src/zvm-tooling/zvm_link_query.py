"""Direct-screen, fixed-command observation of CP minidisk links."""
import re
import time


def link_query_command(vaddr):
    if not isinstance(vaddr, str) or not re.fullmatch(r"[0-9A-Fa-f]{3}", vaddr):
        raise ValueError("Use one three-digit hexadecimal virtual address")
    return "CP QUERY LINKS " + vaddr.upper()


class LinkQuery:
    MAX_PAGES = 64

    def __init__(self, session):
        self.session = session

    def query(self, vaddr, timeout=30):
        s = self.session
        if not s.allow_query_links:
            return {"ok": False, "message": "Link observation requires --allow-query-links",
                    "replacement_safe": False, "link_query_is_lock": False,
                    "host_operations_performed": False}
        try:
            command = link_query_command(vaddr)
            if type(timeout) is not int or not 1 <= timeout <= 60:
                raise ValueError("Link query timeout must be 1..60 seconds")
        except ValueError as exc:
            return {"ok": False, "message": str(exc), "replacement_safe": False,
                    "link_query_is_lock": False, "host_operations_performed": False}

        def work():
            from zvm_commands import RunnerBridge, ready_rc
            from zvm_mcp import host_display

            if s.em is None:
                raise RuntimeError("Connect and inspect/login before querying links")
            deadline = time.monotonic() + timeout
            before = s.snapshot()
            if before["state"] != "cms_ready" or not RunnerBridge.input_field(before):
                raise RuntimeError("CP QUERY LINKS requires CMS Ready and a verified empty command field")
            s.command("MoveCursor(22,0)")
            check = s.snapshot()
            if (check["state"] != "cms_ready" or not RunnerBridge.input_field(check)
                    or check["cursor"] != {"row": 23, "column": 1, "protected": False}):
                raise RuntimeError("CMS command field changed; link query was not submitted")
            s.command('String("' + command + '")')
            s.command("Ascii")
            s.command("Enter")

            pages = []
            previous = check
            echo_seen = False
            while time.monotonic() < deadline:
                s.command("Ascii")
                remaining = max(1, min(3, int(deadline - time.monotonic())))
                output_event = s._wait_output(remaining)
                current = s.snapshot()
                fresh = output_event or host_display(current) != host_display(previous)
                if fresh:
                    pages.append(current)
                    if len(pages) > self.MAX_PAGES:
                        raise RuntimeError("CP QUERY LINKS exceeded the 64-page capture limit")
                    matching_echoes = [i for i, row in enumerate(current["rows"])
                                       if row.strip().upper() == command]
                    if matching_echoes:
                        echo_seen = True
                    previous = current

                    if current["state"] in {"more", "holding"}:
                        if not echo_seen:
                            raise RuntimeError("Paging appeared before the CP query echo; refusing to advance")
                        # A single Enter releases the observed output hold; no
                        # timed scrolling or speculative key repeats.
                        s.command("Enter")
                        continue

                    ready_rows = [i for i, row in enumerate(current["rows"])
                                  if ready_rc(row) is not None]
                    echo_rows = [i for i, row in enumerate(current["rows"])
                                 if row.strip().upper() == command]
                    if (current["state"] == "cms_ready" and echo_seen and ready_rows
                            and echo_rows and max(ready_rows) > max(echo_rows)):
                        return {"vaddr": vaddr.upper(), "command": command,
                                "pages": pages, "page_count": len(pages),
                                "output_complete": True, "completion_observed": True,
                                "cms_command_complete": None, "replacement_safe": False,
                                "link_query_is_lock": False,
                                "host_operations_performed": False}
                    if current["state"] not in {"cms_ready", "more", "holding"}:
                        raise RuntimeError("Unexpected terminal state during CP QUERY LINKS")
            raise TimeoutError("No fresh echoed CP QUERY LINKS result followed by CMS Ready")

        return s._run("query_links", work, timeout + 2)
