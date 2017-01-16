# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

configFile = File.expand_path(File.join(File.dirname(__FILE__), 'config/settings.yaml'))
configFileLocal = File.expand_path(File.join(File.dirname(__FILE__), 'config/settings_local.yaml'))

settings = YAML.load_file(configFile)

if File.exists?(configFileLocal)
    overrides = YAML.load_file(configFileLocal)
    settings.merge!(overrides)
end

Vagrant.configure(2) do |config|
    config.vm.box = 'ubuntu/trusty64'

    config.vm.network "public_network", ip: settings['VM_IP']
    config.vm.synced_folder '.', '/vagrant', nfs: true

    config.vm.provider 'virtualbox' do |vb|
        vb.name = settings['VM_NAME']
        vb.cpus = settings['VM_CPUCOUNT']
        vb.memory = settings['VM_MEMORY']
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    config.vm.provision 'shell' do |s|
        s.path = 'scripts/bootstrap.sh'
        s.args = [
            settings['VM_NAME'],
            settings['HOST_NAME'],
            settings['DB_NAME'],
            settings['DB_USER'],
            settings['DB_PASS']
        ]
    end
end
