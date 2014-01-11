#!/bin/bash
#
# Bulletin Builder Server Setup
#
# Author: bob@rebel-outpost.com
# Licence: MIT
#
# Contributions from: Wayne E. Seguin <wayneeseguin@gmail.com>
# Contributions from: Ryan McGeary <ryan@mcgeary.org>
#
shopt -s nocaseglob
set -e

script_runner='deploy'
bb_server_setup_path=$(cd && pwd)/bb_server_setup
log_file="$bb_server_setup_path/install.log"

control_c()
{
  echo -en "\n\n*** Exiting ***\n\n"
  exit 1
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

clear

echo "###################################"
echo "## Bulletin Builder Server Setup ##"
echo "###################################"

#determine the distro
if [[ $MACHTYPE = *linux* ]] ; then
  distro_sig=$(cat /etc/issue)
  if [[ $distro_sig =~ ubuntu ]] ; then
    distro="ubuntu"
  fi
elif [[ $MACHTYPE = *darwin* ]] ; then
  distro="osx"
    if [[ ! -f $(which gcc) ]]; then
      echo -e "\nXCode/GCC must be installed in order to build required software. Note that XCode does not automatically do this, but you may have to go to the Preferences menu and install command line tools manually.\n"
      exit 1
    fi
else
  echo -e "\nBulletin Builder Server Setup currently only supports Ubuntu and OSX\n"
  exit 1
fi

#now check if user is root
if [ $script_runner == "root" ] ; then
  echo -e "\nThis script must be run as a normal user with sudo privileges\n"
  exit 1
fi

echo -e "\n\n"
echo "run tail -f $log_file in a new terminal to watch the install"

echo -e "\n"
echo "What this script gets you:"
echo " * Required versions of Rub and Rails"
echo " * Imagemagick"
echo " * libs needed to run Rails (sqlite, mysql, etc)"
echo " * Bundler"
echo " * Git"

echo -e "\nThis script is always changing."
echo "Make sure you got it from https://github.com/rebel-outpost/bb_server_setup"

# Check if the user has sudo privileges.
sudo -v >/dev/null 2>&1 || { echo $script_runner has no sudo privileges ; exit 1; }

# Ask if you want to build Ruby or install RVM
echo -e "\n"
echo "Are you ready to setup server for Bulletin Builder?"
echo "=> 1. Yes"
echo "=> 2. No"
echo -n "Select Yes or No [1 or 2]? "
read makeInstall

if [ $makeInstall -eq 1 ] ; then
  echo -e "\n\n!!! Here we go.....!!! \n"
else
  echo -e "\n\n!!! OK then, Goodbye!!!"
  exit 1
fi

echo -e "\n=> Creating install dir..."
cd && mkdir -p bb_server_setup/src && cd bb_server_setup && touch install.log
echo "==> done..."

ruby_version="ruby-1.9.3-p374"
ruby_source_root_url="http://ftp.ruby-lang.org/pub/ruby/1.9/"
ruby_source_tar_name=$ruby_version".tar.gz"
ruby_source_url=$ruby_source_root_url$ruby_source_tar_name
ruby_source_dir_name=$ruby_version


echo -e "\n=> Downloading and running recipe for $distro...\n"
#Download the distro specific recipe and run it, passing along all the variables as args
if [[ $MACHTYPE = *linux* ]] ; then
  wget --no-check-certificate -O $bb_server_setup_path/src/$distro.sh https://raw.github.com/rebel-outpost/bb_server_setup/master/recipes/$distro.sh && cd $bb_server_setup_path/src && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $whichServer $whichDatabase $bb_server_setup_path $log_file
else
  cd $bb_server_setup_path/src && curl -O https://raw.github.com/rebel-outpost/bb_server_setup/master/recipes/$distro.sh && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $whichServer $whichDatabase $bb_server_setup_path $log_file
fi
echo -e "\n==> done running $distro specific commands..."

#now that all the distro specific packages are installed lets get Ruby
# if [ $whichRuby -eq 1 ] ; then
#   # Install Ruby
#   echo -e "\n=> Downloading $ruby_version_string \n"
#   cd $bb_server_setup_path/src && wget $ruby_source_url
#   echo -e "\n==> done..."
#   echo -e "\n=> Extracting $ruby_version_string"
#   tar -xzf $ruby_source_tar_name >> $log_file 2>&1
#   echo "==> done..."
#   echo -e "\n=> Building $ruby_version_string (this will take a while)..."
#   cd  $ruby_source_dir_name && ./configure --prefix=/usr/local >> $log_file 2>&1 \
#    && make >> $log_file 2>&1 \
#     && sudo make install >> $log_file 2>&1
#   echo "==> done..."
# elif [ $whichRuby -eq 2 ] ; then
  #thanks wayneeseguin :)
echo -e "\n=> Installing RVM the Ruby enVironment Manager http://rvm.beginrescueend.com/rvm/install/ \n"
\curl -L https://get.rvm.io | bash >> $log_file 2>&1
echo -e "\n=> Setting up RVM to load with new shells..."
#if RVM is installed as user root it goes to /usr/local/rvm/ not ~/.rvm
if [ -f ~/.bash_profile ] ; then
  if [ -f ~/.profile ] ; then
    echo 'source ~/.profile' >> "$HOME/.bash_profile"
  fi
fi
echo "==> done..."
echo "=> Loading RVM..."
if [ -f ~/.profile ] ; then
  source ~/.profile
fi
if [ -f ~/.bashrc ] ; then
  source ~/.bashrc
fi
if [ -f ~/.bash_profile ] ; then
  source ~/.bash_profile
fi
if [ -f /etc/profile.d/rvm.sh ] ; then
  source /etc/profile.d/rvm.sh
fi
echo "==> done..."
echo -e "\n=> Installing $ruby_version_string (this will take a while)..."
echo -e "=> More information about installing rubies can be found at http://rvm.beginrescueend.com/rubies/installing/ \n"
rvm install $ruby_version >> $log_file 2>&1
echo -e "\n==> done..."
echo -e "\n=> Using $ruby_version and setting it as default for new shells..."
echo "=> More information about Rubies can be found at http://rvm.beginrescueend.com/rubies/default/"
rvm --default use $ruby_version >> $log_file 2>&1
echo "==> done..."
# else
#   echo "How did you even get here?"
#   exit 1
# fi

echo ""

echo -e "\n=> Reloading shell so ruby and rubygems are available..."
if [ -f ~/.bashrc ] ; then
  source ~/.bashrc
fi
if [ -f ~/.bash_profile ] ; then
  source ~/.bash_profile
fi
if [ -f /etc/profile.d/rvm.sh ] ; then
  source /etc/profile.d/rvm.sh
fi
echo "==> done..."

echo -e "\n=> Updating Rubygems..."
# if [ $whichRuby -eq 1 ] ; then
#   sudo gem update --system --no-ri --no-rdoc >> $log_file 2>&1
# elif [ $whichRuby -eq 2 ] ; then
gem update --system --no-ri --no-rdoc >> $log_file 2>&1
# fi
echo "==> done..."

echo -e "\n=> Installing Bundler..."
# if [ $whichRuby -eq 1 ] ; then
#   sudo gem install bundler --no-ri --no-rdoc >> $log_file 2>&1
# elif [ $whichRuby -eq 2 ] ; then
gem install bundler --no-ri --no-rdoc >> $log_file 2>&1
# fi
echo "==> done..."

echo -e "\n#################################"
echo    "### Installation is complete! ###"
echo -e "#################################\n"

echo -e "\n !!! logout and back in to access Ruby !!!\n"

echo -e "\n Thanks!\n-Bob Roberts\n"
