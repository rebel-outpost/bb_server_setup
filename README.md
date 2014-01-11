#Bulletin Builder Server Setup
###Ruby and Rails setup script for Linux and OSX
###Distros supported:
 * Ubuntu
 * OSX (requires XCode/GCC to be installed. Install command line tools via XCode->preferences to install GCC)

#
###To run:
####Linux
  * `wget --no-check-certificate https://raw.github.com/rebel-outpost/bb_server_setup/master/serverinstall.sh && bash serverinstall.sh`

####OSX
  * `curl -O https://raw.github.com/rebel-outpost/bb_server_setup/master/serverinstall.sh && bash serverinstall.sh`


###What this gives you:
  * Homebrew (OSX only)
  * Ruby RVM 1.9.3-p374
  * Imagemagick
  * libs needed to run Rails (sqlite, mysql, etc)
  * Nginx server
  * Bundler
  * Git

