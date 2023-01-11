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
    
    const DIR_WORK = '/tmp/zzfirewall-generate-geolists/';

    const REMOTE_ZIP_ROOT_DIR_STARTS_WITH = 'GeoLite2-Country-CSV';
    const CSV_IP_NAME   = 'GeoLite2-Country-Blocks-IPv4.csv';
    const CSV_GEO_NAME  = 'GeoLite2-Country-Locations-en.csv';

    const IP_NETWORK    = 'network';
    const GEONAME_ID    = 'geoname_id';
    const COUNTRY_CODE  = 'country_iso_code';
    const COUNTRY_NAME  = 'country_name';
    const FILEMAP_NAME  = 'filename';

    const COUNTRY_FILEMAP = [
      // Turkey
      "TR"  => "arab.txt",
      // United Arab Emirates
      "AE"  => "arab.txt"
    ];

    // https://github.com/TurboLabIt/php-symfony-basecommand/blob/main/src/Traits/CliOptionsTrait.php
    protected bool $allowDryRunOpt = true;

    protected array $arrIp      = [];
    protected array $arrCountry = [];

    
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
          ->fxTitle("Downloading...")
          ->downloadGeoIPFile();

        $this->fxOK("File downloaded in ##" . $this->getGeoIPZipPath() . "##");

        $this
          ->fxTitle("Unzipping...")
          ->unzipGeoIPFile();

        $this->fxOK("File unzipped in ##" . $this->getCsvDirPath() . "##");

        $this
          ->fxTitle("Loading IP CSV...")
          ->loadIpCsv();

        $this->fxOK("CSV loaded. ##" . number_format(count($this->arrIp), 0, ',', '.') . "## item(s)");

        $this
          ->fxTitle("Loading Country CSV...")
          ->loadCountryCsv();

        $this->fxOK("CSV loaded. ##" . number_format(count($this->arrCountry), 0, ',', '.') . "## item(s)");
        
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
      $response = $httpClient->request('GET', $downloadUrl);
      $zipData  = $response->getContent();

      $zipPath = $this->getGeoIPZipPath();
      file_put_contents($zipPath, $zipData);

      return $this;
    }


    protected function getGeoIPZipPath() : string
    {
      if( !is_dir(static::DIR_WORK) ) {
        mkdir(static::DIR_WORK);
      }

      $zipPath = static::DIR_WORK . 'maxmind.zip';
      return $zipPath;
    }


    protected function unzipGeoIPFile() : self
    {
      $zipPath = $this->getGeoIPZipPath();

      $oZip = new \ZipArchive();
      $oZip->open($zipPath);
      $oZip->extractTo(static::DIR_WORK);
      $oZip->close();

      unlink($zipPath);

      return $this;
    }


    protected function loadIpCsv() : self
    {
      $me = $this;
      $this->processCsv(static::CSV_IP_NAME, function($arrRow) use($me) {
        $me->arrIp[] = [
          static::IP_NETWORK  => $arrRow[static::IP_NETWORK],
          static::GEONAME_ID  => $arrRow[static::GEONAME_ID]
        ];
      });

      return $this;
    }


    protected function loadCountryCsv() : self
    {
      $me = $this;
      $this->processCsv(static::CSV_GEO_NAME, function($arrRow) use($me) {

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


    protected function processCsv(string $csvName, callable $fxProcess)
    {
      $csvFilePath = $this->getCsvDirPath() . $csvName;
      $this->fxInfo("##" . $csvFilePath . "##");

      $csvFile = Reader::createFromPath($csvFilePath);
      $csvFile->setDelimiter(',');
      $csvFile->setHeaderOffset(0);
      $oCsvData = $csvFile->getRecords();

      $this->fxInfo("This may take a while...");
      $this->io->newLine();

      $progressBar = new ProgressBar($this->output, count($csvFile));
      $progressBar->start();

      foreach($oCsvData as $arrRow) {

        $fxProcess($arrRow);
        $progressBar->advance();
      }

      $progressBar->finish();
      $this->io->newLine(2);
    }


    protected function getCsvDirPath() : string
    {
      $arrFiles = scandir(static::DIR_WORK);
      foreach($arrFiles as $fileName) {

        $fullPath = static::DIR_WORK . $fileName . DIRECTORY_SEPARATOR;

        if( !is_dir($fullPath) || stripos($fileName, static::REMOTE_ZIP_ROOT_DIR_STARTS_WITH) !== 0 ) {
          continue;
        }

        return $fullPath;
      }
    }
}
