#!/bin/bash
#
# Rails Ready
#
# Author: Josh Frye <joshfng@gmail.com>
# Licence: MIT
#
# Contributions from: Wayne E. Seguin <wayneeseguin@gmail.com>
# Contributions from: Ryan McGeary <ryan@mcgeary.org>
#
shopt -s nocaseglob
set -e

script_runner=$(whoami)
railsready_path=$(cd && pwd)/railsready
log_file="$railsready_path/install.log"

control_c()
{
  echo -en "\n\n*** Exiting ***\n\n"
  exit 1
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

clear

echo "#################################"
echo "########## Rails Ready ##########"
echo "#################################"

#determine the distro
if [[ $MACHTYPE = *linux* ]] ; then
  distro_sig=$(cat /etc/issue)
  if [[ $distro_sig =~ ubuntu ]] ; then
    distro="ubuntu"
  elif [[ $distro_sig =~ centos ]] ; then
    distro="centos"
  fi
elif [[ $MACHTYPE = *darwin* ]] ; then
  distro="osx"
    if [[ ! -f $(which gcc) ]]; then
      echo -e "\nXCode/GCC must be installed in order to build required software. Note that XCode does not automatically do this, but you may have to go to the Preferences menu and install command line tools manually.\n"
      exit 1
    fi
else
  echo -e "\nRails Ready currently only supports Ubuntu, CentOS and OSX\n"
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
echo " * Ruby (your choice of version)"
echo " * Imagemagick"
echo " * libs needed to run Rails (sqlite, mysql, etc)"
echo " * Bundler"
echo " * Git"

echo -e "\nThis script is always changing."
echo "Make sure you got it from https://github.com/rebel-outpost/railsready"

# Check if the user has sudo privileges.
sudo -v >/dev/null 2>&1 || { echo $script_runner has no sudo privileges ; exit 1; }

# Ask if you want to build Ruby or install RVM
echo -e "\n"
echo "Build Ruby or install RVM?"
echo "=> 1. Build from source"
echo "=> 2. Install RVM"
echo -n "Select your Ruby type [1 or 2]? "
read whichRuby

# Ask you which version of Ruby
echo -e "\n"
echo "Select Ruby version"
echo "=> 1. 1.9.3"
echo "=> 2. 2.0.0"
echo -n "Select your Ruby version [1 or 2]? "
read whichRubyVersion

# Ask you which server
echo -e "\n"
echo "Select Rails Server"
echo "=> 1. Unicorn"
echo "=> 2. Thin"
echo "=> 3. Passenger"
echo -n "Select your server [1, 2 or 3]? "
read whichServer

# Ask you which db
echo -e "\n"
echo "Select database"
echo "=> 1. Mongo"
echo "=> 2. MySQL"
echo "=> 3. PostgreSQL"
echo -n "Select your database [1, 2 or 3]? "
read whichDatabase

if [ $whichRuby -eq 1 ] ; then
  echo -e "\n\n!!! Set to build Ruby from source and install system wide !!! \n"
elif [ $whichRuby -eq 2 ] ; then
  echo -e "\n\n!!! Set to install RVM for user: $script_runner !!! \n"
else
  echo -e "\n\n!!! Must choose to build Ruby or install RVM, exiting !!!"
  exit 1
fi

echo -e "\n=> Creating install dir..."
cd && mkdir -p railsready/src && cd railsready && touch install.log
echo "==> done..."


if [ $whichRubyVersion -eq 1 ] ; then
  ruby_version="ruby-1.9.3-p0"
  ruby_source_root_url="http://ftp.ruby-lang.org/pub/ruby/1.9/"
elif [ $whichRubyVersion -eq 2 ] ; then
  ruby_version="ruby-2.0.0-p0"
  ruby_source_root_url="http://ftp.ruby-lang.org/pub/ruby/2.0/"
fi

ruby_version_string=$ruby_version
ruby_source_tar_name=$ruby_version".tar.gz"
ruby_source_url=$ruby_source_root_url$ruby_source_tar_name
ruby_source_dir_name=$ruby_version


echo -e "\n=> Downloading and running recipe for $distro...\n"
#Download the distro specific recipe and run it, passing along all the variables as args
if [[ $MACHTYPE = *linux* ]] ; then
  wget --no-check-certificate -O $railsready_path/src/$distro.sh https://raw.github.com/rebel-outpost/railsready/master/recipes/$distro.sh && cd $railsready_path/src && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $whichServer $whichDatabase $railsready_path $log_file
else
  cd $railsready_path/src && curl -O https://raw.github.com/rebel-outpost/railsready/master/recipes/$distro.sh && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $whichServer $whichDatabase $railsready_path $log_file
fi
echo -e "\n==> done running $distro specific commands..."

#now that all the distro specific packages are installed lets get Ruby
if [ $whichRuby -eq 1 ] ; then
  # Install Ruby
  echo -e "\n=> Downloading $ruby_version_string \n"
  cd $railsready_path/src && wget $ruby_source_url
  echo -e "\n==> done..."
  echo -e "\n=> Extracting $ruby_version_string"
  tar -xzf $ruby_source_tar_name >> $log_file 2>&1
  echo "==> done..."
  echo -e "\n=> Building $ruby_version_string (this will take a while)..."
  cd  $ruby_source_dir_name && ./configure --prefix=/usr/local >> $log_file 2>&1 \
   && make >> $log_file 2>&1 \
    && sudo make install >> $log_file 2>&1
  echo "==> done..."
elif [ $whichRuby -eq 2 ] ; then
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
else
  echo "How did you even get here?"
  exit 1
fi

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
if [ $whichRuby -eq 1 ] ; then
  sudo gem update --system --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem update --system --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."

echo -e "\n=> Installing Bundler..."
if [ $whichRuby -eq 1 ] ; then
  sudo gem install bundler --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem install bundler --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."

# if [ $whichServer -eq 1 ] ; then
#   echo -e "\n=> Installing Unicorn..."
#   if [ $whichRuby -eq 1 ] ; then
#     sudo gem install unicorn --no-ri --no-rdoc >> $log_file 2>&1
#   elif [ $whichRuby -eq 2 ] ; then
#     gem install unicorn --no-ri --no-rdoc >> $log_file 2>&1
#   fi
#   echo "==> done..."
# elif [ $whichServer -eq 2 ] ; then
#   echo -e "\n=> Installing Thin..."
#   if [ $whichRuby -eq 1 ] ; then
#     sudo gem install thin --no-ri --no-rdoc >> $log_file 2>&1
#   elif [ $whichRuby -eq 2 ] ; then
#     gem install thin --no-ri --no-rdoc >> $log_file 2>&1
#   fi
#   echo "==> done..."
# elif [ $whichServer -eq 3 ] ; then
#   echo -e "\n=> Installing Passenger..."
#   if [ $whichRuby -eq 1 ] ; then
#     sudo gem install passenger --no-ri --no-rdoc >> $log_file 2>&1
#   elif [ $whichRuby -eq 2 ] ; then
#     gem install passenger --no-ri --no-rdoc >> $log_file 2>&1
#   fi
#   echo "==> done..."
# fi

echo -e "\n#################################"
echo    "### Installation is complete! ###"
echo -e "#################################\n"

echo -e "\n !!! logout and back in to access Ruby !!!\n"

echo -e "\n Thanks!\n-Josh\n"
