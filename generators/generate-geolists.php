<?php
use TurboLabIt\ZzfirewallGenerators\GenerateGeolistsCommand;
use TurboLabIt\PhpSymfonyBasecommand\Command\AbstractBaseCommand;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Output\ConsoleOutput;

require __DIR__.'/vendor/autoload.php';

$arrCmdArguments = [
    GenerateGeolistsCommand::CLI_ARG_MAXMIND_KEY => $argv[1],
    // 💡 https://github.com/TurboLabIt/php-symfony-basecommand/blob/main/src/Traits/CliOptionsTrait.ph 
    //"--" . AbstractBaseCommand::CLI_OPT_DRY_RUN         => true,
    //"--" . AbstractBaseCommand::CLI_OPT_BLOCK_MESSAGES  => true,
];

( new GenerateGeolistsCommand() )
    ->setName('GenerateGeolists')
    ->run(new ArrayInput($arrCmdArguments), new ConsoleOutput());
