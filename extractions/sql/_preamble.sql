-- Shared declarations, prepended to totals.sql and platforms.sql by run_httparchive.sh.
-- Hand-written list: reproduces the Web Almanac figures (see extraction doc).
DECLARE php_apps ARRAY<STRING> DEFAULT [
  'WordPress', 'WooCommerce', 'Drupal', 'Joomla', 'Magento', 'PrestaShop',
  'OpenCart', 'TYPO3 CMS', 'Shopware', 'Concrete CMS', 'MODX', 'Contao',
  'SPIP', 'OXID eShop', 'CS Cart', 'osCommerce', 'X-Cart', 'CubeCart',
  'Pimcore', 'Silverstripe', 'ExpressionEngine', 'DataLife Engine',
  '1C-Bitrix', 'Grav', 'Statamic', 'Textpattern CMS', 'e107', 'XOOPS',
  'Weebly', 'Shoptet', 'Craft CMS', 'Square Online',
  'Gnuboard', 'October CMS', 'Backdrop', 'ProcessWire', 'EC-CUBE',
  'Hyva Themes', 'Gambio', 'EasyDigitalDownloads'];
DECLARE not_a_platform ARRAY<STRING> DEFAULT [
  'Cart Functionality', 'Google Analytics Enhanced eCommerce'];
DECLARE builder_commerce ARRAY<STRING> DEFAULT [
  'Squarespace Commerce', 'Wix eCommerce'];
