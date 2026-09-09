<?php
function getJsonIpList(string $endpoint) : stdClass
{
    // PHP sends no User-Agent by default, and api.github.com answers 403 to a request without one
    $context = stream_context_create(['http' => ['header' => "User-Agent: zzfirewall (+https://github.com/TurboLabIt/zzfirewall)\r\n"]]);
    $txtData = file_get_contents($endpoint, false, $context);

    if( $txtData === false ) {
        die("⚠️ Download from $endpoint FAILED! Aborting!");
    }

    $oData = json_decode($txtData);

    if( !is_object($oData) ) {
        die("⚠️ json_decode from $endpoint FAILED! Aborting!");
    }

    return $oData;
}


function getGoogleIpList(string $endpoint) : array
{
    $oData = getJsonIpList($endpoint);

    if( empty($oData->prefixes) ) {
        die("⚠️ Something's wrong with $endpoint : ->prefixes is empty!");
    }

    $arrIps = [];
    foreach($oData->prefixes as $oneItem) {

        if( empty($oneItem->ipv4Prefix) ) {
            continue;
        }

        $arrIps[] = $oneItem->ipv4Prefix;
    }

    if( empty($arrIps) ) {
        die("⚠️ Something's wrong with $endpoint : the generated list is empty!");
    }

    return $arrIps;
}


function getRipeIpList(string $asn) : array
{
    $endpoint = 'https://stat.ripe.net/data/announced-prefixes/data.json?resource=' . $asn;
    $oData = getJsonIpList($endpoint);

    if( empty($oData->data->prefixes) ) {
        die("⚠️ Something's wrong with $endpoint : ->data->prefixes is empty!");
    }

    $arrIps = [];
    foreach($oData->data->prefixes as $oneItem) {

        if( empty($oneItem->prefix) ) {
            continue;
        }

        // Skip IPv6
        if( str_contains($oneItem->prefix, ':') ) {
            continue;
        }

        $arrIps[] = $oneItem->prefix;
    }

    if( empty($arrIps) ) {
        die("⚠️ Something's wrong with $endpoint : the generated list is empty!");
    }

    return $arrIps;
}


/**
 * https://api.github.com/meta : one list per service. $key picks the one we want, "hooks" being
 * the addresses GitHub delivers webhooks from
 */
function getGithubIpList(string $endpoint, string $key) : array
{
    $oData = getJsonIpList($endpoint);

    if( empty($oData->$key) || !is_array($oData->$key) ) {
        die("⚠️ Something's wrong with $endpoint : ->$key is empty!");
    }

    $arrIps = [];
    foreach($oData->$key as $oneItem) {

        if( empty($oneItem) ) {
            continue;
        }

        // Skip IPv6
        if( str_contains($oneItem, ':') ) {
            continue;
        }

        $arrIps[] = $oneItem;
    }

    if( empty($arrIps) ) {
        die("⚠️ Something's wrong with $endpoint : the generated list is empty!");
    }

    return $arrIps;
}


/**
 * https://ip-ranges.atlassian.com/ : every range is tagged with the products using it and with its
 * direction. "egress" is what Atlassian connects out from (webhooks...), "ingress" is what it listens on
 */
function getAtlassianIpList(string $endpoint, string $product) : array
{
    $oData = getJsonIpList($endpoint);

    if( empty($oData->items) || !is_array($oData->items) ) {
        die("⚠️ Something's wrong with $endpoint : ->items is empty!");
    }

    $arrIps = [];
    foreach($oData->items as $oneItem) {

        if( empty($oneItem->cidr) || empty($oneItem->direction) || empty($oneItem->product) ) {
            continue;
        }

        if( !in_array('egress', $oneItem->direction) || !in_array($product, $oneItem->product) ) {
            continue;
        }

        // Skip IPv6
        if( str_contains($oneItem->cidr, ':') ) {
            continue;
        }

        $arrIps[] = $oneItem->cidr;
    }

    if( empty($arrIps) ) {
        die("⚠️ Something's wrong with $endpoint : the generated list is empty!");
    }

    return $arrIps;
}
