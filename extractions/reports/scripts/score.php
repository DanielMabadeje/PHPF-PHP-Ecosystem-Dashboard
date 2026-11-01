<?php
// Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
// Source: subgroup-research/raw-data/extractions/github-php-longevity.md, code block #2.
// What it is: PHP: ranks the collected repositories by months running x log10(stars).
// Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
declare(strict_types=1);

/**
 * Ranks the collected population by how long each project has been running
 * and is still running.
 *
 *   score = months * log10(stars)
 *
 * The logarithm is load-bearing. Stars span three orders of magnitude across
 * this population while months span less than one, so a plain months * stars
 * is decided by the star count and stops measuring longevity.
 *
 * Months run from the earliest date available for the project. The GitHub
 * creation date is a poor floor for anything older than GitHub, so the first
 * commit from bigquery-public-data.github_repos.commits is preferred wherever
 * the export covers the repository.
 */

const ACTIVE_WITHIN_MONTHS = 12;
const DAYS_PER_MONTH       = 30.44;
const KEEP                 = 1000;

const POPULATION   = 'php_repos.json';
const FIRST_COMMIT = 'first_commits.csv';   // the BigQuery export, optional
const OUTPUT       = 'php_longevity_ranked.json';

// The query already excludes the epoch and the future, but a commit date sitting
// exactly on its lower bound is the bound showing through, not a real date.
const FLOOR = '1995-01-02';

$utc   = new DateTimeZone('UTC');
$today = new DateTimeImmutable('now', $utc);

function monthsBetween(DateTimeImmutable $from, DateTimeImmutable $to): float
{
    return (float) $from->diff($to)->days / DAYS_PER_MONTH;
}

/** Streams the export so a 160 MB file never lands in memory whole. */
function loadFirstCommits(string $path, array $wanted): array
{
    if (!is_readable($path)) {
        fwrite(STDERR, "no {$path}, falling back to GitHub creation dates
");
        return [];
    }

    $handle  = fopen($path, 'r');
    $columns = fgetcsv($handle, escape: '');
    $found   = [];

    while (($row = fgetcsv($handle, escape: '')) !== false) {
        $record = array_combine($columns, $row);
        if (isset($wanted[$record['repo_name']])) {
            $found[$record['repo_name']] = $record['first_commit'];
        }
    }
    fclose($handle);

    return $found;
}

$population = json_decode(file_get_contents(POPULATION), true);
$byName     = array_column($population, null, 'full_name');
$firstCommit = loadFirstCommits(FIRST_COMMIT, $byName);

$ranked    = [];
$archived  = 0;
$forks     = 0;
$quiet     = 0;
$corrected = 0;

foreach ($population as $repo) {
    // Archived is finished, not long running.
    if ($repo['archived']) {
        $archived++;
        continue;
    }
    // A fork inherits its parent's history and would duplicate it.
    if ($repo['fork']) {
        $forks++;
        continue;
    }

    $pushed = new DateTimeImmutable($repo['pushed_at']);
    if (monthsBetween($pushed, $today) > ACTIVE_WITHIN_MONTHS) {
        $quiet++;
        continue;
    }

    $start  = new DateTimeImmutable($repo['created_at']);
    $source = 'github';

    $commit = $firstCommit[$repo['full_name']] ?? null;
    if ($commit !== null && substr($commit, 0, 10) > FLOOR) {
        $candidate = new DateTimeImmutable($commit, $utc);
        if ($candidate < $start) {
            $start  = $candidate;
            $source = 'commit';
            $corrected++;
        }
    }

    $months = monthsBetween($start, $today);
    $stars  = (int) $repo['stargazers_count'];

    $ranked[] = $repo + [
        'start'        => $start->format('Y-m-d'),
        'start_source' => $source,
        'months'       => (int) round($months),
        'score'        => round($months * log10((float) $stars), 1),
    ];
}

usort($ranked, static fn (array $a, array $b): int => $b['score'] <=> $a['score']);

file_put_contents(OUTPUT,
    json_encode(array_slice($ranked, 0, KEEP), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

fwrite(STDERR, sprintf(
    "collected %d | archived %d | forks %d | quiet over %d months %d | eligible %d
",
    count($population), $archived, $forks, ACTIVE_WITHIN_MONTHS, $quiet, count($ranked)
));
fwrite(STDERR, sprintf(
    "start date from first commit for %d of them, from GitHub creation for %d
",
    $corrected, count($ranked) - $corrected
));
