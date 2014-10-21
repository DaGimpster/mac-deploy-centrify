Obviously need to document a lot more, but here are the global environment variables
you really should touch at the top of deploy.sh. 

title="CHANGEME - Mac Deployment Menu" === Menu title, change it to suit your organization.

dcip=CHANGEME === IP address of a pingable domain controller, this will soon be depricated 
                  when I change to an active AD search vs. just a ping check.

local_administrator=CHANGEME === Local administrator account used to promote the user
				 being issued the machine to administrator. 

adjoin_domain=CHANGEME === Active directory domain the machine will be joined to.

adjoin_user=CHANGEME === User with appropriate permissions to add/remove/change computer
			 computer accounts in your domain. 

adjoin_password_hashed=CHANGEME === Password for above named user.

adjoin_ou=CHANGEME === OU the computer account will be placed in. 
