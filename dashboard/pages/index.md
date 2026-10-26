---
title: PHP Ecosystem Dashboard
---

How much of the web runs on PHP, and what kind of PHP? This dashboard answers that with public data, so anyone can check the numbers and the method behind them.

It is built for the PHP Foundation SIG research effort. Every figure comes from a SQL query kept in the
[project repository](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard), run against a named crawl date.
Nothing is computed when you open a page, so the numbers are the same for everyone.

## What is here

- [PHP applications on the web](/php-applications): how many sites run WordPress, Drupal, Magento and other
  PHP-based applications, how that has changed since 2021, and how the answer depends on how "PHP" is defined.

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