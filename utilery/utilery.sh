#!/bin/bash

working_dir_utilery="$1"

database_user_utilery="$2"

database_user_password_utilery="$3"

database_name_utilery="$4"

database_host_utilery="$5"

queries_path_utilery="$working_dir_utilery/utilery/queries.yml"

python_version_utilery="3.5"

#### Configuration ####

#  Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper git and libpq-dev
apt-get update && \
apt-get install -y python$python_version_utilery python$python_version_utilery-dev python3-pip python-virtualenv virtualenvwrapper git libpq-dev gdal-bin nodejs npm

npm install http-server -g
ln -s /usr/bin/nodejs /usr/bin/node

mkdir -p $working_dir_utilery

#  Clone utilery

#  If utilery already exist
if [ -d "$working_dir_utilery/utilery" ]; then
 while true; do
   read -p "Utilery folder already exist in $working_dir_utilery directory, yes will delete utilery folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf  "$working_dir_utilery/utilery"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi
cd $working_dir_utilery
git clone https://github.com/etalab/utilery
cd -

#  Set up of the configuration

#  Add the support of multicores
rm $working_dir_utilery/utilery/utilery/serve.py
cat > $working_dir_utilery/utilery/utilery/serve.py << EOF1
from utilery.views import app
from werkzeug.serving import run_simple
from multiprocessing import cpu_count

run_simple('0.0.0.0', 3579, app, use_debugger=True, use_reloader=True, processes=cpu_count())
EOF1

#  Change the database connexion
rm $working_dir_utilery/utilery/utilery/config/default.py
cat > $working_dir_utilery/utilery/utilery/config/default.py << EOF1
DATABASES = {
    "default": "dbname=$database_name_utilery user=$database_user_utilery password=$database_user_password_utilery host=$database_host_utilery"
}
RECIPES = ['$queries_path_utilery']
TILEJSON = {
    "tilejson": "2.1.0",
    "name": "utilery",
    "description": "A lite vector tile server",
    "scheme": "xyz",
    "format": "pbf",
    "tiles": [
        "http://vector.myserver.org/all/{z}/{x}/{y}.pbf"
    ],
}
BUILTIN_PLUGINS = ['utilery.plugins.builtins.CORS']
PLUGINS = []
DEBUG = False
SRID = 900913
SCALE = 1
BUFFER = 0
CLIP = True
CORS = "*"
EOF1

# Import of the queries you wanna use
cp ./utilery/queries.yml $working_dir_utilery/utilery

#  Create the virtualenv
rm -rf $working_dir_utilery/utilery-virtualenv
cd $working_dir_utilery
virtualenv utilery-virtualenv --python=/usr/bin/python$python_version_utilery
cd -

#  Install python package
cd $working_dir_utilery/utilery
$working_dir_utilery/utilery-virtualenv/bin/pip3 install --upgrade pip
$working_dir_utilery/utilery-virtualenv/bin/pip3 install .
cd -

#  Install unstable python dependencies
$working_dir_utilery/utilery-virtualenv/bin/pip3 install -r $working_dir_utilery/utilery/requirements.txt