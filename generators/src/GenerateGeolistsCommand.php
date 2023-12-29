<?php declare(strict_types=1);
namespace TurboLabIt\ZzfirewallGenerators;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Helper\ProgressBar;
use TurboLabIt\PhpSymfonyBasecommand\Command\AbstractBaseCommand;
use Symfony\Component\HttpClient\HttpClient;
use League\Csv\Reader;


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
      // Latvia
      "LV" => "russia.txt",
      // Russia
      "RU" => "russia.txt"
    ];

    // 💡 https://github.com/TurboLabIt/php-symfony-basecommand/blob/main/src/Traits/CliOptionsTrait.php
    protected bool $allowDryRunOpt      = true;
    protected bool $allowNoDownloadOpt  = true;

    protected array $arrIp              = [];
    protected array $arrCountry         = [];
    protected array $arrFilesToWrite    = [];


    public function __construct(array $arrConfig = [])
    {
        parent::__construct($arrConfig);
    }


    protected function configure()
    {
        parent::configure();
        $this->addArgument(static::CLI_ARG_MAXMIND_KEY, InputArgument::REQUIRED, 'The MaxMind key to use for API access to the GeoIP database');
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
          static::FILEMAP_NAME  => static::COUNTRY_FILEMAP[$code]
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
      $countryId  = $arrIp[static::GEONAME_ID];
      $fileName   = $arrCountry[static::FILEMAP_NAME];

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
