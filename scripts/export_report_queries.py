#!/usr/bin/env python3
"""Copy the SQL and PHP code blocks out of the SIG-ambassadors extraction docs into extractions/reports/, verbatim.

The studies behind the 'report' pages were run by their authors. This script vendors their queries and scripts into this repository so the
results can be reproduced, or checked, without the PR. Nothing is rewritten: each file is the code block as published, plus a header comment
saying where it came from.

Usage:  python3 scripts/export_report_queries.py /path/to/SIG-ambassadors/subgroup-research [--commit <sha>]
Standard library only. Fails if a doc no longer has the expected code block.
"""
import argparse, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "extractions" / "reports"

# (extraction doc, index of the code fence in that doc, output file, what it is)
EXPORTS = [
    ("github-repos.md",            0, "github_repos_composer.sql",          "BigQuery: Composer adoption across public PHP repositories"),
    ("github-repos-licences.md",   0, "github_repos_licences.sql",          "BigQuery: licences of PHP repositories"),
    ("github-php-longevity.md",    1, "github_longevity_first_commits.sql", "BigQuery: earliest credible commit per repository (input to score.php)"),
    ("stackoverflow-bigquery.md",  0, "stackoverflow_bigquery.sql",         "BigQuery: PHP share of Stack Overflow questions by quarter"),
    ("stackoverflow-sede.md",      0, "stackoverflow_sede.sql",             "T-SQL for data.stackexchange.com (run by hand in the browser)"),
    ("github-php-repositories.md", 0, "scripts/collect.php",                "PHP, GitHub API: collects PHP repositories with at least 1,000 stars"),
    ("github-php-longevity.md",    2, "scripts/score.php",                  "PHP: ranks the collected repositories by months running x log10(stars)"),
    ("licence-file-vs-composer.md",0, "scripts/discrepancy.php",            "PHP, GitHub API: LICENSE file vs composer.json"),
    ("package-first-two-years.md", 0, "scripts/cohort.php",                 "PHP, Packagist and ecosyste.ms: first two years of a package"),
]


def fences(path):
    return [(m.group(1), m.group(2)) for m in re.finditer(r"```(\w*)\n(.*?)```", pathlib.Path(path).read_text(), re.S)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("research_dir")
    ap.add_argument("--commit", default="unrecorded")
    a = ap.parse_args()
    ext = pathlib.Path(a.research_dir) / "raw-data" / "extractions"
    if not ext.is_dir():
        sys.exit(f"ERROR: {ext} not found")
    for doc, idx, name, what in EXPORTS:
        blocks = fences(ext / doc)
        if idx >= len(blocks):
            sys.exit(f"ERROR: {doc} has {len(blocks)} code blocks, expected at least {idx + 1}")
        lang, body = blocks[idx]
        want = "php" if name.endswith(".php") else "sql"
        if lang != want:
            sys.exit(f"ERROR: {doc} block #{idx} is '{lang or 'untyped'}', expected '{want}'. The doc changed shape; check before exporting.")
        head = [f"Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit {a.commit}).",
                f"Source: subgroup-research/raw-data/extractions/{doc}, code block #{idx}.",
                f"What it is: {what}.",
                "Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md."]
        dest = OUT / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        if name.endswith(".php"):
            lines = body.split("\n")
            assert lines[0].startswith("<?php"), f"{doc}: PHP block does not start with <?php"
            text = lines[0] + "\n" + "\n".join("// " + h for h in head) + "\n" + "\n".join(lines[1:])
        else:
            text = "\n".join("-- " + h for h in head) + "\n" + body
        dest.write_text(text)
        print(f"  wrote extractions/reports/{name} ({body.count(chr(10))} lines)")


if __name__ == "__main__":
    main()
