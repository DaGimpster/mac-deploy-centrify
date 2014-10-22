#!/bin/bash

source .settings
prompt="Choose an option:"
options=("Set EFI Password" "Set Computer Name / Install Centrify" "Add Mobile User")

# Ensure that whomever is running this script is either root or sudo'd
if [[ $EUID -ne 0 ]]; then
   echo "This script must be executed as root or with sudo"
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
	echo -n "Enter the current EFI password? If none set, press ENTER: "
	read old_efi_password
fi

 echo -n "Enter the EFI password you wish to be set: "
 read new_efi_password
 echo -n "Re-enter the EFI password you wish to be set: "
 read verify_new_efi_password

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
 echo -n "Enter the computer asset tag number, this will be set as the computers name: "
 read new_computer_name
 echo -n "Re-enter the computer asset tag number (ex: LT####): "
 read verify_new_computer_name

if [[ $verify_new_computername -ne $new_computer_name ]]
then
        echo "Asset tag numbers do not match, please try again!"
else
	echo "Setting computer name, installing Centrify package and joining Active Directory."
	scutil --set HostName "$new_computer_name"
	scutil --set LocalHostName "$new_computer_name"
	installer -pkg bin/CentrifyDC-5.1.3.pkg -target / > /dev/null 2>&1
	adjoin -w $adjoin_domain --user $adjoin_user --password $adjoin_password_unhashed --name $new_computer_name -c $adjoin_ou --force
fi
}

# This function will add a mobile user and make them an administrator
function add_mobile_user {
 echo "*******************************"
 echo "****** Add Mobile User   ******"
 echo "*******************************"
 echo ""
 echo -n "Enter the AD user you wish to assign this computer to: "
 read mobile_username
 echo -n "Re-enter the AD user you wish to assign this computer to: "
 read verify_mobile_username

if [[ $verify_mobile_username -ne $mobile_username ]]
then
        echo "Username does not match, please try again!"
else
	dseditgroup -o edit -n /Local/Default -u $local_administrator -p -a $mobile_username -t user admin;
	sleep 3;
	bin/createmobileaccount -n $mobile_username -v;
fi
}

echo ""
echo "$title"
PS3="$prompt "
echo ""
select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in

    1 ) set_efi_password;;
    2 ) set_computer_name;;
    3 ) add_mobile_user;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;

    esac

done
