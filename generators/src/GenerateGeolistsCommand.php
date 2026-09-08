<?php declare(strict_types=1);
namespace TurboLabIt\zzfirewall;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Helper\ProgressBar;
use Symfony\Component\HttpClient\HttpClient;
use TurboLabIt\BaseCommand\Command\AbstractBaseCommand;


#[AsCommand(name: 'GenerateGeolists')]
class GenerateGeolistsCommand extends AbstractBaseCommand
{
    const CLI_ARG_MAXMIND_KEY = "maxmind-key";

    const MAXMIND_DB_DOWNLOAD_URL_KEY_PLACEHOLDER = 'YOUR_LICENSE_KEY';
    const MAXMIND_DB_DOWNLOAD_URL = 
      'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=YOUR_LICENSE_KEY&suffix=zip';
    const MAXMIND_DB_LOCAL_FILENAME = 'maxmind.zip';

    const REMOTE_ZIP_ROOT_DIR_STARTS_WITH = 'GeoLite2-Country-CSV';
    const CSV_IP_NAME   = 'GeoLite2-Country-Blocks-IPv4.csv';
    const CSV_GEO_NAME  = 'GeoLite2-Country-Locations-en.csv';

    const IP_NETWORK    = 'network';
    const GEONAME_ID    = 'geoname_id';
    const COUNTRY_CODE  = 'country_iso_code';
    const COUNTRY_NAME  = 'country_name';
    const FILEMAP_NAME  = 'filename';

    const COUNTRY_FILEMAP = [

      // === ARAB.TXT ===
      // Yemen, Iraq, Saudi Arabia
      "YE" => "arab.txt", "IQ" => "arab.txt", "SA" => "arab.txt",
      // Iran, Syria, Armenia
      "IR" => "arab.txt", "SY" => "arab.txt", "AM" => "arab.txt",
      // Jordan, Lebanon, Kuwait
      "JO" => "arab.txt", "LB" => "arab.txt", "KW" => "arab.txt",
      // Oman, Qatar, Bahrain
      "OM" => "arab.txt", "QA" => "arab.txt", "BH" => "arab.txt",
      // United Arab Emirates, Turkey, Azerbaijan
      "AE" => "arab.txt", "TR" => "arab.txt", "AZ" => "arab.txt",
      // Afghanistan, Pakistan, Palestine
      "AF" => "arab.txt", "PK" => "arab.txt", "PS" => "arab.txt",

      // === CHINA.TXT ===
      // China, Laos, Mongolia
      "CN" => "china.txt", "LA" => "china.txt", "MN" => "china.txt",
      // Bhutan, Vietnam, Thailand
      "BT" => "china.txt", "VN" => "china.txt", "TH" => "china.txt",
      // Singapore
      "SG" => "china.txt",

      // === INDIA.TXT ===
      // Bangladesh, Sri Lanka, India
      "BD" => "india.txt", "LK" => "india.txt", "IN" => "india.txt",
      // Nepal, Indonesia, Cambodia
      "NP" => "india.txt", "ID" => "india.txt", "KH" => "india.txt",

      // === KOREA.TXT ===
      // South Korea, North Korea
      "KR" => "korea.txt", "KP" => "korea.txt",

      // === RUSSIA.TXT ===
      // Uzbekistan, Kazakhstan, Kyrgyzstan
      "UZ" => "russia.txt", "KZ" => "russia.txt", "KG" => "russia.txt",
      // Latvia (in europe.txt as well)
      "LV" => ["russia.txt", "europe.txt"],
      // Russia
      "RU" => "russia.txt",

      // ===  SOUTH-AMERICA.TXT ===
      // Brasil, Argentina, Chile
      "BR" => "south-america.txt", "AR" => "south-america.txt", "CL" => "south-america.txt",
      // Colombia, Peru, Venezuela
      "CO" => "south-america.txt", "PE" => "south-america.txt", "VE" => "south-america.txt",

      // ===  ITALY.TXT ===
      // in europe.txt as well
      'IT' => ['italy.txt', 'europe.txt'],

      // ===  SWITZERLAND.TXT ===
      // in europe.txt as well
      'CH' => ['switzerland.txt', 'europe.txt'],

      // ===  EUROPE.TXT ===
      // every nation from Portugal to the Ukrainian border: the EU, the UK, EFTA, the Balkans and
      // the microstates. Ukraine, Belarus, Moldova, Russia and Turkey are out.
      // IT, CH and LV are above, with both their files: a code can appear only once in this array
      // (PHP silently keeps the last duplicate key), so a country in two lists gets an array of files
      // Portugal, Spain, Andorra
      "PT" => "europe.txt", "ES" => "europe.txt", "AD" => "europe.txt",
      // Gibraltar, France, Monaco
      "GI" => "europe.txt", "FR" => "europe.txt", "MC" => "europe.txt",
      // Belgium, Netherlands, Luxembourg
      "BE" => "europe.txt", "NL" => "europe.txt", "LU" => "europe.txt",
      // United Kingdom, Ireland, Isle of Man
      "GB" => "europe.txt", "IE" => "europe.txt", "IM" => "europe.txt",
      // Jersey, Guernsey, Iceland
      "JE" => "europe.txt", "GG" => "europe.txt", "IS" => "europe.txt",
      // Norway, Svalbard and Jan Mayen, Faroe Islands
      "NO" => "europe.txt", "SJ" => "europe.txt", "FO" => "europe.txt",
      // Denmark, Sweden, Finland
      "DK" => "europe.txt", "SE" => "europe.txt", "FI" => "europe.txt",
      // Åland Islands, Estonia, Lithuania
      "AX" => "europe.txt", "EE" => "europe.txt", "LT" => "europe.txt",
      // Germany, Austria, Liechtenstein
      "DE" => "europe.txt", "AT" => "europe.txt", "LI" => "europe.txt",
      // San Marino, Vatican City, Malta
      "SM" => "europe.txt", "VA" => "europe.txt", "MT" => "europe.txt",
      // Poland, Czechia, Slovakia
      "PL" => "europe.txt", "CZ" => "europe.txt", "SK" => "europe.txt",
      // Hungary, Romania, Bulgaria
      "HU" => "europe.txt", "RO" => "europe.txt", "BG" => "europe.txt",
      // Greece, Cyprus, Albania
      "GR" => "europe.txt", "CY" => "europe.txt", "AL" => "europe.txt",
      // ex-Yugoslavia: Slovenia, Croatia, Bosnia and Herzegovina
      "SI" => "europe.txt", "HR" => "europe.txt", "BA" => "europe.txt",
      // ex-Yugoslavia: Serbia, Montenegro, North Macedonia
      "RS" => "europe.txt", "ME" => "europe.txt", "MK" => "europe.txt",
      // ex-Yugoslavia: Kosovo
      "XK" => "europe.txt"
    ];

    // 💡 https://github.com/TurboLabIt/php-symfony-basecommand/blob/main/src/Traits/CliOptionsTrait.php
    protected bool $allowDryRunOpt      = true;
    protected bool $allowNoDownloadOpt  = true;

    protected array $arrIp              = [];
    protected array $arrCountry         = [];
    protected array $arrFilesToWrite    = [];


    protected function configure() : void
    {
        parent::configure();
        $this->addArgument(
            static::CLI_ARG_MAXMIND_KEY, InputArgument::REQUIRED,
            'The MaxMind key to use for API access to the GeoIP database'
        );
    }


    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // https://github.com/TurboLabIt/php-symfony-basecommand/blob/main/src/Command/AbstractBaseCommand.php
        parent::execute($input, $output);

        $this
          ->fxTitle("Setting up the temp dir...")
          ->deleteWorkingDir()

          ->fxTitle("Downloading...")
          ->downloadGeoIPFile()

          ->fxTitle("Unzipping...")
          ->unzipGeoIPFile()

          ->fxTitle("Loading IP CSV...")
          ->loadIpCsv()

          ->fxTitle("Loading Country CSV...")
          ->loadCountryCsv()

          ->fxTitle("Assigning IPs to the corresponding geofiles...")
          ->addIpsToFiles()

          ->fxTitle("Writing each file...")
          ->writeFileMap()
        ;

        return $this->endWithSuccess();
    }


    protected function downloadGeoIPFile() : self
    {
      $httpClient   = HttpClient::create();
      $downloadUrl  = str_replace(
        static::MAXMIND_DB_DOWNLOAD_URL_KEY_PLACEHOLDER,
        $this->getCliArgument(static::CLI_ARG_MAXMIND_KEY),
        static::MAXMIND_DB_DOWNLOAD_URL
      );

      $this->fxInfo("Downloading from ##" . $downloadUrl . "##");

      if( !$this->isDownloadAllowed() ) {
        return $this;
      }

      $response = $httpClient->request('GET', $downloadUrl);
      $zipData  = $response->getContent();

      $zipPath = $this->getTempWorkingDirFile(static::MAXMIND_DB_LOCAL_FILENAME);
      file_put_contents($zipPath, $zipData);

      $this->fxOK("File downloaded in ##" . $this->getTempWorkingDirFile(static::MAXMIND_DB_LOCAL_FILENAME) . "##");

      return $this;
    }


    protected function unzipGeoIPFile() : self
    {
      $zipPath = $this->getTempWorkingDirFile(static::MAXMIND_DB_LOCAL_FILENAME);

      $oZip = new \ZipArchive();
      $oZip->open($zipPath);
      $oZip->extractTo( $this->getTempWorkingDirPath() );
      $oZip->close();

      $this->fxOK("File unzipped in ##" . $this->getCsvDirPath() . "##");

      return $this;
    }


    protected function loadIpCsv() : self
    {
      $csvFilePath = $this->getCsvDirPath() . static::CSV_IP_NAME;
      $me = $this;
      $this->processCsv($csvFilePath, function($arrRow) use($me) {
        $me->arrIp[] = [
          static::IP_NETWORK  => $arrRow[static::IP_NETWORK],
          static::GEONAME_ID  => $arrRow[static::GEONAME_ID]
        ];
      });

      return $this;
    }


    protected function loadCountryCsv() : self
    {
      $csvFilePath = $this->getCsvDirPath() . static::CSV_GEO_NAME;
      $me = $this;
      $this->processCsv($csvFilePath, function($arrRow) use($me) {

        $name = $arrRow[static::COUNTRY_NAME];
        $code = $arrRow[static::COUNTRY_CODE];

        if( !array_key_exists($code, static::COUNTRY_FILEMAP) ) {
          return true;
        }

        $id = $arrRow[static::GEONAME_ID];
        $me->arrCountry[$id] = [
          static::COUNTRY_NAME  => $name,
          static::COUNTRY_CODE  => $code,
          // always an array: a country can feed more than one file (IT: italy.txt and europe.txt)
          static::FILEMAP_NAME  => (array)static::COUNTRY_FILEMAP[$code]
        ];
      });

      return $this;
    }


    protected function getCsvDirPath() : string
    {
      $arrFiles = scandir( $this->getTempWorkingDirPath() );
      foreach($arrFiles as $fileName) {

        $fullPath = $this->getTempWorkingDirFile($fileName) . DIRECTORY_SEPARATOR;

        if( !is_dir($fullPath) || stripos($fileName, static::REMOTE_ZIP_ROOT_DIR_STARTS_WITH) !== 0 ) {
          continue;
        }

        return $fullPath;
      }
    }


    protected function addIpsToFiles() : self
    {
      $progressBar = new ProgressBar($this->output, count($this->arrIp));
      $progressBar->start();

      foreach($this->arrIp as &$oneIp) {

        $countryId = $oneIp[static::GEONAME_ID];

        if( !array_key_exists($countryId, $this->arrCountry) ) {

          $progressBar->advance();
          continue;
        }

        $this->addEntryToFile($oneIp, $this->arrCountry[$countryId]);
        $progressBar->advance();
      }

      $progressBar->finish();
      $this->io->newLine(2);

      return $this;
    }


    protected function addEntryToFile($arrIp, $arrCountry) : self
    {
      $countryId = $arrIp[static::GEONAME_ID];

      foreach($arrCountry[static::FILEMAP_NAME] as $fileName) {

        if( !array_key_exists($fileName, $this->arrFilesToWrite) ) {
          $this->arrFilesToWrite[$fileName] = [];
        }

        if( !array_key_exists($countryId, $this->arrFilesToWrite[$fileName]) ) {

          $this->arrFilesToWrite[$fileName][$countryId] = [

            static::COUNTRY_NAME  => $arrCountry[static::COUNTRY_NAME],
            static::IP_NETWORK    => []
          ];
        }

        $this->arrFilesToWrite[$fileName][$countryId][static::IP_NETWORK][] = $arrIp[static::IP_NETWORK];
      }

      return $this;
    }


    protected function writeFileMap() : self
    {
      $progressBar = new ProgressBar($this->output, count($this->arrFilesToWrite));
      $progressBar->start();

      foreach($this->arrFilesToWrite as $fileName => $arrData) {

        $txtData =
          '## ☣ DO NOT EDIT DIRECTLY! This file is auto-generated by GenerateGeolistsCommand.php' . PHP_EOL . PHP_EOL;

        foreach($arrData as $arrCountry) {

          $txtData .= '## 🗺 ' . $arrCountry[static::COUNTRY_NAME] . PHP_EOL;

          foreach($arrCountry[static::IP_NETWORK] as $ip) {
            $txtData .= $ip . PHP_EOL;
          }

          $txtData .= PHP_EOL;
        }

        $txtData = trim($txtData) . PHP_EOL;

        $path = __DIR__ . '/../../lists/geos/' . $fileName;

        if( $this->isNotDryRun() ) {
          file_put_contents($path, $txtData);
        }

        $progressBar->advance();
      }

      $progressBar->finish();
      $this->io->newLine(2);

      return $this;
    }
}
