<?php
// Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
// Source: subgroup-research/raw-data/extractions/package-first-two-years.md, code block #0.
// What it is: PHP, Packagist and ecosyste.ms: first two years of a package.
// Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
declare(strict_types=1);

/**
 * Builds the study cohort and collects the first 104 weeks of downloads.
 *
 * Success is measured on two axes rather than assigned by category, because no
 * field in the registry reliably separates a library from a tool: PHPUnit is a
 * tool with 122,193 dependents, and symfony/var-dumper is a library that ships
 * a binary. Each package is placed on both axes and graded by the better of the
 * two, so a project adopted as a dependency and one installed directly can both
 * count as used.
 */

const PKG_API  = 'https://packages.ecosyste.ms/api/v1/registries/packagist.org/packages';
const STATS    = 'https://packagist.org/packages/%s/stats/all.json?average=daily&from=%s&to=%s';
const UA       = 'sig-ambassadors-research';

const WINDOW_FROM = '2013-01-01';   // Packagist daily download history starts here
const WINDOW_TO   = '2024-10-01';   // leaves 104 observable weeks
const WEEKS       = 104;
const PER_GRADE   = 400;
const PARALLEL    = 8;

// Platform requirements and bridges to other ecosystems, not PHP packages.
const PSEUDO = '/^(php$|ext-|lib-|composer-|bower-asset\/|npm-asset\/)/';

/**
 * Fetches urls in parallel and hands each decoded response to $consume.
 * Nothing is accumulated: a full pass over the registry does not fit in memory.
 */
function fetchEach(array $urls, callable $consume, int $parallel = PARALLEL): void
{
    foreach (array_chunk($urls, $parallel, true) as $chunk) {
        $multi = curl_multi_init();
        $handles = [];
        foreach ($chunk as $key => $url) {
            $h = curl_init($url);
            curl_setopt_array($h, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_USERAGENT      => UA,
                CURLOPT_TIMEOUT        => 30,
                CURLOPT_FOLLOWLOCATION => true,
            ]);
            curl_multi_add_handle($multi, $h);
            $handles[$key] = $h;
        }
        do {
            curl_multi_exec($multi, $running);
            curl_multi_select($multi, 0.5);
        } while ($running > 0);

        foreach ($handles as $key => $h) {
            $body = curl_multi_getcontent($h);
            $consume($key, $body === false ? null : json_decode($body, true));
            curl_multi_remove_handle($multi, $h);
            curl_close($h);
            unset($body);
        }
        curl_multi_close($multi);
        gc_collect_cycles();
    }
}

/** Only the fields the study uses, so the pool stays small. */
function slim(array $p): array
{
    return [
        'name'                     => $p['name'],
        'first_release_published_at' => $p['first_release_published_at'] ?? null,
        'repository_url'           => $p['repository_url'] ?? null,
        'dependent_packages_count' => $p['dependent_packages_count'] ?? 0,
        'downloads'                => $p['downloads'] ?? 0,
        'versions_count'           => $p['versions_count'] ?? 0,
    ];
}

function ageMonths(string $firstRelease): float
{
    $start = new DateTimeImmutable(substr($firstRelease, 0, 10));
    $now   = new DateTimeImmutable('2026-10-20');
    return max(1.0, (float) $start->diff($now)->days / 30.44);
}

function eligible(array $p): bool
{
    $first = $p['first_release_published_at'] ?? null;
    if ($first === null || preg_match(PSEUDO, (string) $p['name'])) {
        return false;
    }
    $date = substr($first, 0, 10);
    return $date >= WINDOW_FROM && $date <= WINDOW_TO && !empty($p['repository_url']);
}

/** A on either axis wins; C requires failing both and still having been maintained. */
function grade(array $p): ?string
{
    $dep  = (int) ($p['dependent_packages_count'] ?? 0);
    $rate = (int) (($p['downloads'] ?? 0) / ageMonths($p['first_release_published_at']));
    $vers = (int) ($p['versions_count'] ?? 0);

    if ($dep >= 25   || $rate >= 100000) return 'A';
    if ($dep >= 3    || $rate >= 1000)   return 'B';
    if ($dep === 0 && $rate < 100 && $vers >= 10) return 'C';
    return null;   // the gaps between grades are left out on purpose
}

// ---------------------------------------------------------------- cohort
fwrite(STDERR, "building the pool\n");
$pool = [];
foreach (['dependent_packages_count', 'downloads'] as $sort) {
    $urls = [];
    for ($page = 1; $page <= 15; $page++) {
        $urls[] = PKG_API . "?sort={$sort}&order=desc&per_page=100&page={$page}";
    }
    fetchEach($urls, function ($_, $batch) use (&$pool) {
        foreach ($batch ?? [] as $p) {
            $pool[$p['name']] = slim($p);
        }
    });
    fwrite(STDERR, "  after {$sort}: " . count($pool) . "\n");
}
// The low grade is dense everywhere, so random pages reach it.
$urls = [];
for ($i = 0; $i < 25; $i++) {
    $urls[] = PKG_API . '?per_page=100&page=' . random_int(1, 5180);
}
fetchEach($urls, function ($_, $batch) use (&$pool) {
    foreach ($batch ?? [] as $p) {
        $pool[$p['name']] = slim($p);
    }
});
fwrite(STDERR, '  pool: ' . count($pool) . "\n");

$graded = ['A' => [], 'B' => [], 'C' => []];
foreach ($pool as $p) {
    if (!eligible($p)) continue;
    $g = grade($p);
    if ($g !== null && count($graded[$g]) < PER_GRADE) {
        $p['grade'] = $g;
        $graded[$g][] = $p;
    }
}
foreach ($graded as $g => $list) {
    fwrite(STDERR, sprintf("  grade %s: %d\n", $g, count($list)));
}

// ---------------------------------------------------------------- downloads
$cohort = array_merge($graded['A'], $graded['B'], $graded['C']);
fwrite(STDERR, 'collecting ' . count($cohort) . " download series\n");

$urls = [];
foreach ($cohort as $i => $p) {
    $from = new DateTimeImmutable(substr($p['first_release_published_at'], 0, 10));
    $to   = $from->add(new DateInterval('P' . (WEEKS * 7) . 'D'));
    $urls[$i] = sprintf(STATS, $p['name'], $from->format('Y-m-d'), $to->format('Y-m-d'));
}

$result = [];
fetchEach($urls, function ($i, $payload) use (&$result, $cohort) {
    $p = $cohort[$i];
    $daily = $payload['values'] ?? null;
    if ($daily === null) return;
    $values = array_values($daily)[0] ?? [];
    $weekly = [];
    for ($w = 0; $w < WEEKS; $w++) {
        $slice = array_slice($values, $w * 7, 7);
        if (count($slice) < 7) break;
        $weekly[] = array_sum($slice);
    }
    $result[] = [
        'name'    => $p['name'],
        'grade'   => $p['grade'],
        't0'      => substr($p['first_release_published_at'], 0, 10),
        'repo'    => $p['repository_url'],
        'deps'    => (int) ($p['dependent_packages_count'] ?? 0),
        'rate'    => (int) (($p['downloads'] ?? 0) / ageMonths($p['first_release_published_at'])),
        'versions'=> (int) ($p['versions_count'] ?? 0),
        'weekly'  => $weekly,
    ];
});
file_put_contents('cohort_downloads.json', json_encode($result));
fwrite(STDERR, 'collected ' . count($result) . " series with " . WEEKS . " weeks each\n");
