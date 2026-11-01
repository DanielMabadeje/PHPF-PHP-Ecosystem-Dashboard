---
title: Open source on GitHub
sidebar_position: 3
---

How is PHP written, packaged and licensed in public repositories? These pages cover Composer adoption, licences, how often a project's
`LICENSE` file and its `composer.json` agree, and which PHP projects have been running the longest.

<Alert status="info">
These pages show published results from the PHP Foundation SIG research (<a href="https://github.com/ThePHPF/SIG-ambassadors/pull/40">SIG-ambassadors, PR #40</a>).
The studies were run by their authors against the GitHub dataset and API, and the dashboard's query runner does not refresh them.
Each page says which report it comes from.
</Alert>

- [Composer adoption](/open-source/composer): how many PHP repositories ship a `composer.json`, and how they lay it out
- [Licences](/open-source/licences): which licences PHP projects use, permissive or copyleft
- [LICENSE file vs composer.json](/open-source/licence-declarations): how often the two places a project states its licence agree
- [Long-running PHP projects](/open-source/longevity): which projects have been going the longest and are still maintained

**What these pages have in common**

- **Snapshots.** The BigQuery `github_repos` dataset behind two of the studies was last loaded in October 2025, so its figures describe that moment.
- **Only licensed projects.** GitHub's licence data only covers projects it recognises as open source. Projects without a licence are absent from the licence
  figures, not counted as zero.
- **Repositories, not usage.** A repository is not a deployment. These figures say how PHP code is published, not how widely it runs.
