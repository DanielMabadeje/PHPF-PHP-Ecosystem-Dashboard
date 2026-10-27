-- Adapted from the queries by GianfriAur (https://github.com/GianfriAur/), ThePHPF/SIG-ambassadors PR #40:
-- https://github.com/ThePHPF/SIG-ambassadors/pull/40
-- Shared lists, prepended to queries flagged "1" in scripts/queries.sh.
-- Queries using this must continue the WITH clause (start with ", name AS (") or
-- start directly with SELECT, and join the lists with `, params` in their FROM.
-- No DECLARE / CREATE TEMP: those make BigQuery treat the query as a script, and
-- `bq` does not return a script's final SELECT as the CSV we need.
WITH params AS (
  SELECT
    -- Hand-written list: reproduces the Web Almanac figures (see the extraction doc).
    [
      'WordPress', 'WooCommerce', 'Drupal', 'Joomla', 'Magento', 'PrestaShop',
      'OpenCart', 'TYPO3 CMS', 'Shopware', 'Concrete CMS', 'MODX', 'Contao',
      'SPIP', 'OXID eShop', 'CS Cart', 'osCommerce', 'X-Cart', 'CubeCart',
      'Pimcore', 'Silverstripe', 'ExpressionEngine', 'DataLife Engine',
      '1C-Bitrix', 'Grav', 'Statamic', 'Textpattern CMS', 'e107', 'XOOPS',
      'Weebly', 'Shoptet', 'Craft CMS', 'Square Online',
      'Gnuboard', 'October CMS', 'Backdrop', 'ProcessWire', 'EC-CUBE',
      'Hyva Themes', 'Gambio', 'EasyDigitalDownloads'
    ] AS php_apps,
    ['Cart Functionality', 'Google Analytics Enhanced eCommerce'] AS not_a_platform,
    ['Squarespace Commerce', 'Wix eCommerce'] AS builder_commerce
)