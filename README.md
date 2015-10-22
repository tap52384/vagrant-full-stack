# vagrant-full-stack
Vagrantfile and script for a full-stack development environment.

As I learn what is needed for me to perfect my craft, this script will change to automatically create the environment I need and install all the tools necessary for me to proceed.

### What's installed

* Ubuntu 64-bit
* PHP 5
  * PEAR Mail, php-ldap, XDebug
* MySQL Server 5.5
* Apache 2
  * mod_rewrite
* Oracle InstantClient Drivers
  * Basic and SDK files are required in shared/ folder
* NodeJS, NPM
* Utilities
  * curl, git, vim, rsync, wget,  rpm, unzip, make, sendmail

### What's customized

* The URL for the application will be folder_name.app:port_number; for example, blah.app:8080
* Timezone is set to America/New_York
* Automatically sets the Document root to "web/" if that folder exists instead of "html/"
