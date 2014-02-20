#!/bin/bash

. ./cred.conf

function pause(){
   read -p "$*"
}
echo "OpenConext VM credentials script"

credentials=($engineblock_db_user $engineblock_db_pass $serviceregistry_db_user $serviceregistry_db_pass $manage_db_user $manage_db_pass $teams_db_user $teams_db_pass $api_db_user $api_db_pass $engineblock_janusapi_user $engineblock_janusapi_pass $api_janusapi_user $api_janusapi_pass $local_janusadmin_pass $janus_secretsalt)

for cred in ${credentials[*]};
do
if [[ $cred == "/" ]];
then echo "Check cred.conf some credentials are not set! They are now set as"/" "
exit 1
fi
done

echo "Using credentials assigned to the variables in file cred.conf"
echo "Do you want to STOP ALL RUNNING SERVICES and overwrite config files so credentials can be set with this script? [Y,n]"
read input
if [[ $input == "Y" || $input == "y" ]]; then
	echo -e "\nStopping services..."
	# Do NOT stop MySQL here as we need a running deamon to add passwords!!
	/etc/init.d/shibd stop
	/etc/init.d/httpd stop
	/etc/init.d/tomcat6 stop
	/etc/init.d/slapd stop

        echo -e "\nCopying..."
        cp ./modified/engineblock.ini /etc/surfconext/
        cp ./modified/manage.ini /etc/surfconext/
        cp ./modified/serviceregistry.module_janus.php /etc/surfconext/
        cp ./modified/serviceregistry.config.php /etc/surfconext/
        cp ./modified/coin-teams.properties /opt/tomcat/conf/classpath_properties/
        cp ./modified/coin-api.properties /opt/tomcat/conf/classpath_properties/
	cp ./modified/grouper.hibernate.properties /opt/tomcat/conf/classpath_properties/
        cp ./modified/slapd.conf /etc/openldap/

else
        echo "Not copying files..."
fi

echo -e "\n"
pause "Are you sure you want to continue and change passwords with credentials from cred.conf? If so press Enter, otherwise CTRL+C"

echo -e "\nSetting MySQL users and passwords with values from conf file to all related files"
# Apply credentials to file engineblock.ini
sed -i "s/\[ENGINEBLOCK_DB_USER\]/$engineblock_db_user/g" /etc/surfconext/engineblock.ini
sed -i "s/\[ENGINEBLOCK_DB_PASS\]/$engineblock_db_pass/g" /etc/surfconext/engineblock.ini
sed -i "s/\[ENGINEBLOCK_JANUSAPI_USER\]/$engineblock_janusapi_user/g" /etc/surfconext/engineblock.ini
sed -i "s/\[ENGINEBLOCK_JANUSAPI_PASS\]/$engineblock_janusapi_pass/g" /etc/surfconext/engineblock.ini

# Apply credentials to file manage.ini
sed -i "s/\[MANAGE_DB_USER\]/$manage_db_user/g" /etc/surfconext/manage.ini
sed -i "s/\[MANAGE_DB_PASS\]/$manage_db_pass/g" /etc/surfconext/manage.ini
sed -i "s/\[ENGINEBLOCK_DB_USER\]/$engineblock_db_user/g" /etc/surfconext/manage.ini
sed -i "s/\[ENGINEBLOCK_DB_PASS\]/$engineblock_db_pass/g" /etc/surfconext/manage.ini
sed -i "s/\[SERVICEREGISTRY_DB_USER\]/$serviceregistry_db_user/g" /etc/surfconext/manage.ini
sed -i "s/\[SERVICEREGISTRY_DB_PASS\]/$serviceregistry_db_pass/g" /etc/surfconext/manage.ini

# Apply credentials to file serviceregistry.module_janus.php
sed -i "s/\[SERVICEREGISTRY_DB_USER\]/$serviceregistry_db_user/g" /etc/surfconext/serviceregistry.module_janus.php
sed -i "s/\[SERVICEREGISTRY_DB_PASS\]/$serviceregistry_db_pass/g" /etc/surfconext/serviceregistry.module_janus.php

# Apply credentials to file coin-teams.properties
sed -i "s/\[ENGINEBLOCK_DB_USER\]/$engineblock_db_user/g" /opt/tomcat/conf/classpath_properties/coin-teams.properties
sed -i "s/\[ENGINEBLOCK_DB_PASS\]/$engineblock_db_pass/g" /opt/tomcat/conf/classpath_properties/coin-teams.properties
sed -i "s/\[TEAMS_DB_USER\]/$teams_db_user/g" /opt/tomcat/conf/classpath_properties/coin-teams.properties
sed -i "s/\[TEAMS_DB_PASS\]/$teams_db_pass/g" /opt/tomcat/conf/classpath_properties/coin-teams.properties

# Apply credentials to file grouper.hibernate.properties
sed -i "s/\[TEAMS_DB_USER\]/$teams_db_user/g" /opt/tomcat/conf/classpath_properties/grouper.hibernate.properties
sed -i "s/\[TEAMS_DB_PASS\]/$teams_db_pass/g" /opt/tomcat/conf/classpath_properties/grouper.hibernate.properties

# Apply credentials to file coin-api.properties
sed -i "s/\[ENGINEBLOCK_DB_USER\]/$engineblock_db_user/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[ENGINEBLOCK_DB_PASS\]/$engineblock_db_pass/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[TEAMS_DB_USER\]/$teams_db_user/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[TEAMS_DB_PASS\]/$teams_db_pass/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[API_DB_USER\]/$api_db_user/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[API_DB_PASS\]/$api_db_pass/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[API_JANUSAPI_USER\]/$api_janusapi_user/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
sed -i "s/\[API_JANUSAPI_PASS\]/$api_janusapi_pass/g" /opt/tomcat/conf/classpath_properties/coin-api.properties

# Apply credentials to file serviceregistry.config.php
# The adminpass is the localadmin login for JANUS (simplesamlphp)
sed -i "s/\[LOCAL_JANUSADMIN_PASS\]/$local_janusadmin_pass/g" /etc/surfconext/serviceregistry.config.php
# This is a secret salt used by simpleSAMLphp (JANUS) when it needs to generate a secure hash of a value.
sed -i "s/\[JANUS_SECRETSALT\]/$janus_secretsalt/g" /etc/surfconext/serviceregistry.config.php

echo -e "\nPlease provide the current root password for the MySQL database (by default this is set to 'c0n3xt')"
read current_root_db_pass

echo -e "\nUsing current MySQL root password: $current_root_db_pass"

# Fix some database security issues
echo "Dropping database TEST"
mysql -uroot -p$current_root_db_pass -e "DROP DATABASE test"

# Delete all users other than root
echo "Cleanup MySQL root users and root access"
mysql -uroot -p$current_root_db_pass -e "delete from mysql.user where User <> 'root'"
# Delete other root users than specified
mysql -uroot -p$current_root_db_pass -e "delete from mysql.user where User='root' and Host NOT IN ('localhost','127.0.0.1','localhost.localdomain')"

# Create engineblock user/pass
mysql -uroot -p$current_root_db_pass -e "GRANT ALL PRIVILEGES ON engineblock.* TO $engineblock_db_user@localhost IDENTIFIED BY '$engineblock_db_pass'"
echo "User for database 'engineblock' updated sucessfully"

# Create manage user/pass
mysql -uroot -p$current_root_db_pass -e "GRANT ALL PRIVILEGES ON manage.* TO $manage_db_user@localhost IDENTIFIED BY '$manage_db_pass'"
echo "User for database 'manage' updated sucessfully"

# Create serviceregistry user/pass
mysql -uroot -p$current_root_db_pass -e "GRANT ALL PRIVILEGES ON serviceregistry.* TO $serviceregistry_db_user@localhost IDENTIFIED BY '$serviceregistry_db_pass'"
echo "User for database 'serviceregistry' updated sucessfully"
# Modify JANUS API access user for 'engine'
mysql -uroot -p$current_root_db_pass -e "UPDATE serviceregistry.janus__user SET secret='$engineblock_janusapi_pass' WHERE userid='$engineblock_janusapi_user'"
echo "User for JANUS API access from 'engine' updated sucessfully"
# Modify JANUS API access user for 'api' ('api' is OpenConext API)
# CREATE MYSQL USER API WITH CORRECT COLUMNS AND VALUES...............................................................................................
#mysql -uroot -p$current_root_db_pass -e "UPDATE serviceregistry.janus__user SET secret='$api_janusapi_pass' WHERE userid='$api_janusapi_user'"
#echo "User for JANUS API access from 'engine' updated sucessfully"

# Create teams user/pass
mysql -uroot -p$current_root_db_pass -e "GRANT ALL PRIVILEGES ON teams.* TO $teams_db_user@localhost IDENTIFIED BY '$teams_db_pass'"
echo "User for database 'teams' updated sucessfully"

# Create api user/pass
mysql -uroot -p$current_root_db_pass -e "GRANT ALL PRIVILEGES ON api.* TO $api_db_user@localhost IDENTIFIED BY  '$api_db_pass'"
echo "User for database 'api' updated sucessfully"

# After all set, Flush Privileges
mysql -uroot -p$current_root_db_pass -e "FLUSH PRIVILEGES"

# Change MySQL root password and print new password
mysql -uroot -p$current_root_db_pass -e "UPDATE mysql.user SET Password=PASSWORD('$root_db_pass') WHERE User='root';FLUSH PRIVILEGES;"
echo "MySQL Root password set to: $root_db_pass"

echo "Create a new LDAP passwd for slapd.conf based on cred.conf" 
slapd_pass=`slappasswd -n -s $ldap_pass`
echo $slapd_pass
sed -i "s/\[SLAPD_PASS\]/$slapd_pass/g" /etc/openldap/slapd.conf

echo "Setting LDAP password with value from root_db_pass in all related files"
sed -i "s/\[LDAP_PASS\]/$ldap_pass/g" /etc/surfconext/engineblock.ini
sed -i "s/\[LDAP_PASS\]/$ldap_pass/g" /etc/surfconext/manage.ini
sed -i "s/\[LDAP_PASS\]/$ldap_pass/g" /opt/tomcat/conf/classpath_properties/coin-api.properties
echo "LDAP password set to: $ldap_pass"

# restart LDAP, Mysql, Tomcat, Apache
echo "Restarting LDAP,  Mysql, Tomcat, Shibboleth and Apache"
/etc/init.d/slapd restart
/etc/init.d/mysqld restart
/etc/init.d/tomcat6 restart
echo "Depending on your hardware, restarting all Java apps may take a while...."
/etc/init.d/shibd restart
/etc/init.d/httpd restart

