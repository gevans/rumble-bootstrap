# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'raring'
  config.vm.box_url = 'https://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box'
  config.vm.synced_folder File.dirname(__FILE__), '/root/bootstrap'
  config.vm.provision :shell, inline: '/root/bootstrap/bootstrap.sh'
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :private_network, ip: '33.33.33.10'

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', '1024', '--cpus', '4', '--natdnshostresolver1', 'on']
  end
end
