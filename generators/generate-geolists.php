<?php
use TurboLabIt\ZzfirewallGenerators\GenerateGeolistsCommand;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Output\ConsoleOutput;

require __DIR__.'/vendor/autoload.php';

$arrCmdArguments = [
    GenerateGeolistsCommand::CLI_ARG_MAXMIND_KEY => $argv[1],
    //"--" . AbstractBaseCommand::CLI_OPT_BLOCK_MESSAGES  => true,
    //"--" . AbstractBaseCommand::CLI_OPT_SINGLE_ID       => 3,
];

( new GenerateGeolistsCommand() )
    ->setName('GenerateGeolists')
    ->run(new ArrayInput($arrCmdArguments), new ConsoleOutput());
