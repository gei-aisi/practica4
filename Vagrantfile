# -*- mode: ruby -*-
# vi: set ft=ruby :
require_relative 'provisioning/vbox.rb'
VBoxUtils.check_version('7.2.4')
Vagrant.require_version ">= 2.4.9"

STUDEN_PREFIX = "X"
BOX_NAME = "Y"

# Hostnames for master and worker nodes
MASTER_HOSTNAME = "#{STUDEN_PREFIX}-k8s-master"
WORKER_HOSTNAME = "#{STUDEN_PREFIX}-k8s-worker"

# Cluster settings
MASTER_IP = "192.168.56.10"
MASTER_CORES = 1
WORKER_CORES = 1
MASTER_MEMORY = 2048
WORKER_MEMORY = 1536
NUM_WORKERS = 2
POD_NETWORK = "10.10.0.0/22"
SERVICE_NETWORK = "10.96.0.0/12"

require 'ipaddr'
CLUSTER_IP_ADDR = IPAddr.new MASTER_IP
CLUSTER_IP_ADDR = CLUSTER_IP_ADDR.succ

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME
  config.vm.box_check_update = false

  # Configure hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  
  # Master node
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = MASTER_HOSTNAME
    master.vm.network "private_network", ip: MASTER_IP
    master.vm.network "forwarded_port", guest: 8443, host: 8443

    master.vm.provider "virtualbox" do |vb|
	    vb.name = "AISI-P4-#{master.vm.hostname}"
      vb.cpus = MASTER_CORES
      vb.memory = MASTER_MEMORY
	    vb.gui = false
	    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    end
    
    # Install and setup K8s using ansible
    master.vm.provision "ansible", type: "ansible_local", run: "never" do |ansible|
	    ansible.install = "true"
	    ansible.install_mode = "pip3"
	    ansible.playbook = "provisioning/playbook.yml"
      ansible.inventory_path = "ansible.inventory"
      ansible.limit = "cluster"
	    ansible.extra_vars = {
        master_ip: MASTER_IP,
        master_hostname: MASTER_HOSTNAME,
        pod_network: POD_NETWORK,
		    service_network: SERVICE_NETWORK,
      }
    end
  end
  
  # Worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "worker#{i}" do |worker|
	    worker.vm.hostname = "#{WORKER_HOSTNAME}#{i}"
	    IP_ADDR = CLUSTER_IP_ADDR.to_s
      CLUSTER_IP_ADDR = CLUSTER_IP_ADDR.succ
      worker.vm.network "private_network", ip: IP_ADDR
        
      worker.vm.provider "virtualbox" do |vb|
	      vb.name = "AISI-P4-#{worker.vm.hostname}"
        vb.cpus = WORKER_CORES
        vb.memory = WORKER_MEMORY
	      vb.gui = false
	      vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
      end
    end
  end
  
  # Global provisioning bash script
  config.vm.provision "global", type: "shell", run: "always", path: "provisioning/bootstrap.sh"
end
