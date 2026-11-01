#!/usr/bin/env python3
"""Check that a fresh run of the vendored BigQuery queries still reproduces the numbers the dashboard publishes.

    ./scripts/run_report_query.sh all run
    python3 scripts/verify_report_tables.py            # compares data/reports/raw/*.csv with data/reports/*.csv

Exits non-zero if any count differs. It compares; it never overwrites the published tables.
"""
import argparse, csv, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
bad = 0


def rows(p):
    with open(p, newline="") as f:
        return list(csv.DictReader(f))


def check(label, got, want):
    global bad
    ok = str(got) == str(want)
    if not ok:
        bad += 1
    print(f"  {'ok  ' if ok else 'DIFF'} {label}: fresh {got} vs published {want}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", default=str(ROOT / "data" / "reports" / "raw"))
    ap.add_argument("--tables-dir", default=str(ROOT / "data" / "reports"))
    a = ap.parse_args()
    raw, tab = pathlib.Path(a.raw_dir), pathlib.Path(a.tables_dir)

    p = raw / "github_repos_licences.csv"
    if p.exists():
        print("licences (php_licences.csv)")
        pub = {r["licence"].lower(): r for r in rows(tab / "php_licences.csv")}  # the SQL returns ids in lowercase
        fresh = {r["license"].lower(): r for r in rows(p)}
        check("licences present", sorted(fresh), sorted(pub))
        for k in sorted(set(fresh) & set(pub)):
            check(f"{k} main-language repos", int(fresh[k]["php_is_the_main_language"]), int(pub[k]["php_main_language_repos"]))
            check(f"{k} contains-any-php repos", int(fresh[k]["contains_any_php"]), int(pub[k]["contains_any_php_repos"]))
    p = raw / "stackoverflow_bigquery.csv"
    if p.exists():
        print("Stack Overflow, BigQuery snapshot (so_questions_quarterly.csv)")
        pub = {r["quarter_start"]: r for r in rows(tab / "so_questions_quarterly.csv") if r["source"] == "BigQuery snapshot"}
        fresh = {r["quarter"]: r for r in rows(p)}
        check("quarters covered", len(fresh), len(pub))
        for k in sorted(set(fresh) & set(pub)):
            check(f"{k} php/total", f"{fresh[k]['php_questions']}/{fresh[k]['total_questions']}", f"{pub[k]['php_questions']}/{pub[k]['total_questions']}")
    p = raw / "github_repos_composer.csv"
    if p.exists():
        print("Composer adoption (composer_adoption.csv)")
        f = rows(p)[0]
        pub = {r["metric"]: int(r["repositories"]) for r in rows(tab / "composer_adoption.csv")}
        at_root = int(f["uses_composer"]) - int(f["manifest_not_at_root"])
        for metric, val in (("PHP repositories (total)", int(f["total_php_repos"])), ("Ships a composer.json", int(f["uses_composer"])),
                            ("No composer.json", int(f["no_composer"])), ("Manifest at repository root", at_root),
                            ("Manifest outside the root", int(f["manifest_not_at_root"])), ("vendor/ committed to Git", int(f["vendor_committed"])),
                            ("vendor/ committed, no manifest", int(f["vendor_committed_without_manifest"]))):
            check(metric, val, pub[metric])
    print("\nALL REPRODUCED" if not bad else f"\n{bad} difference(s): the data or the report changed; look before updating data/reports/")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
