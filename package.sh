#!/bin/bash

## packaging tool for OpenOlitor client delivery

 #                                                                           #
#    ____                   ____  ___ __                                      #
#   / __ \____  ___  ____  / __ \/ (_) /_____  _____                          #
#  / / / / __ \/ _ \/ __ \/ / / / / / __/ __ \/ ___/   OpenOlitor             #
# / /_/ / /_/ /  __/ / / / /_/ / / / /_/ /_/ / /       contributed by tegonal #
# \____/ .___/\___/_/ /_/\____/_/_/\__/\____/_/        http://openolitor.ch   #
#     /_/                                                                     #
#                                                                             #
# This program is free software: you can redistribute it and/or modify it     #
# under the terms of the GNU General Public License as published by           #
# the Free Software Foundation, either version 3 of the License,              #
# or (at your option) any later version.                                      #
#                                                                             #
# This program is distributed in the hope that it will be useful, but         #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with this program. If not, see http://www.gnu.org/licenses/                 #
#                                                                             #
 #                                                                           #

while [[ $# -gt 1 ]]
do
  key="$1"

  case $key in
    -b|--branch)
      BRANCH="$2"
      shift
      ;;
    -e|--env)
      ENVIRONMENT="$2"
      shift
      ;;
    -n|--build-number)
      BUILD_NUMBER="$2"
      shift
      ;;
    -o|--output)
      OUTPUT="$2"
      shift
      ;;
    -ncle|--no-clean)
      NOCLEAN=true
      shift
      ;;
		-nclo|--no-clone)
      NOCLONE=true
      shift
      ;;
    *)

  ;;

esac
shift
done

BRANCH=${BRANCH:-'master'}
ENVIRONMENT=${ENVIRONMENT:-'test'}
OUTPUT=${OUTPUT:-'openolitor-client.zip'}
NOCLEAN=${NOCLEAN:-false}
NOCLONE=${NOCLONE:-false}

echo "Using branch ${BRANCH} and environment ${ENVIRONMENT}"

if [ "$NOCLEAN" = false ] ; then
	echo "Cleaning up .tmp and dist"

	rm -rf .tmp
	mkdir .tmp
	rm -rf dist
	mkdir dist
fi

declare -a PROJECTS=($(<projects))

NGINX_CONFIG="$(cat nginx.conf)"
NGINX_LOCATION="$(cat nginx_location.conf)"
LOCATIONS=""
FILES="nginx.conf"

for PROJECT in "${PROJECTS[@]}"
do
	if [ "$NOCLONE" = false ] ; then
	  ( git clone --depth 1 -b $BRANCH https://github.com/OpenOlitor/${PROJECT}.git .tmp/${PROJECT} )
  fi

  ( cd .tmp/${PROJECT} && npm install -g bower grunt grunt-cli && npm install --cache-min 99999 && bower install && grunt build --env=$ENVIRONMENT --buildnr=$BUILD_NUMBER )

  PROJECT_NAME=$(echo $PROJECT | cut -d'-' -f 3)
  if [ "kundenportal" = $PROJECT_NAME ]; then
    PROJECT_LOCATION="/"
    PROJECT_ROOT="$PROJECT_NAME"
  else
    PROJECT_LOCATION="/$PROJECT_NAME"
    PROJECT_ROOT=""
  fi

  LOCATION="${NGINX_LOCATION/project_location/$PROJECT_LOCATION}"
  LOCATION="${LOCATION/project_root/$PROJECT_ROOT}"

  LOCATIONS="$LOCATIONS
  $LOCATION"

  ( cd .tmp/ && ln -fs $PROJECT/dist $PROJECT_NAME )

  FILES="$FILES
$PROJECT_NAME"

done

NGINX_CONFIG="${NGINX_CONFIG/nginx_locations/$LOCATIONS}"

echo "$NGINX_CONFIG" > .tmp/nginx.conf

( cd .tmp/ && echo "$FILES" | zip -r ../dist/$OUTPUT -@ )
