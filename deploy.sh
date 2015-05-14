#!/bin/bash

# Source the variables, and set a couple generic menu items up. 
source .settings
prompt="Choose an option:"
options=("Set EFI Password" "Set Computer Name / Install Centrify" "Add Mobile User" "Encrypt Harddrive")

# Ensure that whomever is running this script is either root or sudo'd
if [[ $EUID -ne 0 ]]; then
   echo " "
   echo "This script must be executed as root or with sudo"
   echo " "
   exit 1
fi

# Ensure the .settings file octal permissions are 600
perm=$(stat -f %p ".settings")
if [ "$perm" -ne "100600" ]; then
    echo " "
    echo "Your .settings octal permissions are not 600"
    echo "Please execute: chmod 600 .settings"
    echo " "
    exit 1
fi

# This function will set the EFI password
function set_efi_password {
 echo "*******************************"
 echo "****** Set EFI Password *******"
 echo "*******************************"
 echo ""
 
# Check if the EFI password is set (0 yes / 1 no). If 0 ask for password.
bin/setregproptool -c
if [[ $? -eq 0 ]]
then
	echo "EFI password is currently enabled."
	echo ""
	read -s -p "Enter the current EFI password? If none set, press ENTER: " old_efi_password
	echo ""
fi

 read -s -p "Enter the EFI password you wish to be set: " new_efi_password
 echo ""
 read -s -p "Re-enter the EFI password you wish to be set: " verify_new_efi_password

# Verify passwords entered, if EFI was enabled pass the old password to tool. 
if [[ $verify_new_efi_password -ne $new_efi_password ]]
then
	echo "Passwords do not match, please try again!"
elif [[ -z $old_efi_password ]]
then	
	bin/setregproptool -m command –p $new_efi_password
else
	bin/setregproptool -m command –p $new_efi_password -o $old_efi_password
fi
}

# This function will set the computers name and install Centrify
function set_computer_name {
# Attempt to ping a DC, if no-go bail out to menu.
 echo ""
 echo "Attempting to ping a Domain Controller."
 echo ""
ping -c 3 $dcip > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "Could not ping a Domain Controller, please connect to the corporate network or VPN (TunnelAll) to continue."
	echo ""
	return
fi 

adjoin_password_unhashed=`echo "$adjoin_password_hashed" | base64 --decode`
echo $adjoin_password_unhashed

 echo "*******************************"
 echo "****** Set Computer Name ******"
 echo "****** Install Centrify  ******"
 echo "*******************************"
 echo ""
 read -p "Enter the computer asset tag number, this will be set as the computers name: " new_computer_name
 echo ""
 read -p "Re-enter the computer asset tag number: " verify_new_computer_name

if [[ $verify_new_computername -ne $new_computer_name ]]
then
        echo "Asset tag numbers do not match, please try again!"
else
	echo "Setting computer name, installing Centrify package and joining Active Directory."
	scutil --set HostName "$new_computer_name"
	scutil --set LocalHostName "$new_computer_name"
	installer -pkg bin/CentrifyDC-5.1.3.pkg -target / > /dev/null 2>&1
	adjoin -w $adjoin_domain --user $adjoin_user --password $adjoin_password_unhashed --name $new_computer_name -c $adjoin_ou --force
	adlicense --licensed
fi
}

# This function will add a mobile user and make them an administrator
function add_mobile_user {
 echo "*******************************"
 echo "****** Add Mobile User   ******"
 echo "*******************************"
 echo ""
 read -p "Enter the AD user you wish to assign this computer to: " mobile_username
 echo ""
 read -p "Re-enter the AD user you wish to assign this computer to: " verify_mobile_username
 echo ""
 read -s -p "Enter the AD user password  you wish to assign this computer to: " mobile_user_password
 echo ""
 read -s -p "Re-enter the AD user password you wish to assign this computer to: " verify_mobile_user_password

if [[ $verify_mobile_username -ne $mobile_username ]]
then
        echo "Username does not match, please try again!"
else
	dseditgroup -o edit -n /Local/Default -u $local_administrator -p -a $mobile_username -t user admin;
	sleep 3;
	bin/createmobileaccount -n $mobile_username -v;
fi
}

# This function will install the institutional FileVault key, and then encrypt the local harddrive
function encrypt_harddrive {
 echo "*******************************"
 echo "******   Encrypt Drive   ******"
 echo "*******************************"
 echo ""

if [ -z "$mobile_username" ]
then
	read -p "Mobile User hasnt been added yet, do you wish to continue? (y or n): " no_mobile_user
fi

if [[ $no_mobile_user == y ]]
then
	echo ""
	echo "Drive encryption will begin in 10 seconds, system will restart automatically."
	echo "Break NOW to cancel!"
	echo ""
	sleep 10
	sed -i.orig "s/LOCALADMIN/$local_administrator/g" files/filevault-nomobileuser.plist
	sed -i.orig "s/ADMINPASSWORD/$local_administrator_password/g" files/filevault-nomobileuser.plist
	fdesetup enable -norecoverykey -institutional -inputplist < files/filevault-nomobileuser.plist -forcerestart
elif [[ $no_mobile_user == "" ]]
then
	echo ""
        echo "Drive encryption will begin in 10 seconds, system will restart automatically."
        echo "Break NOW to cancel!"
	echo ""
        sleep 10
        sed -i.orig "s/LOCALADMIN/$local_administrator/g" files/filevault-mobileuser.plist
        sed -i.orig "s/ADMINPASSWORD/$local_administrator_password/g" files/filevault-mobileuser.plist
        sed -i.orig "s/MOBILEUSER/$mobile_username/g" files/filevault-mobileuser.plist
        sed -i.orig "s/USERPASSWORD/$mobile_user_password/g" files/filevault-mobileuser.plist
        fdesetup enable -norecoverykey -institutional -inputplist < files/filevault-mobileuser.plist -forcerestart
fi
}

# Menu options are at beginning of script.
echo " "
echo "$title"
PS3="$prompt "
echo " "
select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in

    1 ) set_efi_password;;
    2 ) set_computer_name;;
    3 ) add_mobile_user;;
    4 ) encrypt_harddrive;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;

    esac

done
