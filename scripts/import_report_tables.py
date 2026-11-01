#!/usr/bin/env python3
"""Import published result tables from the SIG-ambassadors research reports into data/reports/*.csv.

The BigQuery queries in extractions/ are refreshed by scripts/run_httparchive.sh. The other studies (GitHub API,
Stack Exchange, Packagist) are run by their authors, and their results are published as markdown tables in
ThePHPF/SIG-ambassadors, PR #40. This script reads those tables so numbers are never retyped by hand.

Usage:
    python3 scripts/import_report_tables.py /path/to/SIG-ambassadors/subgroup-research [--commit <sha>]

It fails loudly if a report's table changes shape (section name or row count), instead of importing garbage.
Standard library only.
"""
import argparse, csv, datetime, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "reports"


def clean(cell):
    cell = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", cell)  # markdown link -> text
    return cell.replace("**", "").replace("`", "").strip()


def link_of(cell):
    m = re.search(r"\]\(([^)]*)\)", cell)
    return m.group(1) if m else ""


def num(cell):
    s = clean(cell).replace(",", "").replace("%", "").replace("*", "").strip()
    if s in ("", "—", "-"):
        return ""
    return float(s) if "." in s else int(s)


def read_tables(path):
    lines = pathlib.Path(path).read_text().split("\n")
    out, sec, i = [], "", 0
    while i < len(lines):
        if lines[i].startswith("#"):
            sec = lines[i].strip("# ").strip()
        if lines[i].startswith("|") and i + 1 < len(lines) and re.match(r"^\|[\s:|-]+\|$", lines[i + 1]):
            j = i + 2
            while j < len(lines) and lines[j].startswith("|"):
                j += 1
            header = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            rows = [[c.strip() for c in r.strip().strip("|").split("|")] for r in lines[i + 2:j]]
            out.append((sec, header, rows))
            i = j
            continue
        i += 1
    return out


def table(path, section, nth=0, expect_rows=None):
    hits = [t for t in read_tables(path) if t[0] == section]
    if len(hits) <= nth:
        sys.exit(f"ERROR: section {section!r} (table #{nth}) not found in {path}")
    sec, header, rows = hits[nth]
    if expect_rows is not None and len(rows) != expect_rows:
        sys.exit(f"ERROR: {path.name} / {section!r}: expected {expect_rows} rows, found {len(rows)}. "
                 f"The report changed shape; update the importer before importing.")
    return header, rows


def write(name, header, rows, meta, source, section, note=""):
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)
    meta[name] = {"rows": len(rows), "source_file": source, "section": section, "note": note}
    print(f"  wrote data/reports/{name} ({len(rows)} rows)")


def quarter_start(year, q):
    return f"{int(year)}-{(int(q) - 1) * 3 + 1:02d}-01"


# Families as defined in the licences extraction (raw-data/extractions/github-repos-licences.md).
PERMISSIVE = {"MIT", "BSD-3-Clause", "Apache-2.0", "BSD-2-Clause", "Unlicense", "CC0-1.0", "ISC"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("research_dir", help="path to the subgroup-research folder of a SIG-ambassadors checkout")
    ap.add_argument("--commit", default="", help="commit sha of that checkout, recorded as provenance")
    a = ap.parse_args()
    R = pathlib.Path(a.research_dir) / "reports"
    if not R.is_dir():
        sys.exit(f"ERROR: {R} is not a directory")
    meta_path = OUT / "metadata.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    files = {}

    # ---- Composer adoption
    h, rows = table(R / "composer-adoption.md", "Results", expect_rows=7)
    out = []
    for r in rows:
        share_text = clean(r[2])
        out.append([clean(r[0]), num(r[1]), num(share_text.split("%")[0] + "%"), share_text.split("%", 1)[1].strip() or "of total", clean(r[3])])
    write("composer_adoption.csv", ["metric", "repositories", "reported_share_pct", "reported_share_of", "meaning"], out, files,
          "reports/composer-adoption.md", "Results")

    # ---- Licences
    h, rows = table(R / "php-licences.md", "Families", expect_rows=3)
    write("php_licence_families.csv", ["family", "projects", "reported_share_pct"],
          [[clean(r[0]), num(r[1]), num(r[2])] for r in rows if clean(r[0]) != "total"], files,
          "reports/php-licences.md", "Families")
    h, rows = table(R / "php-licences.md", "Every licence", expect_rows=16)
    out = []
    for r in rows:
        name = clean(r[0])
        if name.lower() == "total":
            continue
        out.append([name, "permissive" if name in PERMISSIVE else "copyleft", num(r[1]), num(r[2]), num(r[3])])
    write("php_licences.csv", ["licence", "family", "php_main_language_repos", "reported_share_pct", "contains_any_php_repos"], out, files,
          "reports/php-licences.md", "Every licence", "family follows the report's definition (permissive list in the extraction)")

    # ---- LICENSE file vs composer.json
    h, rows = table(R / "licence-file-vs-composer.md", "The answer", expect_rows=5)
    write("licence_vs_composer_outcomes.csv", ["outcome", "reported_share_pct"], [[clean(r[0]), num(r[1])] for r in rows], files,
          "reports/licence-file-vs-composer.md", "The answer")
    h, rows = table(R / "licence-file-vs-composer.md", "By licence", expect_rows=16)
    out = [[clean(r[0]), num(r[1]), num(r[2]), num(r[3]), num(r[4]), num(r[5]), num(r[6]), num(r[7])]
           for r in rows if re.match(r"^[a-z0-9.-]+$", clean(r[0]))]
    if len(out) != 15:
        sys.exit(f"ERROR: expected 15 licence rows in 'By licence', parsed {len(out)}")
    write("licence_vs_composer_by_licence.csv",
          ["licence", "population", "sampled", "agree_pct", "disagree_pct", "no_composer_json_pct", "no_license_key_pct", "not_spdx_pct"],
          out, files, "reports/licence-file-vs-composer.md", "By licence", "weighted total row dropped")
    h, rows = table(R / "licence-file-vs-composer.md", "By popularity", expect_rows=4)
    write("licence_vs_composer_by_stars.csv",
          ["stars_band", "population", "sampled", "agree_pct", "disagree_pct", "no_composer_json_pct", "no_license_key_pct"],
          [[clean(r[0]), num(r[1]), num(r[2]), num(r[3]), num(r[4]), num(r[5]), num(r[6])] for r in rows], files,
          "reports/licence-file-vs-composer.md", "By popularity")

    # ---- Stack Overflow share of questions
    so = R / "php-share-of-stackoverflow.md"
    q_rows, y_rows = [], []
    for nth, source in ((0, "Stack Exchange Data Explorer"), (1, "BigQuery snapshot")):
        # tables #0/#1 are the Data Explorer quarter/year tables, #2/#3 the BigQuery ones
        pass
    h, rows = table(so, "By quarter", 0, 73)
    for r in rows:
        label = clean(r[0]); partial = "*" in label
        y, q = re.match(r"(\d{4}) Q(\d)", label).groups()
        q_rows.append(["Stack Exchange Data Explorer", int(y), int(q), quarter_start(y, q), num(r[1]), num(r[2]), num(r[3]), "yes" if partial else "no"])
    h, rows = table(so, "By quarter", 1, 43)
    for r in rows:
        label = clean(r[0]); partial = "*" in label
        y, q = re.match(r"(\d{4}) Q(\d)", label).groups()
        q_rows.append(["BigQuery snapshot", int(y), int(q), quarter_start(y, q), num(r[1]), num(r[2]), num(r[3]), "yes" if partial else "no"])
    write("so_questions_quarterly.csv",
          ["source", "year", "quarter", "quarter_start", "php_questions", "total_questions", "reported_share_pct", "partial_period"],
          q_rows, files, "reports/php-share-of-stackoverflow.md", "By quarter (both tables)", "two sources; they diverge after 2021 Q3")
    h, rows = table(so, "By year", 0, 19)
    for r in rows:
        label = clean(r[0]); y_rows.append(["Stack Exchange Data Explorer", int(label.replace("*", "").strip()), num(r[1]), num(r[3]), num(r[5]), "yes" if "*" in label else "no"])
    h, rows = table(so, "By year", 1, 11)
    for r in rows:
        label = clean(r[0]); y_rows.append(["BigQuery snapshot", int(label.replace("*", "").strip()), num(r[1]), num(r[2]), num(r[3]), "yes" if "*" in label else "no"])
    write("so_questions_yearly.csv", ["source", "year", "php_questions", "total_questions", "reported_share_pct", "partial_period"],
          y_rows, files, "reports/php-share-of-stackoverflow.md", "By year (both tables)")

    # ---- Longevity
    lo = R / "top-long-running-php.md"
    h, ten = table(lo, "The ten", expect_rows=10)
    what = {int(clean(r[0])): clean(r[5]) for r in ten}
    h, rows = table(lo, "The first hundred", expect_rows=100)
    out = []
    for r in rows:
        k = int(clean(r[0]))
        out.append([k, clean(r[1]), link_of(r[1]), num(r[2]), clean(r[3]), clean(r[4]), num(r[5]), clean(r[6]), num(r[7]), what.get(k, "")])
    write("top_long_running_php.csv",
          ["rank", "project", "url", "stars", "started", "start_source", "months_running", "last_push", "score", "what_it_is"],
          out, files, "reports/top-long-running-php.md", "The first hundred (+ descriptions from 'The ten')")

    stamp = datetime.date.today().isoformat()
    for name, m in files.items():
        m.update({"imported_on": stamp, "sig_ambassadors_commit": a.commit or "unrecorded",
                  "origin": "ThePHPF/SIG-ambassadors PR #40, subgroup-research/" + m["source_file"]})
        meta[name] = m
    meta_path.write_text(json.dumps(meta, indent=2, sort_keys=True) + "\n")
    print(f"metadata -> {meta_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
