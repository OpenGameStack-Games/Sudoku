#!/usr/bin/env python3
"""Unit tests validating GitHub Actions workflow files for common parser pitfalls."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS_DIR = REPO_ROOT / ".github" / "workflows"


class WorkflowValidationTests(unittest.TestCase):
    def test_workflows_exist_and_have_no_utf8_bom(self) -> None:
        workflows = sorted(WORKFLOWS_DIR.glob("*.yml"))
        self.assertGreaterEqual(len(workflows), 3, "Expected ci.yml, android_release.yml, and web_release.yml")
        for wf in workflows:
            raw = wf.read_bytes()
            self.assertFalse(
                raw.startswith(b"\xef\xbb\xbf"),
                f"{wf.name} must not contain a UTF-8 BOM",
            )

    def test_workflows_do_not_reference_secrets_context_in_if_conditionals(self) -> None:
        # GitHub Actions rejects workflows that reference `secrets.*` directly in `if:` expressions.
        if_secrets_pattern = re.compile(r"^\s*if\s*:.*\bsecrets\.", re.MULTILINE)
        for wf in sorted(WORKFLOWS_DIR.glob("*.yml")):
            text = wf.read_text(encoding="utf-8")
            match = if_secrets_pattern.search(text)
            self.assertIsNone(
                match,
                f"{wf.name} references `secrets.` inside an `if:` expression "
                "(bind to `env:` first and check `env.<VAR> != ''`).",
            )

    def test_ogs_manifests_exist_valid_json_and_no_bom(self) -> None:
        ogs_stack_path = REPO_ROOT / "ogs_stack.json"
        ogs_config_path = REPO_ROOT / "ogs_config.json"
        legacy_stack_path = REPO_ROOT / "stack.json"

        self.assertFalse(
            legacy_stack_path.exists(),
            "Legacy stack.json must not exist at repository root; use ogs_stack.json instead.",
        )

        for path in (ogs_stack_path, ogs_config_path):
            self.assertTrue(path.exists(), f"{path.name} must exist at the repository root")
            raw = path.read_bytes()
            self.assertFalse(
                raw.startswith(b"\xef\xbb\xbf"),
                f"{path.name} must not contain a UTF-8 BOM",
            )
            parsed = json.loads(raw.decode("utf-8"))
            self.assertIsInstance(
                parsed,
                dict,
                f"{path.name} must be a valid JSON dictionary",
            )


if __name__ == "__main__":
    unittest.main()
