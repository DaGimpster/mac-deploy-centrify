Obviously need to document a lot more, but here are the global environment variables
you really should touch in the .settings file. 

title="CHANGEME - Mac Deployment Menu"
Menu title, change it to suit your organization.

dcip="CHANGEME"
IP address of a pingable domain controller, this will soon be depricated 
when I change to an active AD search vs. just a ping check.

local_administrator="CHANGEME"
Local administrator account used to promote the user being issued to the computer
to administrator.

adjoin_domain="CHANGEME"
Active directory domain the machine will be joined to.
example: domain.local

adjoin_user="CHANGEME"
User account with appropriate permissions to add/remove/change computer accounts in
your domain.

adjoin_password_hashed="CHANGEME"
Password for above named user. This password needs to be encoded with base64.
You should also protect your .settings file with apropriate octal permissions.
example: echo "mypasswd" | base64

adjoin_ou="CHANGEME"
OU the computer account will be placed in. 
example: OU=Computers,OU=company,DC=domain,DC=local
