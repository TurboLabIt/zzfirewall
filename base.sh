## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"

## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

## Default config files
CONFIGFILE_FULLPATH_DEFAULT=${SCRIPT_DIR}${SCRIPT_NAME}.default.conf
CONFIGFILE_NAME=$SCRIPT_NAME.conf
CONFIGFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_NAME
CONFIGFILE_FULLPATH_DIR=${SCRIPT_DIR}${CONFIGFILE_NAME}

## Config reading function
function zzfirewallConfigSet()
{
  for CONFIGFILE_FULLPATH in "$@"
  do
    if [ -f "$CONFIGFILE_FULLPATH" ]; then
      source "$CONFIGFILE_FULLPATH"
    fi
  done
}

zzfirewallConfigSet "$CONFIGFILE_FULLPATH_DEFAULT" "$CONFIGFILE_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_DIR"


function printMessage()
{
  echo -e "\e[1;33m $1... \e[0m"
}

## Footer function
function zzfirewallPrintEndFooter()
{
  echo ""
  echo "Time took"
  echo "---------"
  echo "$((($(date +%s)-$TIME_START)/60)) min."

  echo ""
  echo "The End"
  echo "-------"
  echo $(date)
  echo "$FRAME"
}

