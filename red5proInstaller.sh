#!/bin/bash
#!/usr/bin/bash 
## --

#SERVICE NAME
RED5_VERSION_NAME="Red5 Pro"

# Configuration file
RPRO_CONFIGURATION_FILE=conf.ini

# DEFAULT_RPRO_PATH=/usr/local/red5pro
# MIN_JAVA_VERSION="1.8"
RED5PRO_LOGGING=true
RED5PRO_LOG_FILE_NAME=rpro_installer.log
RPRO_LOG_FILE=$PWD/$RED5PRO_LOG_FILE_NAME

RPRO_OS_TYPE=
OS_DEB="DEBIAN"
OS_RHL="REDHAT"

RED5PRO_INSTALL_AS_SERVICE=true 
RPRO_SERVICE_LOCATION_V1=/etc/init.d
RPRO_SERVICE_NAME_V1=red5pro 
RPRO_SERVICE_LOCATION_V2=/lib/systemd/system
RPRO_SERVICE_NAME_V2=red5pro.service
RPRO_SERVICE_LOCATION=
RPRO_SERVICE_NAME=

# init.d(1) vs modern jsvc(2)
RED5PRO_SERVICE_VERSION=2

RPRO_RED5SH=red5.sh
RPRO_SERVICE_INSTALLER=/usr/sbin/update-rc.d
RPRO_IS_64_BIT=0
RPRO_OS_NAME=
RPRO_OS_VERSION=
RPRO_MODE=0

PID=/var/run/red5pro.pid
JAVA_JRE_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/8u102-b14/"
JAVA_32_FILENAME="jre-8u102-linux-i586.rpm"
JAVA_64_FILENAME="jre-8u102-linux-x64.rpm"

RED5PRO_DEFAULT_DOWNLOAD_NAME="red5pro_latest.zip"
RED5PRO_DEFAULT_DOWNLOAD_FOLDER_NAME="tmp"
RED5PRO_DEFAULT_DOWNLOAD_FOLDER=
RED5PRO_INSTALLER_OPERATIONS_CLEANUP=1


RED5PRO_SSL_LETSENCRYPT_FOLDER_NAME="letsencrypt"
RED5PRO_SSL_LETSENCRYPT_GIT="https://github.com/letsencrypt/letsencrypt"
RED5PRO_SSL_LETSENCRYPT_FOLDER=
RED5PRO_SSL_LETSENCRYPT_EXECUTABLE="letsencrypt-auto"
RED5PRO_SSL_DEFAULT_HTTP_PORT=5080
RED5PRO_SSL_DEFAULT_HTTPS_PORT=443
RED5PRO_SSL_DEPRECATED_WS_PORT=8081
RED5PRO_SSL_DEPRECATED_WSS_PORT=8083

RED5PRO_SSL_DEFAULT_WS_PORT=5080
RED5PRO_SSL_DEFAULT_WSS_PORT=443

NEW_RED5PRO_WEBSOCKETS=true
RED5PRO_OPEN_SOURCE=false

RED5PRO_DOWNLOAD_URL=
RED5PRO_MEMORY_PCT=80
RED5PRO_UPFRONT_MEMORY_ALLOC=true
RED5PRO_DEFAULT_MEMORY_PATTERN="-Xmx2g"


configure_for_red5_os()
{
	RED5_VERSION_NAME="Red5"
	RPRO_SERVICE_LOCATION_V1=/etc/init.d	
	RPRO_SERVICE_NAME_V1=red5 
	RPRO_SERVICE_LOCATION_V2=/lib/systemd/system
	RPRO_SERVICE_NAME_V2=red5.service
	RPRO_RED5SH=red5.sh
	RPRO_SERVICE_INSTALLER=/usr/sbin/update-rc.d
	PID=/var/run/red5.pid
	RED5PRO_DEFAULT_DOWNLOAD_NAME="red5_latest.zip"
}


validatePermissions()
{
	if [[ $EUID -ne 0 ]]; then
		echo "This script does not seem to have / has lost root permissions. Please re-run the script with 'sudo'"
		exit 1
	fi
}

######################################################################################
################################## LOGGER ############################################

write_log()
{
	if [ $# -eq 0 ]; then
		return
	else
		if $RED5PRO_LOGGING; then			
			logger -s $1 2>> $RPRO_LOG_FILE
		fi
	fi
}

lecho()
{
	if [ $# -eq 0 ]; then
		return
	else
		echo $1

		if $RED5PRO_LOGGING; then
			logger -s $1 2>> $RPRO_LOG_FILE
		fi
	fi
}


lecho_err()
{
	if [ $# -eq 0 ]; then
		return
	else
		# Red in Yellow
		echo -e "\e[41m $1\e[m"

		if $RED5PRO_LOGGING; then
			logger -s $1 2>> $RPRO_LOG_FILE
		fi
	fi
}


clear_log()
{
	> $RPRO_LOG_FILE
}



delete_log()
{
	rm $RPRO_LOG_FILE
}

######################################################################################
############################ MISC ----- METHODS ######################################

cls()
{
	printf "\033c"
}

refresh()
{
	if [ "$RPRO_MODE" -eq  1 ]; then
 	show_utility_menu
	else
 	show_simple_menu
	fi
}

pause()
{

	printf "\n"
	read -r -p 'Press any [ Enter ] key to continue...' key


	if [ "$RPRO_MODE" -eq  1 ]; then
 	show_utility_menu
	else
 	show_simple_menu
	fi
}

pause_license()
{

	printf "\n"
	read -r -p 'Press [ Enter ] key to continue...' key

	show_licence_menu
}

empty_pause()
{
	printf "\n"
	read -r -p 'Press any [ Enter ] key to continue...' key
}

empty_line()
{
	printf "\n"
}


######################################################################################
############################ MISC TOOL INSTALLS ######################################

# Public
check_java()
{
	write_log "Checking java requirements"

	java_check_success=0
	has_min_java_version=0

	for JAVA in "${JAVA_HOME}/bin/java" "${JAVA_HOME}/Home/bin/java" "/usr/bin/java" "/usr/local/bin/java"
		do
			if [ -x "$JAVA" ]
			then
			break
		fi
	done

	if [ ! -x "$JAVA" ]; then
	  	lecho "Unable to locate Java. If you think you do have java installed, please set JAVA_HOME environment variable to point to your JDK / JRE."
	else
		JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')

		JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')

		lecho "Current java version is $JAVA_VERSION"

		JAVA_VERSION_MAJOR=`echo "${JAVA_VERSION:0:3}"`

		if (( $(echo "$JAVA_VERSION_MAJOR < $MIN_JAVA_VERSION" |bc -l) )); then
			has_min_java_version=0			
			lecho "You need to install a newer java version of java!"		
		else
			has_min_java_version=1
			lecho "Minimum java version is already installed!"
		fi
	fi

	if [ ! $# -eq 0 ]
	  then
	    pause
	fi

}

# Public
check_unzip()
{
	write_log "Checking for unzip utility"			
	unzip_check_success=0

	if isinstalled unzip; then
	unzip_check_success=1
	write_log "unzip utility was found"		
	else
	unzip_check_success=0
	lecho "unzip utility not found."				
	fi
}

# Public

check_git()
{
	write_log "Checking for git software"	
	git_check_success=0

	if isinstalled git; then
	git_check_success=1
	write_log "git utility was found"
	else
	git_check_success=0
	lecho "git utility not found."
	fi
}

check_wget()
{
	write_log "Checking for wget utility"	
	wget_check_success=0

	if isinstalled wget; then
	wget_check_success=1
	write_log "wget utility was found"
	else
	wget_check_success=0
	lecho "wget utility not found."
	fi
}

check_bc()
{
	write_log "Checking for bc utility"	
	bc_check_success=0

	if isinstalled bc; then
	bc_check_success=1
	write_log "bc utility was found"
	else
	bc_check_success=0
	lecho "bc utility not found."
	fi
}

check_jsvc()
{
	write_log "Checking for jsvc utility"	
	jsvc_check_success=0

	if isinstalled jsvc; then
	jsvc_check_success=1
	write_log "jsvc utility was found"
	else
	jsvc_check_success=0
	lecho "jsvc utility not found."
	fi
}

# Public
install_java()
{
	write_log "Installing java"	
	java_install_success=0

	if isDebian; then
	install_java_deb	
	else
	install_java_rhl
	fi
	
	# verify
	check_java

	# has_min_java_version=1

	if [ $has_min_java_version -eq 1 ]; then
		local default_jre="$(which java)";
		lecho "Java successfully installed at $default_jre"
		java_install_success=1
	else
		lecho "Could not install required version of java"
	fi
		
}

# Private
install_java_deb()
{
	lecho "Installing Java for Debian";
	apt-get install -y default-jre
}

# Private
install_java_rhl()
{
	lecho "Installing Java for CentOs";
	yum -y install java
}

# Public
install_jsvc()
{
	write_log "Installing jsvc"

	if isDebian; then
	install_jsvc_deb	
	else
	install_jsvc_rhl
	fi		
}

# Private
install_jsvc_deb()
{
	write_log "Installing jsvc on debian"
	apt-get install -y jsvc

	install_jsvc="$(which jsvc)";
	lecho "jsvc installed at $install_jsvc"
}

# Private
install_jsvc_rhl()
{
	write_log "Installing jsvc on rhl"
	yum -y install jsvc

	install_jsvc="$(which jsvc)";
	lecho "jsvc installed at $install_jsvc"
}

# Public
install_unzip()
{
	write_log "Installing unzip"

	if isDebian; then
	install_unzip_deb	
	else
	install_unzip_rhl
	fi		
}

# Private
install_unzip_deb()
{
	write_log "Installing unzip on debian"

	apt-get install -y unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}

# Private
install_unzip_rhl()
{
	write_log "Installing unzip on rhle"

	# yup update
	yum -y install unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}

# Public

install_git()
{
	write_log "Installing git"

	if isDebian; then
	install_git_deb	
	else
	install_git_rhl
	fi		
}

install_wget()
{
	write_log "Installing wget"

	if isDebian; then
	install_wget_deb	
	else
	install_wget_rhl
	fi		
}

install_bc()
{
	write_log "Installing bc"

	if isDebian; then
	install_bc_deb	
	else
	install_bc_rhl
	fi		
}

# Private

install_git_deb()
{
	write_log "Installing git on debian"

	apt-get install -y git

	install_git="$(which git)";
	lecho "git installed at $install_git"
}

install_git_rhl()
{
	write_log "Installing git on rhle"

	yum -y install git

	install_git="$(which git)";
	lecho "git installed at $install_git"
}

install_wget_deb()
{
	write_log "Installing wget on debian"

	apt-get install -y wget

	install_wget="$(which wget)";
	lecho "wget installed at $install_wget"
}

# Private
install_wget_rhl()
{
	write_log "Installing wget on rhle"

	# yup update
	yum -y install wget

	install_wget="$(which wget)";
	lecho "wget installed at $install_wget"
}

# Private
install_bc_deb()
{
	write_log "Installing bc on debian"

	apt-get install -y bc

	install_bc="$(which bc)";
	lecho "bc installed at $install_bc"
}

# Private
install_bc_rhl()
{
	write_log "Installing bc on rhle"

	# yup update
	yum -y install bc

	install_bc="$(which bc)";
	lecho "bc installed at $install_bc"
}

# Public
add_update_java()
{
	install_java
}

######################################################################################
############################# SSL INSTALLER (LetsEncrypt) ############################

letsencrypt_exists()
{	
	if [ -d "$RED5PRO_SSL_LETSENCRYPT_FOLDER" ]; then
		
		RED5PRO_SSL_LETSENCRYPT__SETUP_FILE="$RED5PRO_SSL_LETSENCRYPT_FOLDER/setup.py"

		if [ -f "$RED5PRO_SSL_LETSENCRYPT__SETUP_FILE" ]; then
			true
		else
			false
		fi
	else
	  false
	fi
}

letsencrypt_download()
{
	letsencrypt_download_success=0

	cd "$CURRENT_DIRECTORY"

	git clone "$RED5PRO_SSL_LETSENCRYPT_GIT"
	
	if letsencrypt_exists; then

		letsencrypt_download_success=1
	else
		letsencrypt_download_success=0
	fi
}

show_has_ssl_cert_menu()
{
	has_ssl_cert_menu
	has_ssl_cert_menu_read_options
}

has_ssl_cert_menu()
{
	cls

	lecho "I have detected an existing letsEncrypt SSL certificate for this domain. Please an appropriate action to continue!"

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	echo -e "\e[44m EXISTING SSL CERT DETECTED! \e[m"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "1. --- DELETE LETSENCRYPT DIRECTORY (ALL CERTIFICATES) AND TRY AGAIN"
	echo "2. --- ATTEMPT TO USE THE EXISTING CERTIFICATE			  "	
	echo "3. --- Exit					 		  "
	echo "                             		 			  "

}

has_ssl_cert_menu_read_options(){

	reuse_existing_ssl_cert=0

	local choice
	read -p "Enter choice [ 1 - 2 | X to exit ] " choice
	case $choice in
		1) rm -rf /etc/letsencrypt ;;
		2) reuse_existing_ssl_cert=1 ;;
		[xX])  pause ;;		
		*) echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_has_ssl_cert_menu ;;
	esac
}

rpro_ssl_installer()
{
	# Permission check
	validatePermissions

	rpro_ssl_installation_success=0


	lecho "Starting Letsencrypt SSL Installer"
	sleep 2

	# Downloading

	if letsencrypt_exists; then
		lecho "Letsencrypt found at $RED5PRO_SSL_LETSENCRYPT_FOLDER"
	else
		lecho "Downloading letsencrypt ssl cert generator"
		letsencrypt_download
		
		# Recheck
		if [[ $letsencrypt_download_success -eq 0 ]]; then
			lecho_err "Failed to download letsencrypt from github"
			pause
		fi
	fi

	# Check for Red5 Pro
	check_current_rpro 1 1
	if [[ $rpro_exists -eq 0 ]]; then
		pause
	fi
	
	# Stopping Red5 Pro if running [ VERY iMPORTANT! ]
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	lecho "$RED5_VERSION_NAME will be stopped temporarily (If running), for the Letsencrypt SSL challenge to complete successfully!."
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	sleep 5
	stop_red5pro_service 1

	# Initializing letsencrypt => Need better way to know if this is first time setup or already setup

	cd "$RED5PRO_SSL_LETSENCRYPT_FOLDER"	

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	lecho " Preparing letsencrypt" 
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	sleep 2
 
	./letsencrypt-auto --help 2>&1 | tee -a "$RPRO_LOG_FILE"
	
	# Get Certificate
	ssl_cert_request_form

	# detect if cert exists for the domain
	rpro_old_ssl_domain_account="/etc/letsencrypt/live/$rpro_ssl_reg_domain"
	if [ -d "$rpro_old_ssl_domain_account" ]; then
		show_has_ssl_cert_menu
	fi

	# Prepare Keystore stuff

	rpro_ssl_fullchain="/etc/letsencrypt/live/$rpro_ssl_reg_domain/fullchain.pem"
	rpro_ssl_privkey="/etc/letsencrypt/live/$rpro_ssl_reg_domain/privkey.pem"
	rpro_ssl_fullchain_and_key="/etc/letsencrypt/live/$rpro_ssl_reg_domain/fullchain_and_key.p12"
	rpro_ssl_keystore_jks="/etc/letsencrypt/live/$rpro_ssl_reg_domain/keystore.jks"
	rpro_ssl_tomcat_cer="/etc/letsencrypt/live/$rpro_ssl_reg_domain/tomcat.cer"
	rpro_ssl_trust_store="/etc/letsencrypt/live/$rpro_ssl_reg_domain/truststore.jks"

	# if has cert then use that
	if [[ $reuse_existing_ssl_cert -eq 1 ]]; then

		# Ask for SSL cert password
		ssl_cert_passphrase_form

	else

		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		lecho "Requesting SSL certificate" 
		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

		sleep 2

		letsencrypt_cert_gen_success=0
		rpro_ssl_response=$(./letsencrypt-auto certonly --standalone --email "$rpro_ssl_reg_email" --agree-tos -d "$rpro_ssl_reg_domain" 2>&1 | tee /dev/tty)

		lecho "$rpro_ssl_response" | grep 'Congratulations! Your certificate and chain have been saved' &> /dev/null
		if [ $? == 0 ]; then
		   	lecho "Cert successfully generated!"
			letsencrypt_cert_gen_success=1
		else
			lecho "$rpro_ssl_response" | grep 'You have an existing certificate that has exactly the same domains' &> /dev/null

			if [ $? == 0 ]; then
				letsencrypt_cert_gen_success=1
			else			
				lecho_err "SSL cert generation failed!"
				read -r -p " -- Retry? [y/N] " try_login_response
				case $try_login_response in
				[yY][eE][sS]|[yY]) 
				rpro_ssl_installer
				;;
				*)
				letsencrypt_cert_gen_success=0
				;;
				esac
			fi	
		fi

		# Recheck & exit
		if [[ $letsencrypt_cert_gen_success -eq 0 ]]; then
			lecho "SSL Certificate generation did not succeed. Please rectify any errors mentioned in the logging and try again!"
			pause
		fi
	
		# Create Keystore

		#rpro_ssl_fullchain="/etc/letsencrypt/live/$rpro_ssl_reg_domain/fullchain.pem"
		#rpro_ssl_privkey="/etc/letsencrypt/live/$rpro_ssl_reg_domain/privkey.pem"
		#rpro_ssl_fullchain_and_key="/etc/letsencrypt/live/$rpro_ssl_reg_domain/fullchain_and_key.p12"
		#rpro_ssl_keystore_jks="/etc/letsencrypt/live/$rpro_ssl_reg_domain/keystore.jks"
		#rpro_ssl_tomcat_cer="/etc/letsencrypt/live/$rpro_ssl_reg_domain/tomcat.cer"
		#rpro_ssl_trust_store="/etc/letsencrypt/live/$rpro_ssl_reg_domain/truststore.jks"
	
		# Ask for keystore password here -> input
		ssl_cert_passphrase_form

		openssl pkcs12 -export -in "$rpro_ssl_fullchain" -inkey "$rpro_ssl_privkey" -out "$rpro_ssl_fullchain_and_key" -password pass:"$rpro_keystore_cert_pass" -name tomcat


		keytool_response=$(keytool -importkeystore -deststorepass "$rpro_keystore_cert_pass" -destkeypass "$rpro_keystore_cert_pass" -destkeystore "$rpro_ssl_keystore_jks" -srckeystore "$rpro_ssl_fullchain_and_key" -srcstoretype PKCS12 -srcstorepass "$rpro_keystore_cert_pass" -alias tomcat)

		# Check for keytool error
		if [[ ${keytool_response} == *"keytool error"* ]];then
		    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		    lecho_err "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
		    lecho_err "Error Details:"
		    lecho_err "$keytool_response"
		    pause
		fi

		keytool_response=$(keytool -export -alias tomcat -file "$rpro_ssl_tomcat_cer" -keystore "$rpro_ssl_keystore_jks" -storepass "$rpro_keystore_cert_pass" -noprompt)

		# Check for keytool error
		if [[ ${keytool_response} == *"keytool error"* ]];then
		    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		    lecho_err "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
		    lecho_err "Error Details:"
		    lecho_err "$keytool_response"
		    pause
		fi

		keytool_response=$(keytool -import -trustcacerts -alias tomcat -file "$rpro_ssl_tomcat_cer" -keystore "$rpro_ssl_trust_store" -storepass "$rpro_keystore_cert_pass" -noprompt)

		# Check for keytool error
		if [[ ${keytool_response} == *"keytool error"* ]];then
		    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		    lecho_err "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
		    lecho_err "Error Details:"
		    lecho_err "$keytool_response"
		    pause
		fi

	fi
	
	# if all ok -> Prepare RTMPS Key and Trust store parameters
	# RTMPS Key and Trust store parameters
	rpro_ssl_trust_store_rtmps_keystorepass="rtmps.keystorepass=$rpro_keystore_cert_pass"
	rpro_ssl_trust_store_rtmps_keystorefile="rtmps.keystorefile=$rpro_ssl_keystore_jks"
	rpro_ssl_trust_store_rtmps_truststorepass="rtmps.truststorepass=$rpro_keystore_cert_pass"
	rpro_ssl_trust_store_rtmps_truststorefie="rtmps.truststorefile=$rpro_ssl_trust_store"

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	lecho "Updating configuration files" 
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	## Substitute appropriate files to enable ssl

	# Locating files to replace

	red5pro_conf_properties="$DEFAULT_RPRO_PATH/conf/red5.properties"
	red5pro_conf_jee_container="$DEFAULT_RPRO_PATH/conf/jee-container.xml"

	# Select appropriate ssl config files after checking websocket version
	if $NEW_RED5PRO_WEBSOCKETS ; then
		red5pro_installer_conf_properties="$CURRENT_DIRECTORY/conf/red5-ssl.properties"
		red5pro_installer_conf_jee_container="$CURRENT_DIRECTORY/conf/jee-container-ssl.xml"
	else
		red5pro_installer_conf_properties="$CURRENT_DIRECTORY/conf/deprecated/red5-ssl.properties"
		red5pro_installer_conf_jee_container="$CURRENT_DIRECTORY/conf/deprecated/jee-container-ssl.xml"
	fi	
	
	config_ssl_jeecontainer

	#simple_config_ssl_properties
	smart_config_ssl_properties

	rpro_ssl_installation_success=1

	lecho "$RED5_VERSION_NAME SSL configuration conplete!. Please restart server for changes to take effect."
	read -r -p "Restart server now ? [y/N] " rpro_restart_response
	case $rpro_restart_response in
	[yY][eE][sS]|[yY]) 
	restart_red5pro_service
	;;
	*)
	;;
	esac

	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}

ssl_cert_request_form()
{

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	lecho "-------- SSL CERTIFICATE REQUEST ----------" 
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	local rpro_ssl_form_valid=1
	local rpro_ssl_domain_valid=0
	local rpro_ssl_email_valid=0

	echo "Enter Domain (The domain name for which SSL cert is required): "
	read rpro_ssl_reg_domain

	echo "Enter Email (The email address to identify the SSL with) : "
	read rpro_ssl_reg_email

	# Simple domain name validation
	if [ ! -z "$rpro_ssl_reg_domain" -a "$rpro_ssl_reg_domain" != " " ]; then	
		rpro_ssl_reg_domain_valid=1		
	else
		rpro_ssl_form_valid=0
		lecho "Invalid 'Domain' string!"		
	fi

	# simple validate email
	if isEmailValid "${rpro_ssl_reg_email}"; then
		rpro_ssl_reg_email_valid=1		
	else
		rpro_ssl_form_valid=0
		lecho "Invalid 'Email' string!"		
	fi

	# if all params not valid
	if [ "$rpro_ssl_form_valid" -eq "0" ]; then
	
		lecho_err "One or more parameters are invalid. Please check and try again!"
		read -r -p " -- Retry? [y/N] " try_login_response
		case $try_login_response in
		[yY][eE][sS]|[yY]) 
		ssl_cert_request_form
		;;
		*)
		pause
		;;
		esac		
	fi
}

ssl_cert_passphrase_form()
{

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	lecho "------- SSL CERTIFICATE PASSWORD ----------" 
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	local rpro_ssl_cert_passphrase_form_valid=0
	local rpro_ssl_cert_passphrase_form_error="Unknown error!"
	local rpro_ssl_cert_passphrase_valid=0


	echo "Enter the  SSL cert password : "
	read -s rpro_ssl_cert_passphrase

	echo "Confirm password : "
	read -s rpro_ssl_cert_passphrase_copy
	
	# simple validate password
	if [ ! -z "$rpro_ssl_cert_passphrase" -a "$rpro_ssl_cert_passphrase" != " " ]; then		

		if [ "$rpro_ssl_cert_passphrase" == "$rpro_ssl_cert_passphrase_copy" ]; then

			rpro_ssl_cert_passphrase_length=size=${#rpro_ssl_cert_passphrase} 

			if [[ "$rpro_ssl_cert_passphrase_length" -gt 4 ]]; then

				rpro_ssl_cert_passphrase_valid=1
			else
				rpro_ssl_cert_passphrase_valid=0
				rpro_ssl_cert_passphrase_form_error="Invalid password length. Minimum length should be 5"
			fi
		else
			rpro_ssl_cert_passphrase_valid=0
			rpro_ssl_cert_passphrase_form_error="Passwords do not match!"
		fi		
	else
		rpro_ssl_cert_passphrase_valid=0
		rpro_ssl_cert_passphrase_form_error="Password cannot be empty!"
	fi

	# If all params not valid
	local try_login_response
	if [ "$rpro_ssl_cert_passphrase_valid" -eq "0" ]; then
	
		lecho_err "There seems to be a problem with the cert password.Cause:$rpro_ssl_cert_passphrase_form_error.Please check and try again!"
		read -r -p " -- Retry? [y/N] " try_login_response
		case $try_login_response in
		[yY][eE][sS]|[yY]) 
		ssl_cert_passphrase_form
		;;
		*)
		pause
		;;
		esac		
	fi

	rpro_keystore_cert_pass=$rpro_ssl_cert_passphrase
}

config_ssl_jeecontainer()
{
	lecho "Configuring $red5pro_conf_jee_container.."
	sleep 1

	if [ ! -f "$red5pro_conf_jee_container" ]; then
	    lecho_err "Error : File  $red5pro_conf_jee_container not found!"
	    pause
	fi
	
	if [ ! -f "$red5pro_installer_conf_jee_container" ]; then
	    lecho_err "Error : File  $red5pro_installer_conf_jee_container not found!"
	    pause
	fi

	# Replace jee-container config	
	cp -f "$red5pro_installer_conf_jee_container" "$red5pro_conf_jee_container"
}

simple_config_ssl_properties()
{
	lecho "Configuring $red5pro_conf_properties.."

	if [ ! -f "$red5pro_conf_properties" ]; then
	    lecho_err "Error : File  $red5pro_conf_properties not found!"
	    pause
	fi


	if [ ! -f "$red5pro_installer_conf_properties" ]; then
	    lecho_err "Error : File  $red5pro_installer_conf_properties not found!"
	    pause
	fi

	# Dumb replace red5.properties config
	cp -f "$red5pro_installer_conf_properties" "$red5pro_conf_properties"
	sleep 1
}

remove_letsencrypt_ssl_config_domain()
{
	read_ssl_config_domain_properties

	if [ -d "/etc/letsencrypt/live/$letsencrypt_ssl_cert_domain_value" ]; then
		rm -rf "/etc/letsencrypt/live/$letsencrypt_ssl_cert_domain_value"
		lecho "SSL Certificate information for $letsencrypt_ssl_cert_domain_value was removed"
		sleep 2
	fi
	
}

read_ssl_config_domain_properties()
{
	red5pro_conf_properties="$DEFAULT_RPRO_PATH/conf/red5.properties"	
	lecho "Reading SSL config from $red5pro_conf_properties.."

	if [ ! -f "$red5pro_conf_properties" ]; then
	    lecho_err "Error : File  $red5pro_conf_properties not found!"
	    pause
	fi

	local letsencrypt_rtmps_keystorefile_pattern="rtmps.keystorefile*"
	local letsencrypt_rtmps_keystorefile_pattern_replace=""
	local letsencrypt_rtmps_keystorefile_value=
	letsencrypt_ssl_cert_domain_value=

	while IFS= read line
	do
		case "$line" in			
		$letsencrypt_rtmps_keystorefile_pattern) 
			letsencrypt_rtmps_keystorefile_value=$(echo $line | sed -e "s/rtmps.keystorefile=/${letsencrypt_rtmps_keystorefile_pattern_replace}/g")
			break
		;;
		*) continue ;;
		esac
	
	done <"$red5pro_conf_properties"

	# Check if set
	if [ -z ${letsencrypt_rtmps_keystorefile_value+x} ]; then
		false
	else 

		if [[ ${letsencrypt_rtmps_keystorefile_value} == *"letsencrypt"* ]];then
		   lecho "Letsencrypt ssl cert $letsencrypt_rtmps_keystorefile_value found"

		   # /etc/letsencrypt/live/ssltester.flashvisions.com/keystore.jks found
		   letsencrypt_ssl_cert_domain_value=$(echo $letsencrypt_rtmps_keystorefile_value | sed -e "s|/etc/letsencrypt/live/||g" -e "s|/keystore.jks||g")

		    true
		else
		    false
		fi
	fi
	
}

smart_config_ssl_properties()
{
	lecho "Configuring $red5pro_conf_properties.."

	# Patterns and replacements

	# HTTP &  HTTPS

	local http_port_pattern="http.port=.*"
	local http_port_replacement_value="http.port=$RED5PRO_SSL_DEFAULT_HTTP_PORT"
	local https_port_pattern="https.port=.*"
	local https_port_replacement_value="https.port=$RED5PRO_SSL_DEFAULT_HTTPS_PORT"

	# RTMPS

	local rtmps_keystorepass_pattern="rtmps.keystorepass=.*"
	local rtmps_keystorepass_replacement_value="$rpro_ssl_trust_store_rtmps_keystorepass"

	local rtmps_keystorefile_pattern="rtmps.keystorefile=.*"
	local rtmps_keystorefile_replacement_value="$rpro_ssl_trust_store_rtmps_keystorefile"

	local rtmps_truststorepass_pattern="rtmps.truststorepass=.*"
	local rtmps_truststorepass_replacement_value="$rpro_ssl_trust_store_rtmps_truststorepass"

	local rtmps_truststorefile_pattern="rtmps.truststorefile=.*"
	local rtmps_truststorefile_replacement_value="$rpro_ssl_trust_store_rtmps_truststorefie"
	local has_wss_conf=0

	# Websocket configuration

	# For old version of websockets	
	if ! $NEW_RED5PRO_WEBSOCKETS ; then

		local ws_host_pattern="ws.host=.*" 
		local ws_host_replacement_value="ws.host=0.0.0.0"

		local ws_port_pattern="ws.port=.*" 
		local ws_port_replacement_value="ws.port=$RED5PRO_SSL_DEFAULT_WS_PORT"

		local wss_host_pattern="wss.host=.*" 
		local wss_host_replacement_value="wss.host=0.0.0.0"

		local wss_port_pattern="wss.port=.*" 
		local wss_port_replacement_value="wss.port=$RED5PRO_SSL_DEFAULT_WSS_PORT"

		local ws_config_pattern="ws.port=.*"
		local ws_config_replacement_value="$ws_port_replacement_value\n$wss_host_replacement_value\n$wss_port_replacement_value"
		
		# Check if wss is already configured in the file
		while IFS= read line
		do
			case "$line" in			
				$wss_port_pattern) 
				has_wss_conf=1
				break
				;;
				*) continue ;;
				esac		
	
		done <"$red5pro_conf_properties"

	fi

	# First pass - Simple replacements
	sed -i -e "s|$http_port_pattern|$http_port_replacement_value|" -e "s|$https_port_pattern|$https_port_replacement_value|" -e "s|$rtmps_keystorepass_pattern|$rtmps_keystorepass_replacement_value|" -e "s|$rtmps_keystorefile_pattern|$rtmps_keystorefile_replacement_value|" -e "s|$rtmps_truststorepass_pattern|$rtmps_truststorepass_replacement_value|" -e "s|$rtmps_truststorefile_pattern|$rtmps_truststorefile_replacement_value|"   "$red5pro_conf_properties"


	# For old version of websockets	
	if ! $NEW_RED5PRO_WEBSOCKETS ; then
		# Second pass - wss config check & smart replacements
		if [[ $has_wss_conf -eq 1 ]]; then
			sed -i -e "s|$wss_host_pattern|$wss_host_replacement_value|" -e "s|$wss_port_pattern|$wss_port_replacement_value|" "$red5pro_conf_properties"
		else
			sed -i -e "s|$ws_config_pattern|$ws_config_replacement_value|" "$red5pro_conf_properties"
		fi
	fi
}

######################################################################################
############################ RED5PRO OPERATIONS ######################################

modify_jvm_memory()
{
	
	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to $RED5_VERSION_NAME installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi

	check_current_rpro 1

	local red5_sh_file
	if [[ $rpro_exists -eq 1 ]]; then

		red5_sh_file=$rpro_path/$RPRO_RED5SH

		if [ ! -f $red5_sh_file ]; then
	  		lecho_err "CRITICAL ERROR! $red5_sh_file was not found!"
			pause;
		else
			# red5_sh_content=`cat $red5_sh_file`
			lecho "Calculating maximum allocatable memory"
			sleep 1

			# JVM memory allocation
			eval_memory_to_allocate			
			alloc_phymem_string="-Xmx"$alloc_phymem_rounded"g"

			sed -i -e "s/-Xmx2g/$alloc_phymem_string/g" $red5_sh_file # improve this
			lecho "JVM memory size is set to $alloc_phymem_rounded Gb!"
			sleep 1

			if [ ! $# -eq 0 ];  then
				pause
			fi
		fi
	fi
}

# Private
eval_memory_to_allocate()
{
	local low_mem_response
	local low_mem_message

	phymem=$(free -m|awk '/^Mem:/{print $2}') # Value in Mb
	# echo "Total Memory in MB = $phymem"
	local alloc_phymem=$(awk "BEGIN { pc=${phymem}*${RED5PRO_MEMORY_PCT}/100; print int(pc);}") # calculate percentage to allocate
	alloc_phymem=$(bc <<< "scale=1;$alloc_phymem/1024") # Mb to Gb
	alloc_phymem_rounded=$(printf "%.0f" $alloc_phymem) # Round off
	

	if [[ "$alloc_phymem_rounded" -lt 2 ]]; then
		low_mem_message="SEVERE!: System memory is insufficient for running this software. A minimum of 2GB is required for $RED5_VERSION_NAME"
	else 
		if [[ "$alloc_phymem_rounded" -eq 2 ]]; then	

			low_mem_message="WARNING!: System memory is is barely enough for running this software"
		fi
	fi

	if [ -z "$low_mem_message" ]; then

		write_log "Memory $alloc_phymem_rounded GB.Check Ok!"
	else

		if [ $# -eq 0 ];  then		
			read -r -p "$low_mem_message.Do you wish to continue ? [y/N] " low_mem_response
			case $low_mem_response in
			[yY][eE][sS]|[yY]) 
				write_log "Memory $alloc_phymem_rounded GB (not ok) but user wishes to continue installation"
			;;
			*)
			sleep 1
			exit 0
			;;
			esac
		fi	
	fi	

}

# Private
download_latest()
{
	clear

	local rpro_email_valid=0
	local rpro_password_valid=0

	latest_rpro_download_success=0
	rpro_zip=

	lecho "Downloading latest Red5 Pro from red5pro.com"
	
	# create tmp directory
	#dir=`mktemp -d` && cd $dir
	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	# echo $dir
	red5pro_com_login_form	
}

red5pro_com_login_form()
{

	local rpro_form_valid=1
	local try_login_response

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "Please enter your 'red5pro.com' login details"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	
	echo "Enter Email : "
	read rpro_email

	echo "Enter Password : "
	# read rpro_passcode
	read -s rpro_passcode

	# simple validate email
	if isEmailValid "${rpro_email}"; then
		rpro_email_valid=1		
	else
		rpro_form_valid=0
		lecho "Invalid email string!"		
	fi
	
	# simple validate password
	if [ ! -z "$rpro_passcode" -a "$rpro_passcode" != " " ]; then
		rpro_password_valid=1		
	else
		rpro_form_valid=0
		lecho "Invalid password string!"
	fi

	# Permission check
	validatePermissions

	# if all params are valid
	if [ "$rpro_form_valid" -eq "1" ]; then
	
		lecho "Attempting to log in with your credentials"

		# POST to site
		wget --server-response --save-cookies cookies.txt --keep-session-cookies --post-data="email=$rpro_email&password=$rpro_passcode" "https://account.red5pro.com/login" 2>$dir/wsession.txt
		wget_status=$(< $dir/wsession.txt)

		echo "$(cat $RPRO_LOG_FILE)$wget_status" > $RPRO_LOG_FILE	

		# Check http code
		local wget_status_ok=0
		if [[ $wget_status == *"HTTP/1.1 200"* ]] 
		then
			wget_status_ok=1
		fi
		
		# if 200 then proceed
		if [ "$wget_status_ok" -eq "1" ]; then

			echo "Attempting to download latest Red5 Pro archive file to $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

			wget --load-cookies cookies.txt --content-disposition -p  https://account.red5pro.com/download/red5 -O "$RED5PRO_DEFAULT_DOWNLOAD_NAME"

			rpro_zip="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER/$RED5PRO_DEFAULT_DOWNLOAD_NAME"

			if [ -f $rpro_zip ] ; then
				find . -type f -not \( -name '*zip' \) -delete

				latest_rpro_download_success=1
			else
				lecho "Oops!! Seems like the archive was not downloaded properly to disk."
				pause	
			fi
		else
			
			lecho_err "Failed to authenticate with website!"
			read -r -p " -- Retry? [y/N] " try_login_response
			case $try_login_response in
			[yY][eE][sS]|[yY]) 
			download_latest
			;;
			*)
			latest_rpro_download_success=0
			;;
			esac
		fi
		
	else
		lecho_err "Invalid request parameters"
		read -r -p " -- Retry? [y/N] " try_login_response
		case $try_login_response in
		[yY][eE][sS]|[yY]) 
		download_latest
		;;
		*)
		latest_rpro_download_success=0
		;;
		esac
	fi

}

download_from_url()
{
	clear
	
	latest_rpro_download_success=0
	rpro_zip=
	RED5PRO_DOWNLOAD_URL=

	lecho "Downloading $RED5_VERSION_NAME from url"
	
	# create tmp directory
	#dir=`mktemp -d` && cd $dir
	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	if [ -z "$RED5PRO_DOWNLOAD_URL" ]; then
		echo "Enter the $RED5_VERSION_NAME archive file URL source";
		read RED5PRO_DOWNLOAD_URL
	fi

	# Permission check
	validatePermissions

	lecho "Attempting to download $RED5_VERSION_NAME archive file to $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

	wget -O "$RED5PRO_DEFAULT_DOWNLOAD_NAME" "$RED5PRO_DOWNLOAD_URL"

	rpro_zip="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER/$RED5PRO_DEFAULT_DOWNLOAD_NAME"

	if [ -f $rpro_zip ] ; then
		find . -type f -not \( -name '*zip' \) -delete

		latest_rpro_download_success=1
	else
		lecho "Oops!! Seems like the archive was not downloaded properly to disk."
		pause	
	fi

}

# Public
auto_install_rpro()
{
	write_log "Starting Red5 Pro auto-installer"

	red5_zip_install_success=0

	# Install prerequisites
	prerequisites

	# Download red5 zip from red5pro.com
	echo "Preparing to install Red5 Pro from 'red5pro.com'"
	sleep 2
	download_latest

	if [ "$latest_rpro_download_success" -eq 0 ]; then
		lecho_err "Failed to download latest Red5 Pro distribution from 'red5pro.com'. Please contact support!"
		pause
	fi


	if [ -z "$rpro_zip" ]; then
		lecho_err "Downloaded file could not be found or is invalid. Exiting now!"
		pause
	fi

	# Installing red5 from zip downloaded  from red5pro.com

	lecho "Installing Red5 Pro from $rpro_zip"
	sleep 2
	install_rpro_zip $rpro_zip

	if [ "$red5_zip_install_success" -eq 0 ]; then		
		lecho_err "Failed to install Red5 Pro distribution. Something went wrong!! Try again or contact support!"
	fi

	
	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}

auto_install_rpro_url()
{
	write_log "Starting $RED5_VERSION_NAME auto-installer"

	red5_zip_install_success=0

	# Install prerequisites
	prerequisites	

	# Download red5 zip from url
	echo "Preparing to install $RED5_VERSION_NAME from $RED5PRO_DOWNLOAD_URL"
	sleep 2
	download_from_url

	if [ "$latest_rpro_download_success" -eq 0 ]; then
		lecho_err "Failed to download $RED5_VERSION_NAME distribution from $RED5PRO_DOWNLOAD_URL. Please contact support!"
		pause
	fi


	if [ -z "$rpro_zip" ]; then
		lecho_err "Downloaded file could not be found or is invalid. Exiting now!"
		pause
	fi

	# Installing red5 from zip downloaded  from red5pro.com

	lecho "Installing $RED5_VERSION_NAME from $rpro_zip"
	sleep 2
	install_rpro_zip $rpro_zip $RED5PRO_DOWNLOAD_URL

	if [ "$red5_zip_install_success" -eq 0 ]; then		
		lecho_err "Failed to install $RED5_VERSION_NAME distribution. Something went wrong!! Try again or contact support!"
	fi

	
	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}

# Public
register_rpro_as_service()
{
	check_current_rpro 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then

		write_log "Registering service for $RED5_VERSION_NAME"
		if [ -f "$target" ]; then
		lecho "Service already exists. Do you wish to re-install ?" 
		read -r -p "Are you sure? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 
		register_rpro_service
		;;
		*)
		lecho "Service installation cancelled"
		;;
		esac

		else
		register_rpro_service
		fi
	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}

# Public
unregister_rpro_as_service()
{
	check_current_rpro 0

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$target" ]; then
			lecho "Service does not exists. Nothing to remove" 
		else
			unregister_rpro_service
		fi

	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}

# Public
install_rpro_zip()
{
	red5_zip_install_success=0

	# Install prerequisites
	# prerequisites [ extra not needed ]
			
	clear
	lecho "Installing $RED5_VERSION_NAME from zip"
	

	if [ $# -eq 0 ]; then
		echo "Enter the full path to $RED5_VERSION_NAME distribution archive"
		read rpro_zip_path
	else 
		rpro_zip_path=$1
	fi

	write_log "Installing $RED5_VERSION_NAME from zip $rpro_zip_path"

	if ! isValidArchive $rpro_zip_path; then
		lecho "Cannot process archive $rpro_zip_path"
		pause;
	fi

	local filename=$(basename "$rpro_zip_path")
	local extension="${filename##*.}"
	filename="${filename%.*}"

	lecho "Attempting to install $RED5_VERSION_NAME from zip"

	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	unzip_dest="$dir/$filename"

	check_current_rpro 1
	
	if [ "$rpro_exists" -eq 1 ]; then

		lecho "An existing $RED5_VERSION_NAME installation was found at install destination.If you continue this will be replaced. The old installation will be backed up to $RPRO_BACKUP_HOME"

		sleep 1
		echo "Warning! All file(s) and folder(s) at $DEFAULT_RPRO_PATH will be removed permanently"
		read -r -p "Do you wish to continue? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY])

		# backup Red5 Pro
		backup_rpro

		if [ $rpro_backup_success -eq 0 ]; then
			# proceed to install new Red5 Pro
			lecho_err "Failed to create a backup of your existing $RED5_VERSION_NAME installation"
			pause
		fi	

		# remove rpro service
		unregister_rpro_service

		# check remove old files
		rm -rf $DEFAULT_RPRO_PATH

		;;
		*)
		lecho "Operation cancelled"
		pause
		;;
		esac	
	fi

	lecho "Unpacking archive $rpro_zip_path to install location..."

	if [ -d "$unzip_dest" ]; then
	  rm -rf $unzip_dest
	fi
	
	
	if ! unzip $rpro_zip_path -d $unzip_dest; then
		lecho_err "Failed to extract zip. Possible invalid archive"
		pause;
	fi


	if [ ! -d "$unzip_dest" ]; then
		lecho_err "Could not create output directory."
		pause;
	fi

	# Move to actual install location 
	rpro_loc=$DEFAULT_RPRO_PATH

	lecho "Moving files to install location : $rpro_loc"

	# Identify archive type and move accordingly

	if [[ $# -gt 1 ]]; then

		if isSingleLevel $unzip_dest; then
			
			# Single level archive -> top level manual zip
			if [ ! -d "$rpro_loc" ]; then
			  mkdir -p $rpro_loc
			fi

			mv -v $unzip_dest/* $rpro_loc

		else
			# Two level archive -> like at red5pro.com
			rpro_loc=$DEFAULT_RPRO_PATH
			mv -v $unzip_dest/* $rpro_loc
		fi


	else
		# Move to actual install location 
		rpro_loc=$DEFAULT_RPRO_PATH
		mv -v $unzip_dest/* $rpro_loc
	fi

	# DEFAULT_RPRO_PATH=/usr/local/red5pro

	lecho "Setting permissions ..."

	sleep 1

#   commenting out, as these are unnecessary and make the entire directory path executable
#	chmod -R 755 $rpro_loc	
#	chmod -R ugo+w $rpro_loc

	chmod +x $rpro_loc/*.sh

	# set path
	lecho "Setting RED5_HOME"
	sleep 1
	export RED5_HOME=$rpro
 

	# Clear tmp directories - IMPORTANT
	if [ "$RED5PRO_INSTALLER_OPERATIONS_CLEANUP" -eq 1 ]; then
		lecho "cleaning up ..."
		sleep 1

		# Delete unzipped content
		rm -rf $unzip_dest

		# Delete zip
		rm -rf $rpro_zip_path
	fi

	sleep 1	

	if [ ! -d "$rpro_loc" ]; then
		lecho "Could not install $RED5_VERSION_NAME at $rpro_loc"
		pause
	else
		echo "All done! ..."
		lecho "$RED5_VERSION_NAME installed at  $rpro_loc"
		red5_zip_install_success=1
	fi

	# Install additional libraries
	postrequisites

	# JVM memory update
	modify_jvm_memory


	# Installing red5 service
	if $RED5PRO_INSTALL_AS_SERVICE; then			

		echo "For $RED5_VERSION_NAME to autostart with operating system, it needs to be registered as a service"
		read -r -p "Do you want to register $RED5_VERSION_NAME service now? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 
		
			lecho "Registering $RED5_VERSION_NAME as a service"

			sleep 2
			register_rpro_service
		
			if [ "$rpro_service_install_success" -eq 0 ]; then
			lecho_err "Failed to register $RED5_VERSION_NAME service. Something went wrong!! Try again or contact support!"
			pause
			fi

			# All Done
			lecho "$RED5_VERSION_NAME service is now installed on your system. You can start / stop it with from the menu".
		;;
		*)
			# Rejected
			lecho "Service installation was cancelled. You can manually register $RED5_VERSION_NAME as service from the menu.".
		;;
		esac

		
	else
		
		lecho "$RED5_VERSION_NAME service auto-install is disabled. You can manually register $RED5_VERSION_NAME as service from the menu.".
	fi
	

	# Moving to home directory	
	cd ~

	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}

isValidArchive()
{
	local archive_path=$1

	if [ ! -f "$archive_path" ]; then
		lecho "Invalid archive file path $archive_path"
		false
	else
		local filename=$(basename "$archive_path")

		local extension="${filename##*.}"
		filename="${filename%.*}"

		local filesize=$(stat -c%s "$archive_path")
		
		if [ "$filesize" -lt 30000 ]; then
			lecho "Invalid archive file size detected for $archive_path. Probable corrupt file!"
			false
		else
			case "$extension" in 
			zip|tar|gz*) 
			    true
			    ;;	
			*)
			    lecho "Invalid archive type $extension"
			    false
			    ;;
			esac
		fi
	fi
}

isSingleLevel()
{
	local rpro_tmp=$1
	local count=$(find $rpro_tmp -maxdepth 1 -type d | wc -l)

	if [ $count -gt 2 ]; then
		true
	else
		false
	fi
}

# Public
register_rpro_service()
{
	# Permission check
	validatePermissions

	if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
	   register_rpro_service_v1
	else
	   register_rpro_service_v2
	fi	
}

# Public
unregister_rpro_service()
{
	# Permission check
	validatePermissions
	
	if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
	   unregister_rpro_service_v1
	else
	   unregister_rpro_service_v2
	fi	
}

######################### V1 #########################

# Private
register_rpro_service_v1()
{

	rpro_service_install_success=0

	lecho "Preparing to install service..."
	sleep 2

service_script="#!/bin/sh
### BEGIN INIT INFO
# chkconfig: 2345 85 85
# description: $RED5_VERSION_NAME streaming server
# Provides:          $RED5_VERSION_NAME
# Required-Start:    \$local_fs \$network
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: $RED5_VERSION_NAME
# processname: red5
### END INIT INFO

PROG=red5
RED5_HOME=$DEFAULT_RPRO_PATH
DAEMON=\$RED5_HOME/\$PROG.sh
PID=$PID

start() {
  # check to see if the server is already running
  if netstat -an | grep ':5080' > /dev/null 2>&1 ; then
    while netstat -an | grep ':5080' > /dev/null 2>&1 ; do
      # wait 5 seconds and test again
      sleep 5
    done
  fi
  cd \${RED5_HOME} && ./red5.sh > /dev/null 2>&1 &
}

stop() {
  cd \${RED5_HOME} && ./red5-shutdown.sh > /dev/null 2>&1 &
}

case \"\$1\" in
  start)
    start
    exit 1
  ;;
  stop)
    stop
    exit 1
  ;;
  **)
    echo \"Usage: \$0 {start|stop}\" 1>&2
    exit 1
  ;;

esac"

	lecho "Writing service script"
	sleep 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	touch "$target"

	# write script to file
	echo "$service_script" > "$target"

	sleep 1

	# make service file executable
	chmod 644 "$target"

	if isDebian; then
	register_rpro_service_deb	
	else
	register_rpro_service_rhl
	fi	


	lecho "$RED5_VERSION_NAME service installed successfully!"
	rpro_service_install_success=1
}

# Private
register_rpro_service_deb()
{
	lecho "Registering service \"$RPRO_SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $RPRO_SERVICE_NAME defaults

	lecho "Enabling service \"$RPRO_SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $RPRO_SERVICE_NAME enable
}

# Private
register_rpro_service_rhl()
{
	lecho "Registering service \"$RPRO_SERVICE_NAME\""
	sleep 1

	systemctl daemon-reload
	

	lecho "Enabling service \"$RPRO_SERVICE_NAME\""
	sleep 1

	systemctl enable $RPRO_SERVICE_NAME
}

# Private
unregister_rpro_service_v1()
{
	rpro_service_remove_success=0
	
	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	lecho "Preparing to remove service..."
	sleep 2


	if [ -f "$target" ];	then
	

		# 1. Terminate service if running

		# 2. check PID file and check pid
		

		if isDebian; then
		unregister_rpro_service_deb	
		else
		unregister_rpro_service_rhl
		fi

		rm -rf "$target"

		lecho "Service removed successfully"
		rpro_service_remove_success=0
	
	else
		lecho "$RED5_VERSION_NAME service was not found"
	fi
}

# Private
unregister_rpro_service_deb()
{
	lecho "Disabling service \"$RPRO_SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $RPRO_SERVICE_NAME disable

	lecho "Removing service \"$RPRO_SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $RPRO_SERVICE_NAME remove
}

# Private
unregister_rpro_service_rhl()
{
	lecho "Disabling service \"$RPRO_SERVICE_NAME\""
	sleep 1

	systemctl disable $RPRO_SERVICE_NAME


	lecho "Removing service \"$RPRO_SERVICE_NAME\""
	sleep 1
}

# Private
start_red5pro_service_v1()
{
	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"
	"$target" start /dev/null 2>&1 &
	sleep 15
}

# Private
stop_red5pro_service_v1()
{
	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"
	"$target" stop /dev/null 2>&1 &
}

# Private
restart_red5pro_service_v1()
{
	lecho "This feature is not supported in V1 service installer!. To 'restart' please stop the service and then start it again."
}

####################### V2 #############################

# Private
register_rpro_service_v2()
{
	rpro_service_install_success=0


	lecho "Preparing to install service..."
	sleep 2

	# JVM memory allocation
	eval_memory_to_allocate 1
		
	# If upfront allocation 'selected' then min = max else min = 256m 
	if $RED5PRO_UPFRONT_MEMORY_ALLOC; then			
		JVM_MEMORY_ALLOC_MIN="-Xms"$alloc_phymem_rounded"g"
	else
		JVM_MEMORY_ALLOC_MIN="-Xms256m"
	fi
	
	JVM_MEMORY_ALLOC="-Xmx"$alloc_phymem_rounded"g"

	# Installing service manager
	prerequisites_jsvc

	if isDebian; then
	JAVA_ENV=/usr/lib/jvm/java-8-openjdk-amd64	
	else
	JAVA_ENV=/usr/lib/jvm/jre-1.8.0-openjdk
	fi

#######################################################

service_script="[Unit]
Description=$RED5_VERSION_NAME
After=syslog.target network.target

[Service]
Type=forking
Environment=PID=$PID
Environment=JAVA_HOME=$JAVA_ENV
LimitNOFILE=65536
Environment=RED5_HOME=$DEFAULT_RPRO_PATH
WorkingDirectory=$DEFAULT_RPRO_PATH
ExecStart=/usr/bin/jsvc -debug \\
    -home \${JAVA_HOME} \\
    -cwd \${RED5_HOME} \\
    -cp \${RED5_HOME}/commons-daemon-1.0.15.jar:\${RED5_HOME}/red5-service.jar:\${RED5_HOME}/conf \\
    -Dred5.root=\${RED5_HOME} \\
    -Djava.library.path=\${RED5_HOME}/lib/amd64-Linux-gpp/jni \\
    -Djava.security.debug=failure -Djava.security.egd=file:/dev/./urandom \\
    -Dcatalina.home=\${RED5_HOME} -Dcatalina.useNaming=true \\
    -Dorg.terracotta.quartz.skipUpdateCheck=true \\
    $JVM_MEMORY_ALLOC_MIN $JVM_MEMORY_ALLOC -Xverify:none \\
    -XX:+TieredCompilation -XX:+UseBiasedLocking \\
    -XX:MaxMetaspaceSize=128m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC \\
    -XX:InitialCodeCacheSize=8m -XX:ReservedCodeCacheSize=32m \\
    -XX:CMSInitiatingOccupancyFraction=60 \\
    -outfile \${RED5_HOME}/log/jsvc-service.log -errfile \${RED5_HOME}/log/jsvc-error.log \\
    -wait 60 \\
    -umask 011 \\
    -pidfile \${PID} org.red5.daemon.EngineLauncher 9999
ExecStop=/usr/bin/jsvc -stop -pidfile \${PID} org.red5.daemon.EngineLauncher 9999

[Install]
WantedBy=multi-user.target
"

#######################################################


	lecho "Writing service script"
	sleep 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	touch "$target"

	# write script to file
	echo "$service_script" > "$target"

	# make service file executable
	chmod 644 "$target"

	# register_rpro_service_generic_v2

	lecho "$RED5_VERSION_NAME service installed successfully!"
	rpro_service_install_success=1	
}

# Private
register_rpro_service_generic_v2()
{

	lecho "Registering service \"$RPRO_SERVICE_NAME\""
	sleep 1	

	# Reload daemon 
	systemctl daemon-reload

	lecho "Enabling service \"$RPRO_SERVICE_NAME\""

	# enable service
	systemctl enable "$RPRO_SERVICE_NAME"
}

# Private
unregister_rpro_service_generic_v2()
{
	lecho "Unregistering service \"$RPRO_SERVICE_NAME\""
	sleep 1	

	# Reload daemon 
	systemctl daemon-reload

	lecho "Disabling service \"$RPRO_SERVICE_NAME\""

	# disaable service
	systemctl disable "$RPRO_SERVICE_NAME"
}

# Private
unregister_rpro_service_v2()
{
	rpro_service_remove_success=0
	
	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	lecho "Preparing to remove service..."
	sleep 2

	if [ -f "$target" ];	then
	
		unregister_rpro_service_generic_v2

		# remove service
		rm -f "$target"

		lecho "Service removed successfully"
		rpro_service_remove_success=0
	
	else
		lecho "$RED5_VERSION_NAME service was not found"
	fi
}

# Private
start_red5pro_service_v2()
{
	systemctl start "$RPRO_SERVICE_NAME"
}

# Private
stop_red5pro_service_v2()
{
	systemctl stop "$RPRO_SERVICE_NAME"
}

# Private
restart_red5pro_service_v2()
{
	systemctl restart "$RPRO_SERVICE_NAME"
}

############################################################

is_service_installed()
{
	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"
	if [ ! -f "$target" ];	then
	false
	else
	true
	fi
}

start_red5pro_service()
{
	cd ~

	check_current_rpro 1 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$target" ];	then
			lecho "It seems $RED5_VERSION_NAME service was not installed. Please register $RED5_VERSION_NAME service from the menu for best results."
			lecho " Attempting to start $RED5_VERSION_NAME using \"red5.sh\""

			if !(is_running_red5pro_service_v1); then
				cd $DEFAULT_RPRO_PATH && exec $DEFAULT_RPRO_PATH/red5.sh > /dev/null 2>&1 &
			else
				lecho "Server is already running!" 
			fi			

		else
			lecho "$RED5_VERSION_NAME service was found at $target"
			lecho " Attempting to start service"

			if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
				
				if !(is_running_red5pro_service 1); then
					start_red5pro_service_v1
				else
					lecho "Server is already running!" 
				fi
			else		

				if !(is_running_red5pro_service 1); then
					start_red5pro_service_v2
				else
					lecho "Server is already running!" 
				fi

			fi
		
		fi
	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}

stop_red5pro_service()
{
	cd ~

	check_current_rpro 1 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then	


		if [ ! -f "$target" ];	then
			lecho "It seems $RED5_VERSION_NAME service was not installed. Please register $RED5_VERSION_NAME service from the menu for best results."
			lecho " Attempting to stop using \"red5-shutdown.sh\" (if running)"

			if is_running_red5pro_service_v1; then				
				cd $DEFAULT_RPRO_PATH && exec $DEFAULT_RPRO_PATH/red5-shutdown.sh > /dev/null 2>&1 &
				lecho "Note : it may take a few seconds for the server to shut down."
				sleep 10
			else
				lecho "Server is not running!" 
			fi	
		else
			lecho "$RED5_VERSION_NAME service was found at $RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME."
			lecho "Attempting to stop $RED5_VERSION_NAME service"

			if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then	

				if is_running_red5pro_service 1; then
					stop_red5pro_service_v1
				else
					lecho "Server is not running!" 
				fi
				
			else
				if is_running_red5pro_service 1; then
					stop_red5pro_service_v2
				else
					lecho "Server is not running!" 
				fi
			fi
		fi
	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}

restart_red5pro_service()
{
	cd ~
	
	check_current_rpro 1 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$target" ];	then
			lecho "It seems $RED5_VERSION_NAME service was not installed. Please register $RED5_VERSION_NAME service from the menu for to activate this feature."
		else
			lecho "$RED5_VERSION_NAME service was found at $target."
			lecho "Attempting to restart $RED5_VERSION_NAME service"

			if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
				restart_red5pro_service_v1
			else
				restart_red5pro_service_v2
			fi
		fi
	fi


	if [ $# -eq 0 ]
	  then
	    pause
	fi
}

is_running_red5pro_service_v2()
{
	systemctl status "$RPRO_SERVICE_NAME" | grep 'active (running)' &> /dev/null
	if [ $? == 0 ]; then
	   true
	else
	   false	
	fi
}

is_running_red5pro_service_v1()
{
	local red5_grep=$(ps aux | grep red5)	
	echo "$red5_grep" | grep 'org.red5.server.Bootstrap' &> /dev/null

	if [ $? == 0 ]; then
	   true
	else
	   false	
	fi
}

is_running_red5pro_service()
{
	cd ~
	
	local rpro_running=0
	check_current_rpro 1 1

	local target="$RPRO_SERVICE_LOCATION/$RPRO_SERVICE_NAME"

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$target" ];	then
			lecho "It seems $RED5_VERSION_NAME service was not installed. Please register $RED5_VERSION_NAME service from the menu for to activate this feature."
		else			

			if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
				if is_running_red5pro_service_v1; then
					rpro_running=1
				fi

			else
				if is_running_red5pro_service_v2; then
					rpro_running=1
				fi				
			fi
		fi
	fi


	if [ $# -eq 0 ]; then
	    pause
	else
	    if [ "$rpro_running" -eq 1 ]; then
		true
	    else
		false
	    fi
	fi
}

remove_rpro_installation()
{
	local rpro_exists=0
	local check_silent=0

	lecho "Looking for $RED5_VERSION_NAME at install location..."
	sleep 2

	if [ ! -d $DEFAULT_RPRO_PATH ]; then
  		lecho "No $RED5_VERSION_NAME installation found at install location : $DEFAULT_RPRO_PATH"
	else
		red5pro_ini="$DEFAULT_RPRO_PATH/conf/red5.ini" 

		if [ ! -f $red5pro_ini ]; then
			check_red5_os_version
			if $RED5PRO_OPEN_SOURCE ; then
				if [ ! "$check_silent" -eq 1 ] ; then
					lecho "Red5 Open source was found at install location : $DEFAULT_RPRO_PATH"
					rpro_exists=1
				fi
			else
				lecho "There were files found at install location : $DEFAULT_RPRO_PATH, but the installation might be broken !. I could not locate version information"
			fi
		else
			rpro_exists=1		
		fi
	fi


	if [ "$rpro_exists" -eq 1 ] ; then

		echo "$RED5_VERSION_NAME installation found at install location : $DEFAULT_RPRO_PATH"
		echo "Warning! All file(s) and folder(s) at $DEFAULT_RPRO_PATH will be removed permanently"
		read -r -p "Are you sure? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 

		# Stop if running
		stop_red5pro_service 1

		# remove rpro service
		unregister_rpro_service

		# check remove folder
		rm -rf $DEFAULT_RPRO_PATH

		unset RED5_HOME

		if [ ! -d "$DEFAULT_RPRO_PATH" ]; then
			lecho "Red5 installation was removed"
		fi
		;;
		*)
		lecho "Uninstall cancelled"
		;;
		esac
	fi


	if [ $# -eq 0 ]; then
		pause		
	fi
	
}

check_current_rpro()
{
	rpro_exists=0
	local check_silent=0

	# IF second param is set then turn on silent mode quick check
	if [ $# -eq 2 ]; then
		check_silent=1		
	fi


	if [ ! "$check_silent" -eq 1 ] ; then
		lecho "Looking for $RED5_VERSION_NAME at install location..."
		sleep 2
	fi


	if [ ! -d $DEFAULT_RPRO_PATH ]; then
		if [ ! "$check_silent" -eq 1 ] ; then
  		lecho "No $RED5_VERSION_NAME installation found at install location : $DEFAULT_RPRO_PATH"
		fi
	else
		red5pro_ini="$DEFAULT_RPRO_PATH/conf/red5.ini" 

		if [ ! -f $red5pro_ini ]; then

			check_red5_os_version
			if $RED5PRO_OPEN_SOURCE ; then
				if [ ! "$check_silent" -eq 1 ] ; then
				lecho "Red5 Open source was found at install location : $DEFAULT_RPRO_PATH"
				fi
				rpro_exists=1
			else
				lecho "There were files found at install location : $DEFAULT_RPRO_PATH, but the installation might be broken !. I could not locate version information"
				rpro_exists=0
			fi		
		
		else
			rpro_exists=1

		if [ ! "$check_silent" -eq 1 ] ; then
		lecho "$RED5_VERSION_NAME installation found at install location : $DEFAULT_RPRO_PATH"
		fi

		local pattern='server.version*'
		local replace=""
		while IFS= read line
		do
			case "$line" in			
			$pattern) 
				if [ ! "$check_silent" -eq 1 ] ; then					
					red5pro_server_version=$(echo $line | sed -e "s/server.version=/${replace}/g")
					lecho "$RED5_VERSION_NAME build info : $red5pro_server_version" 
					check_websockets_version
					break
				fi
			;;
			*) continue ;;
			esac
		
		done <"$red5pro_ini"

		fi
	fi

	if [ $# -eq 0 ]; then
		pause		
	fi


	# return true or false
	if [ ! "$rpro_exists" -eq 1 ] ; then
		true
	else
		false
	fi

}


check_red5_os_version()
{
	local LIB_DIR="$DEFAULT_RPRO_PATH/lib"
	local red5_commons_file="$LIB_DIR/red5-server-common-*"

	# Checking if red5 open source is being used
	RED5PRO_OPEN_SOURCE=false

	if ls $red5_commons_file 1> /dev/null 2>&1; then
		
		# Additional check for new websocket plugin version
		if ls $red5_commons_file 1> /dev/null 2>&1; then
			local red5_commons_file_name
			red5_commons_file_name=$(ls $red5_commons_file)
			red5_commons_file_name=$(basename "$red5_commons_file_name")
			local second=""
			red5_commons_file_name=${red5_commons_file_name//red5-server-common-/$second}
			red5_commons_file_name=${red5_commons_file_name//.jar/$second}
			red5pro_server_version=$red5_commons_file_name
			RED5PRO_OPEN_SOURCE=true
			configure_for_red5_os
		fi

		write_log "Open source red5 found"		
	else
		write_log "Could not identify server version"
	fi

	# if no params supplied then return normally else return valuee
	if [ $# -gt 0 ]; then
		if $RED5PRO_OPEN_SOURCE ; then
			true
		else
			false
		fi		
	fi

}

check_websockets_version()
{
	local PLUGINS_DIR="$DEFAULT_RPRO_PATH/plugins"
	local websocket_plugin_file="$PLUGINS_DIR/websocket-*"
	local tomcat_plugin_file="$PLUGINS_DIR/tomcatplugin-*"

	# Checking if websocket plugin exists

	if ls $websocket_plugin_file 1> /dev/null 2>&1; then
		
		# Additional check for new websocket plugin version
		#if ls $tomcat_plugin_file 1> /dev/null 2>&1; then
		#	echo $tomcat_plugin_file
		#fi

		write_log "Build uses old websocket implementation"
		NEW_RED5PRO_WEBSOCKETS=false
		RED5PRO_SSL_DEFAULT_WS_PORT=$RED5PRO_SSL_DEPRECATED_WS_PORT
		RED5PRO_SSL_DEFAULT_WSS_PORT=$RED5PRO_SSL_DEPRECATED_WSS_PORT		
	else
		write_log "Build uses new websocket implementation"
		NEW_RED5PRO_WEBSOCKETS=true
		RED5PRO_SSL_DEFAULT_WS_PORT=$RED5PRO_SSL_DEFAULT_HTTP_PORT
		RED5PRO_SSL_DEFAULT_WSS_PORT=$RED5PRO_SSL_DEFAULT_HTTPS_PORT
	fi

	# if no params supplied then return normally else return valuee
	if [ $# -gt 0 ]; then
		if $NEW_RED5PRO_WEBSOCKETS ; then
			true
		else
			false
		fi		
	fi

}

######################################################################################
####################### RED5PRO UPGRADE OPERATION MENU ###############################

## PRIVATE ###
restore_rpro()
{
	lecho "Not implemented"	
}

## PRIVATE ###
backup_rpro()
{
	# Permission check
	validatePermissions

	rpro_backup_success=0


	if [ ! -d "$RPRO_BACKUP_HOME" ]; then
	  mkdir -p $RPRO_BACKUP_HOME
	  chmod ugo+w $RPRO_BACKUP_HOME
	fi

	
	if [ -d "$RPRO_BACKUP_HOME" ]; then
	  
		lecho "Starting backup procedure..."
		sleep 2

		# echo "Stopping $RED5_VERSION_NAME if it was running..."
		stop_red5pro_service 1
		sleep 2

		lecho "Backing up... "
		sleep 2

		# Create backup folder
		t_now=`date +%Y-%m-%d-%H-%M-%S`
		RPRO_BACKUP_FOLDER="$RPRO_BACKUP_HOME/$t_now"

		# Copy all files to backup folder
		cp -R $DEFAULT_RPRO_PATH $RPRO_BACKUP_FOLDER
		sleep 2

		# Show notice to user that back up was saved
		if [ -d "$RPRO_BACKUP_FOLDER" ]; then
			if [ -f $red5pro_ini ]; then
				printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
				lecho "Your active $RED5_VERSION_NAME installation was backed up successfully to $RPRO_BACKUP_FOLDER"
				lecho "You can restore any necessary file(s) later from the backup manually."
				printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
				chmod -R ugo+w $RPRO_BACKUP_FOLDER
				rpro_backup_success=1
			else
				lecho_err "Something went wrong!! Perhaps files were not copied properly"
			fi
		else
			lecho_err "WARNING! Could not create backup destination directory"
		fi

		empty_pause

	else
		lecho_err "Failed to create backup directory. Backup will be skipped..."

	fi

}

upgrade()
{
	lecho_err "Not implemented"
}

## PRIVATE ###
upgrade_clean()
{
	lecho_err "Not implemented"
}

######################################################################################
############################ LICENSE OPERATIONS ######################################

check_license()
{
	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to $RED5_VERSION_NAME installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi

	check_current_rpro 1
	if [[ $rpro_exists -eq 1 ]]; then

		local lic_file=$rpro_path/LICENSE.KEY

		write_log "Checking license"

		if [ ! -f $lic_file ]; then
	  		lecho "No license file found!. Please install a license."
		else
			local value=`cat $lic_file`
			echo "Current license : $value"
			write_log "license found!"
		fi
	fi
	
	pause_license;	
}

set_update_license()
{

	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to $RED5_VERSION_NAME installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi

	check_current_rpro 1
	if [[ $rpro_exists -eq 1 ]]; then

		local lic_file="$rpro_path/LICENSE.KEY"
		local lic_new=1

		if [ ! -f $lic_file ]; then
	  		echo "Installing license code : Please enter new license code and press [ Enter ]."
			read license_code
			write_log "Installing license code"
			if [ ! -f "$lic_file" ] ; then
		 		# if not create the file
				write_log "Creating license file $lic_file"
		 		touch "$lic_file"
		     	fi
		else
			lic_new=0
			cat $lic_file | while read line
			do
			echo "a line: $line"
			done
			echo "Updating license : Please enter new license code and press [ Enter ]."
			read license_code			
		fi

		local license_code=$(echo $license_code | tr '[a-z]' '[A-Z]')
		write_log "Writing license code to file $license_code"
		printf $license_code > $lic_file;

		if [ $lic_new -eq 1 ]; then
		lecho "License installed"
		else
		lecho "License updated"
		fi
	fi

	pause_license;	
}

######################################################################################
############################ LICENSE MENU ############################################

show_licence_menu()
{
	licence_menu
	license_menu_read_options
}

licence_menu()
{

	cls

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	echo -e "\e[44m ----------- MANAGE LICENSE ------------- \e[m"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "1. ADD OR UPDATE LICENSE"
	echo "2. VIEW LICENSE"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "0. BACK"
	echo "			  "   
}

license_menu_read_options(){

	local choice
	read -p "Enter choice [ 1 - 2 | 0 to go back ] " choice

	case $choice in
		1) set_update_license 0 ;;
		2) check_license 0 ;;
		0) 
		if [ $RPRO_MODE -eq  1]; then 
		show_utility_menu 
		else 
		show_simple_menu 
		fi 
		;;
		*) echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_licence_menu ;;
	esac
}

######################################################################################
############################ ADVANCE OPERATION MENU ################################

show_utility_menu()
{
	advance_menu
	advance_menu_read_options
}

advance_menu()
{
	cls

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	echo -e "\e[44m $RED5_VERSION_NAME INSTALLER - UTILITY MODE \e[m"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "1. --- CHECK EXISTING $RED5_VERSION_NAME INSTALLATION"
	echo "2. --- WHICH JAVA AM I USING ?		 "
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "0. --- BACK					 "
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "X. --- Exit					 "
	echo "                             		 	 "

}

advance_menu_read_options(){

	local choice

	# Permission check
	validatePermissions

	read -p "Enter choice [ 1 - 2 | 0 to go back | X to exit ] " choice

	case $choice in
		1) cls && check_current_rpro ;;
		2) cls && check_java 1 ;;
		0) cls && main ;;
		[xX])  exit 0;;
		*) echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_utility_menu ;;
	esac
}

######################################################################################
############################ SIMPLE OPERATION MENU ################################

show_simple_menu()
{
	simple_menu
	simple_menu_read_options
}

simple_menu()
{

	cls

	check_current_rpro 1 1

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo -e "\e[44m $RED5_VERSION_NAME INSTALLER - BASIC MODE \e[m"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	if [ "$RED5_OPEN_SOURCE" -eq "1" ]; then
		echo -e "1. --- \e[9mINSTALL LATEST Red5 Pro\e[0m"
	else
		echo "1. --- INSTALL LATEST $RED5_VERSION_NAME		"
	fi	

	if [ "$RED5_OPEN_SOURCE" -eq "1" ]; then
		echo "2. --- INSTALL $RED5_VERSION_NAME FROM URL (UPLOADED ARCHIVE / GITHUB)	"
	else
		echo "2. --- INSTALL $RED5_VERSION_NAME FROM URL (UPLOADED ARCHIVE)	"
	fi
	


	if [[ $rpro_exists -eq 1 ]]; then

		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
		echo "3. --- REMOVE $RED5_VERSION_NAME INSTALLATION	"

		if [ "$RED5_OPEN_SOURCE" -eq "1" ]; then
			echo -e "4. --- \e[9mADD / UPDATE $RED5_VERSION_NAME LICENSE\e[0m	"
		else
			echo "4. --- ADD / UPDATE $RED5_VERSION_NAME LICENSE	"
		fi



		if [ "$RED5_OPEN_SOURCE" -eq "1" ]; then
			echo -e "5. --- \e[9mSSL CERT INSTALLER (Letsencrypt)\e[0m 		"
		else
			echo "5. --- SSL CERT INSTALLER (Letsencrypt) 		"
		fi	

		
		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		echo "6. --- START $RED5_VERSION_NAME			"
		echo "7. --- STOP $RED5_VERSION_NAME			"		
		#printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
		#echo "------ $RED5_VERSION_NAME SERVICE OPTIONS		"
		if is_service_installed; then
		echo "8. --- RESTART $RED5_VERSION_NAME			"
		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
		echo "9. --- REMOVE SERVICE			"
		else
		printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
		echo "8. --- INSTALL SERVICE			"
		fi

	fi

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "0. --- BACK"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo "X. --- Exit				"
	echo "                             		"

}

simple_menu_read_options(){

	local choice

	# Permission check
	validatePermissions

	if [[ $rpro_exists -eq 1 ]]; then
		if is_service_installed; then
		read -p "Enter choice [ 1 - 9 | 0 to go back | X to exit ] " choice
		else
		read -p "Enter choice [ 1 - 8 | 0 to go back | X to exit ] " choice
		fi
	else
		read -p "Enter choice [ 1 - 2 | 0 to go back | X to exit ] " choice
	fi
	
	case $choice in
		# 1) check_current_rpro ;;
		1) 
			if [ ! "$RED5_OPEN_SOURCE" -eq "1" ]; then
				cls && auto_install_rpro
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		2) cls && auto_install_rpro_url ;;
		3) 
			if [[ $rpro_exists -eq 1 ]]; then
				cls && remove_rpro_installation 
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		4) 
			if [ ! "$RED5_OPEN_SOURCE" -eq "1" ]; then
				if [[ $rpro_exists -eq 1 ]]; then
					cls && show_licence_menu
				else
					echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
				fi
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		5) 
			if [ ! "$RED5_OPEN_SOURCE" -eq "1" ]; then
				if [[ $rpro_exists -eq 1 ]]; then
					cls && rpro_ssl_installer
				else
					echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
				fi
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		6) 

			if [[ $rpro_exists -eq 1 ]]; then
				cls && start_red5pro_service
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		7) 

			if [[ $rpro_exists -eq 1 ]]; then
				cls && stop_red5pro_service
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		8)
			if is_service_installed; then
				if [[ $rpro_exists -eq 1 ]]; then
					cls && restart_red5pro_service
				else
					echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
				fi
			else
				cls && register_rpro_as_service
			fi
			;;
		9)
			if is_service_installed; then
				cls && unregister_rpro_as_service
			else
				echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu
			fi
			;;
		0) cls && main ;;
		[xX])  exit 0;;
		*) echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && show_simple_menu ;;
	esac
}

######################################################################################
################################ INIT FUNCTIONS ######################################

load_configuration()
{
	sudo sleep 0

	if [ ! -f $RPRO_CONFIGURATION_FILE ]; then

		echo -e "\e[41m CRITICAL ERROR!! - Configuration file not found!\e[m"
		echo -e "\e[41m Exiting...\e[m"
		exit 1
	fi

	# Load config values
	source "$RPRO_CONFIGURATION_FILE"
	
	# Open source installation mode
	if [ "$RED5_OPEN_SOURCE" -eq "1" ]; then
		configure_for_red5_os
	fi

	JAVA_32_BIT="$JAVA_JRE_DOWNLOAD_URL/$JAVA_32_FILENAME"
	JAVA_64_BIT="$JAVA_JRE_DOWNLOAD_URL/$JAVA_64_FILENAME"


	# Set install location if not set

	CURRENT_DIRECTORY=$PWD
	

	if [ -z ${DEFAULT_RPRO_INSTALL_LOCATION+x} ]; then 
		DEFAULT_RPRO_PATH="$CURRENT_DIRECTORY/$DEFAULT_RPRO_FOLDER_NAME"
	else
		DEFAULT_RPRO_PATH="$DEFAULT_RPRO_INSTALL_LOCATION/$DEFAULT_RPRO_FOLDER_NAME"			
	fi


	RED5PRO_DEFAULT_DOWNLOAD_FOLDER="$CURRENT_DIRECTORY/$RED5PRO_DEFAULT_DOWNLOAD_FOLDER_NAME"
	[ ! -d foo ] && mkdir -p $RED5PRO_DEFAULT_DOWNLOAD_FOLDER && chmod ugo+w $RED5PRO_DEFAULT_DOWNLOAD_FOLDER
	

	RED5PRO_SSL_LETSENCRYPT_FOLDER="$CURRENT_DIRECTORY/$RED5PRO_SSL_LETSENCRYPT_FOLDER_NAME"

}

detect_system()
{

	local ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	if [ -f /etc/lsb-release ]; then
	    . /etc/lsb-release
	    RPRO_OS_NAME=$DISTRIB_ID
	    RPRO_OS_VERSION=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
	    RPRO_OS_NAME=Debian  # XXX or Ubuntu??
	    RPRO_OS_VERSION=$(cat /etc/debian_version)
	elif [ -f /etc/redhat-release ]; then
	    # TODO add code for Red Hat and CentOS here
	    RPRO_OS_VERSION=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
	    RPRO_OS_NAME=$(rpm -q --qf "%{RELEASE}" $(rpm -q --whatprovides redhat-release))
	else
	    RPRO_OS_NAME=$(uname -s)
	    RPRO_OS_VERSION=$(uname -r)
	fi

	case $(uname -m) in
	x86_64)
	    ARCH=x64  # AMD64 or Intel64 or whatever
	    RPRO_IS_64_BIT=1
	    os_bits="64 Bit"
	    ;;
	i*86)
	    ARCH=x86  # IA32 or Intel32 or whatever
	    RPRO_IS_64_BIT=0
	    os_bits="32 Bit"
	    ;;
	*)
	    # leave ARCH as-is
	    ;;
	esac

	echo -e "* Distribution: \e[36m$RPRO_OS_NAME\e[m"
	write_log "Distribution: $RPRO_OS_NAME"

	echo -e "* Version: \e[36m$RPRO_OS_VERSION\e[m"
	write_log "Version: $RPRO_OS_VERSION"

	echo -e "* Kernel: \e[36m$os_bits\e[m"
	write_log "Kernel: $os_bits"


	empty_line

	USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
	echo -e "* Home directory: \e[36m$USER_HOME\e[m"
	write_log "Home directory: $USER_HOME"

	RPRO_BACKUP_HOME="$USER_HOME/$DEFAULT_BACKUP_FOLDER"
	echo -e "* BackUp directory: \e[36m$RPRO_BACKUP_HOME\e[m"
	write_log "BackUp directory: $RPRO_BACKUP_HOME"

	
	echo -e "* Install directory: \e[36m$DEFAULT_RPRO_PATH\e[m"
	write_log "Install directory: $DEFAULT_RPRO_PATH"

	
	# echo -e "* Downloads directory: \e[36m$RED5PRO_DEFAULT_DOWNLOAD_FOLDER\e[m"
	write_log "Downloads directory: $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

	
	if [[ $RPRO_OS_NAME == *"Ubuntu"* ]]; then
	RPRO_OS_TYPE=$OS_DEB
	else
	RPRO_OS_TYPE=$OS_RHL
	fi

	# Service installation
	if $RED5PRO_INSTALL_AS_SERVICE; then			

		# Service installer mode selection
		if [ "$RED5PRO_SERVICE_VERSION" -eq "1" ]; then
		RPRO_SERVICE_LOCATION=$RPRO_SERVICE_LOCATION_V1
		RPRO_SERVICE_NAME=$RPRO_SERVICE_NAME_V1
		echo -e "* Service Deployment : \e[36mClassic\e[m"
		else
		RPRO_SERVICE_LOCATION=$RPRO_SERVICE_LOCATION_V2
		RPRO_SERVICE_NAME=$RPRO_SERVICE_NAME_V2
		echo -e "* Service Deployment : \e[36mModern\e[m"
		fi

	else
		echo -e "* Service Deployment : \e[36mDisabled\e[m"
	fi

	write_log "OS TYPE $RPRO_OS_TYPE"
}

simple_usage_mode()
{
	write_log "Basic mode selected"

	RPRO_MODE=0

	simple_menu
	simple_menu_read_options
}

utility_usage_mode()
{
	write_log "Utility mode selected"

	RPRO_MODE=1
	
	advance_menu
	advance_menu_read_options
}

welcome_menu()
{	
	cls

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	
	echo -e "\e[44m $RED5_VERSION_NAME INSTALLER - MAIN MENU \e[m"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	detect_system

	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -	

	echo "                             		"
	echo "1. BASIC MODE (Recommended)		"
	echo "                             		"
	echo "2. UTILITY MODE				"
	echo "                             		"
	echo "X. Exit					"
	echo "                             		"
}

read_welcome_menu_options()
{
	
	local choice
	read -p "Enter choice [ 1 - 2 | X to exit] " choice
	case $choice in
		1) simple_usage_mode ;;
		2) utility_usage_mode ;;
		[xX])  exit 0;;
		*) echo -e "\e[41m Error: Invalid choice\e[m" && sleep 2 && main ;;
	esac
}

main()
{
	welcome_menu
	read_welcome_menu_options
}

######################################################################################
############################ prerequisites FUNCTION ##################################

prerequisites()
{
	lecho "Checking installation prerequisites..."
	sleep 2

	prerequisites_update

	prerequisites_git
	prerequisites_java
	prerequisites_unzip
	prerequisites_wget
	prerequisites_bc
}

prerequisites_git()
{
	check_git

	if [[ $git_check_success -eq 0 ]]; then
		echo "Installing git..."
		sleep 2

		install_git
	fi 
}

prerequisites_java()
{

	# Checking java
	lecho "Checking java requirements"
	sleep 2
	check_java

	
	if [ "$has_min_java_version" -eq 0 ]; then
		echo "Installing latest java runtime environment..."
		sleep 2

		install_java
	fi 
}

prerequisites_update()
{

	if isDebian; then
	prerequisites_update_deb
	else
	prerequisites_update_rhl
	fi
}

prerequisites_update_deb()
{
	apt-get update
}

prerequisites_update_rhl()
{
	yum -y update
}

prerequisites_unzip()
{	
	check_unzip


	if [[ $unzip_check_success -eq 0 ]]; then
		echo "Installing unzip..."
		sleep 2

		install_unzip
	fi 
}

prerequisites_wget()
{
	
	check_wget


	if [[ $wget_check_success -eq 0 ]]; then
		echo "Installing wget..."
		sleep 2

		install_wget
	fi 
}

prerequisites_bc()
{
	
	check_bc


	if [[ $bc_check_success -eq 0 ]]; then
		echo "Installing bc..."
		sleep 2

		install_bc
	fi 
}

prerequisites_jsvc()
{
	check_jsvc


	if [[ $jsvc_check_success -eq 0 ]]; then
		echo "Installing jsvc..."
		sleep 2

		install_jsvc
	fi 
}


######################################################################################
########################### postrequisites FUNCTION ##################################

postrequisites()
{
	lecho "Resolving and installing additional dependencies.."
	sleep 2

	if isDebian; then
	postrequisites_deb
	else
	postrequisites_rhl
	fi	
}

postrequisites_rhl()
{
	write_log "Installing additional dependencies for RHLE"
	yum -y install ntp

	if [ ! "$RED5_OPEN_SOURCE" -eq "1" ]; then
		yum -y install libva libvdpau
	fi
}


postrequisites_deb()
{
	write_log "Installing additional dependencies for DEBIAN"
	apt-get install -y ntp

	if [ ! "$RED5_OPEN_SOURCE" -eq "1" ]; then
		apt-get install -y libva1 libva-drm1 libva-x11-1 libvdpau1
	fi
}


######################################################################################
############################## isinstalled FUNCTION ##################################

isinstalled()
{
	if isDebian; then
	isinstalled_deb $1 
	else
	isinstalled_rhl $1
	fi
}

isinstalled_rhl()
{
	if yum list installed "$@" >/dev/null 2>&1; then
	true
	else
	false
	fi
}

isinstalled_deb()
{
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1|grep "install ok installed")

	if [ -z "$PKG_OK" ]; then
	false
	else
	true
	fi
}


# Public
isDebian()
{
	if [ "$RPRO_OS_TYPE" == "$OS_DEB" ]; then
	true
	else
	false
	fi
}

#################################################################################################
############################## repo_has_required_java FUNCTION ##################################

repo_has_required_java()
{
	if isDebian; then
	repo_has_required_java_deb
	else
	repo_has_required_java_rhl
	fi
}

repo_has_required_java_deb()
{
	local JAVA_REPO_VERSION=$(apt-cache policy default-jre | grep "Candidate:" | cut -d ":" -f3) 
	local REPO_VERSION=`echo $JAVA_REPO_VERSION | cut -f1 -d "-"`

	#echo $MIN_JAVA_VERSION
	#echo $REPO_VERSION

	if (( $(echo "$REPO_VERSION < $MIN_JAVA_VERSION" |bc -l) )); then		
		false		
	else
		true
	fi
}

repo_has_required_java_rhl()
{
	true
}

#################################################################################################
############################## UTILITY FUNCTIONS ##################################

function isEmailValid() {
      regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+"
      [[ "${1}" =~ $regex ]]
}

# Permission check
validatePermissions

# Load configuration
load_configuration

# Start application
write_log "====================================="
write_log "	NEW INSTALLER SESSION	

	"
main
