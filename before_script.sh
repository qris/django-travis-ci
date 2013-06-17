#!/bin/bash
set -e

# Use pip because we may be running with a different python than the
# system one, in which case system packages won't be visible.
sudo apt-get build-dep python-imaging
pip install selenium pytz markdown textile docutils py-bcrypt PyYAML PIL pylibmc Sphinx

if [ $DB = postgres ]
then
	pip install psycopg2
	TEMPLATE=template1
	if [ $GIS = gis ]
	then
		sudo apt-get install postgis postgresql-9.1-postgis libproj0 libgdal1-1.7.0 libgeos-c1
		wget https://docs.djangoproject.com/en/1.5/_downloads/create_template_postgis-debian.sh
		sudo sudo -u postgres sh create_template_postgis-debian.sh >/dev/null
		TEMPLATE=template_postgis
	fi
	psql -c "create database django TEMPLATE $TEMPLATE ;" -U postgres
	psql -c "create database django2 TEMPLATE $TEMPLATE ;" -U postgres
elif [ $DB = mysql ]
then
	pip install MySQL-python
	if [ $GIS = gis ]
	then
		sudo apt-get install libgeos-c1	libgdal1-1.7.0
	fi
	mysql -e 'create database django;'
	mysql -e 'create database django2;'
fi

echo $PATH

sudo ln -s `pwd`/tests/travis_configs/chromedriver /usr/local/bin
which chromedriver
stat -L /usr/local/bin/chromedriver

sudo bash /etc/init.d/xvfb start

# Experimental fixes for running out of disk space on Travis
# https://github.com/travis-ci/travis-ci/issues/1125
# Disabled for testing whether Josh's increased ramdisk has fixed the
# problems.

if false; then
	postgresql_conf=/etc/postgresql/9.1/main/postgresql.conf
	data_directory=`sudo awk '/data_directory/{ print $3 }' $postgresql_conf`

	sudo tee -a $postgresql_conf <<EOF
	restart_after_crash = off
	checkpoint_timeout = 30
	checkpoint_segments = 1
	log_min_messages = info
	log_checkpoints = on
	log_temp_files = 1024
	log_autovacuum_min_duration = 0
EOF

	sudo /etc/init.d/postgresql stop
	sudo mv $data_directory/pg_xlog /tmp
	sudo ln -s /tmp/pg_xlog $data_directory
	sudo /etc/init.d/postgresql start
fi

