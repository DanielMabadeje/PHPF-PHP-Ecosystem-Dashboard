---
title: PHP Ecosystem Dashboard
---

How much of the web runs on PHP, and what kind of PHP? This dashboard answers that with public data, so anyone can check the numbers and the method behind them.

It is built for the PHP Foundation SIG research effort. The pages come from two kinds of source, and each page says which:

- **Refreshed pages** (platforms, families) come from SQL queries kept in the
  [project repository](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard), run against named crawl dates.
- **Report pages** (marked `report` in the sidebar) show published results from SIG studies. The studies were run by their authors and
  are not refreshed by this project's query runner.

Nothing is computed when you open a page, so the numbers are the same for everyone.

## What is here

- [PHP applications on the web](/php-applications): how many sites run WordPress, Drupal, Magento and other
  PHP-based applications, how that has changed since 2021, and how the answer depends on how "PHP" is defined.
- [Platforms and versions](/php-usage): platform trends, add-on adoption, and which versions of WordPress, Drupal and Magento sites run.
- [Open source on GitHub](/open-source): Composer adoption, licences, how often a LICENSE file and `composer.json` agree, and the longest-running PHP projects.
- [Developer community](/community): PHP's share of Stack Overflow questions over time.
- [Glossary](/glossary): what "flagged as PHP", "named application", "crawl" and the other terms mean, with a worked example.

## How to read the charts

- **Sites** means the home page of a website (the "root page"), as seen by the HTTP Archive's mobile crawl.
  It does not count every page of every site.
- **Crawl** labels (for example `2025-07`) are the month the HTTP Archive crawled the web. Data is only as
  fresh as the latest crawl included, not today's web.
- Technology is detected from what a site sends to the browser (scripts, headers, markup). Sites that hide
  their technology are counted as not using it, so figures are a floor, not an exact count.

## Where the data comes from

[HTTP Archive](https://httparchive.org), queried through Google BigQuery. Technology detection is by
[Wappalyzer](https://www.wappalyzer.com/); its rules change over time, so some movement between crawls reflects
better detection rather than real change.

## Credits

The queries and the research method behind this dashboard were written and documented by
[GianfriAur](https://github.com/GianfriAur/) as part of the PHP Foundation SIG research
([SIG-ambassadors, PR #40](https://github.com/ThePHPF/SIG-ambassadors/pull/40)). This project adapts them: it runs the same
questions for several crawl dates and publishes the results as a dashboard. Any errors in that adaptation are ours, not theirs.