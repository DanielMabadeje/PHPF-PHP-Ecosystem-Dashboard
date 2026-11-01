<?php
// Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
// Source: subgroup-research/raw-data/extractions/github-php-repositories.md, code block #0.
// What it is: PHP, GitHub API: collects PHP repositories with at least 1,000 stars.
// Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
declare(strict_types=1);

/**
 * Collects every repository GitHub classifies as PHP with at least 1,000 stars.
 *
 * A search returns at most 1,000 results however many matched, so the population
 * is gathered in star windows. Keep each one well under the cap: these counts only
 * go up, and a window that reaches 1,000 drops rows without reporting an error.
 */

const WINDOWS = [
    'language:PHP stars:1000..1999',
    'language:PHP stars:2000..2999',
    'language:PHP stars:3000..4999',
    'language:PHP stars:>=5000',
];

const FIELDS = [
    'full_name', 'stargazers_count', 'created_at', 'pushed_at',
    'archived', 'fork', 'language', 'description', 'html_url',
    'forks_count', 'open_issues_count',
];

const PER_PAGE   = 100;
const THROTTLE   = 7;  // anonymous callers get 10 search requests a minute
const MAX_RETRIES = 4;

function fetch(string $url): array
{
    $context = stream_context_create(['http' => [
        'header'        => "Accept: application/vnd.github+json\r\n"
                         . "User-Agent: sig-ambassadors-research\r\n",
        'timeout'       => 30,
        'ignore_errors' => true,
    ]]);

    for ($attempt = 1; $attempt <= MAX_RETRIES; $attempt++) {
        $body = @file_get_contents($url, false, $context);
        if ($body !== false) {
            $decoded = json_decode($body, true);
            if (isset($decoded['items'])) {
                return $decoded;
            }
            // Rate limited or otherwise refused: $http_response_header holds the status.
            fwrite(STDERR, sprintf("  attempt %d: %s\n", $attempt,
                $decoded['message'] ?? 'unexpected response'));
        } else {
            fwrite(STDERR, sprintf("  attempt %d: request failed\n", $attempt));
        }
        sleep(20);
    }

    fwrite(STDERR, "gave up on {$url}\n");
    exit(1);
}

$rows   = [];
$totals = [];

foreach (WINDOWS as $window) {
    $page = 1;
    while (true) {
        $url = 'https://api.github.com/search/repositories?' . http_build_query([
            'q'        => $window,
            'sort'     => 'stars',
            'order'    => 'desc',
            'per_page' => PER_PAGE,
            'page'     => $page,
        ]);

        $result = fetch($url);
        $items  = $result['items'];
        $totals[$window] = $result['total_count'];

        fwrite(STDERR, sprintf("%s page %d: %d of %d\n",
            $window, $page, count($items), $result['total_count']));

        foreach ($items as $repo) {
            $row = [];
            foreach (FIELDS as $field) {
                $row[$field] = $repo[$field] ?? null;
            }
            $row['license'] = $repo['license']['spdx_id'] ?? null;

            // Keyed by name, so a repository gaining a star mid-collection and
            // appearing in two windows is stored once rather than twice.
            $rows[$repo['full_name']] = $row;
        }

        if (count($items) < PER_PAGE) {
            break;
        }
        $page++;
        sleep(THROTTLE);
    }
    sleep(THROTTLE);
}

file_put_contents('php_repos.json',
    json_encode(array_values($rows), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

$sum = array_sum($totals);
fwrite(STDERR, sprintf("\ncollected %d distinct repositories, windows sum to %d\n",
    count($rows), $sum));

// The windows partition the population, so these two must agree. A short sum
// means a window hit the 1,000 cap; a long one means the boundaries overlap.
if (count($rows) !== $sum) {
    fwrite(STDERR, "WARNING: the windows do not partition the population\n");
    exit(1);
}
