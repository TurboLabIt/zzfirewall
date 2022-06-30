<?php
/**
 * Banner
 * ======
 */
echo "⚙️ Adding banner..." . PHP_EOL;
$txtBlacklist  = '## ☠️ WARNING! This file was AUTOGENERATED by zzfirewall on ' .  date('Y-m-d H:i:s') . ' - Do not edit directly!';
$txtBlacklist .= PHP_EOL . '## See: https://github.com/TurboLabIt/zzfirewall/';


/**
 * Writing the file...
 * ===================
 */
$txtBlacklist .= PHP_EOL . PHP_EOL;
const BLACKLIST_OUT_PATH = '/usr/local/turbolab.it/zzfirewall/lists/autogen/blacklist.txt';
echo "⚙️ Writing the file to " . BLACKLIST_OUT_PATH . "..." . PHP_EOL;
file_put_contents(BLACKLIST_OUT_PATH, $txtBlacklist);

echo PHP_EOL . "✅ " .basename(__FILE__, '.php') . " is DONE" . PHP_EOL;

