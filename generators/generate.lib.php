<?php
function getJsonIpList(string $endpoint) : stdClass
{
    $txtData = file_get_contents($endpoint);

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