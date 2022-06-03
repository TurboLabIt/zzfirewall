<?php
/**
 * Banner
 * ======
 */
echo "⚙️ Adding banner..." . PHP_EOL;
$txtWhitelist  = '## ☠️ WARNING! This file is AUTOGENERATED by zzfirewall! Do not edit!';
$txtWhitelist .= PHP_EOL . '## See: https://github.com/TurboLabIt/zzfirewall/';


/**
 * Allow connections from Google...
 * ================================
 */
const GOOGLE_WHITELIST_URL = 'https://www.gstatic.com/ipranges/goog.json';
echo "⚙️ Adding from Google " . GOOGLE_WHITELIST_URL . "..." . PHP_EOL;
$txtWhitelist .= PHP_EOL . PHP_EOL . '## 🔎 Allow from Google - ' . GOOGLE_WHITELIST_URL . PHP_EOL;
$txtGoogle = file_get_contents(GOOGLE_WHITELIST_URL);

if($txtGoogle === false) {
  die("⚠️ Download from " . GOOGLE_WHITELIST_URL . " FAILED! Aborting!");
}

$arrGoogle = json_decode($txtGoogle);

if( !is_object($arrGoogle) ) {
  die("⚠️ json_decode from " . GOOGLE_WHITELIST_URL . " FAILED! Aborting!");
}

$txtGoogle = "";
foreach($arrGoogle->prefixes as $oneItem) {

  if( empty($oneItem->ipv4Prefix) ) {
    continue;
  }

  $txtGoogle .= $oneItem->ipv4Prefix . PHP_EOL;
}

$txtWhitelist .= $txtGoogle;

/**
 * Writing the file...
 * ===================
 */
const WHITELIST_OUT_PATH = '/usr/local/turbolab.it/zzfirewall/lists/autogen/';

$filePath = WHITELIST_OUT_PATH . 'whitelist.txt';
echo "⚙️ Writing the file to " . $filePath . "..." . PHP_EOL;
file_put_contents($filePath, $txtWhitelist);

$filePath = WHITELIST_OUT_PATH . 'google.txt';
echo "⚙️ Writing the file to " . $filePath . "..." . PHP_EOL;
file_put_contents($filePath, $txtGoogle);

echo PHP_EOL . "✅ " . basename(__FILE__, '.php') . " is DONE" . PHP_EOL;

