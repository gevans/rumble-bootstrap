#!/usr/bin/env sh

set -e

### Setup variables

export BOOTSTRAP_REPO=${BOOTSTRAP_REPO:-"https://github.com/gevans/rumble-bootstrap.git"}
export BOOTSTRAP_BRANCH=${BOOTSTRAP_BRANCH:-"master"}
export BOOTSTRAP_ROOT="$HOME/bootstrap"

# Enable truly non-interactive apt-get installs
export DEBIAN_FRONTEND=noninteractive

# Get the name of the running Ubuntu release (e.g. precise)
release=$(lsb_release -s --codename)

# Fail unless we're running on Ubuntu 13.04
if [ "$release" != "raring" ]; then
  echo "This installation script requires Ubuntu 13.04 (Raring Ringtail)."
  exit 1
fi

echo "And we're off! Get back to working on your app. This is going to take a while..."

exists() {
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

### Update and install package dependencies

# Update source list
cat > /etc/apt/sources.list <<EOF
deb http://us.archive.ubuntu.com/ubuntu $release main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu $release main restricted universe multiverse

deb http://us.archive.ubuntu.com/ubuntu $release-updates main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu $release-updates main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu $release-security main restricted universe multiverse
deb-src http://security.ubuntu.com/ubuntu $release-security main restricted universe multiverse
EOF

apt-get -y update
apt-get -y upgrade
apt-get -y install git make curl software-properties-common

### Base setup

# Set the timezone to UTC
apt-get -y install tzdata
echo "Etc/UTC" > /etc/timezone
dpkg-reconfigure tzdata

# Install ntpd
apt-get -y install ntp

# Set the machine hostname
echo $HOSTNAME > /etc/hostname
sed -i -r "s/^127.0.0.1 localhost/127.0.0.1 localhost $HOSTNAME/" > /etc/hosts || true
hostname $HOSTNAME

# Set the LC_CTYPE so that auto-completion works properly
apt-get -y install locales
locale-gen en_US.utf8
update-locale LC_ALL=en_US.utf8
dpkg-reconfigure locales

### Clone bootstrap repository

test -d $BOOTSTRAP_ROOT || git clone --recursive $BOOTSTRAP_REPO $BOOTSTRAP_ROOT

# Switch branches, if necessary
cd $BOOTSTRAP_ROOT
current_branch=$(git symbolic-ref -q --short HEAD)
if [ "$current_branch" != "$BOOTSTRAP_BRANCH" ]; then
  test $BOOTSTRAP_BRANCH && git checkout origin/$BOOTSTRAP_BRANCH || true
  git submodule update --init --recursive
fi

### Install Dokku

if ! exists /usr/local/bin/dokku; then
  cd dokku
  make all
fi

# Install plugins
added_new_plugins=false
plugin_path="/var/lib/dokku/plugins"
cd $plugin_path
while read plugin; do
  repo=$(echo $plugin | awk '{print $1}')
  name=$(echo $plugin | awk '{print $2}')
  if [ ! -d "$plugin_path/$name" ]; then
    added_new_plugins=true
    git clone $repo $name
  fi
done < $BOOTSTRAP_ROOT/config/dokku-plugins.txt
$added_new_plugins && dokku plugins-install

### Add SSH & deploy keys

KEY_FILE="/root/.ssh/authorized_keys"

mkdir -p /root/.ssh && chmod 0700 /root/.ssh
touch $KEY_FILE && chmod 0600 $KEY_FILE

# Add Rails Rumble key to root
curl http://railsrumble.com.s3.amazonaws.com/rumblebot.pub > $KEY_FILE

# Clear and readd gitreceive keys
[ -f /home/git/.ssh/authorized_keys ] && echo "" > /home/git/.ssh/authorized_keys
while read line; do
  public_key=$(echo $line | awk '{print $1, $2, $3}')
  name=$(echo $line | awk '{print $4}')

  # Add key to Dokku
  echo $public_key | gitreceive upload-key $name
  # Add key to root
  echo $public_key >> $KEY_FILE
done < $BOOTSTRAP_ROOT/config/deploy_keys.txt

### Clean up

apt-get -y autoremove
apt-get -y clean

### Finalize

# Copy resolv.conf
cat $BOOTSTRAP_ROOT/config/resolv.conf > /etc/resolv.conf

# Add our silly/informational messages
cat $BOOTSTRAP_ROOT/config/motd.tail > /etc/motd.tail
cat $BOOTSTRAP_ROOT/config/issue.net > /etc/issue.net

sshd_config="/etc/ssh/sshd_config"

# Uncomment sshd Banner option
sed -i -r 's/^#Banner \/etc\/issue.net/Banner \/etc\/issue.net/' $sshd_config
# Force public key authentication
sed -i -r 's/^#PasswordAuthentication yes/PasswordAuthentication no/' $sshd_config

# Reload OpenSSH server
service ssh reload

# Remove the default nginx site
test -f /etc/nginx/sites-enabled/default && rm /etc/nginx/sites-enabled/default && service nginx reload

echo
echo "And we're done. Happy Rumbling!"
