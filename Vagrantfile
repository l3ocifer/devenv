# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Ubuntu (Linux) environment
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/focal64"
    ubuntu.vm.hostname = "ubuntu-test"
    ubuntu.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    ubuntu.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      pip3 install ansible
    SHELL
    ubuntu.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "main.yml"
      ansible.extra_vars = {
        ansible_python_interpreter: "/usr/bin/python3"
      }
    end
  end

  # WSL-like environment (Ubuntu based)
  config.vm.define "wsl" do |wsl|
    wsl.vm.box = "ubuntu/focal64"
    wsl.vm.hostname = "wsl-test"
    wsl.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    wsl.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      pip3 install ansible
      # Simulate WSL environment
      echo 'WSL_DISTRO_NAME="Ubuntu-20.04"' >> /etc/environment
    SHELL
    wsl.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "main.yml"
      ansible.extra_vars = {
        ansible_python_interpreter: "/usr/bin/python3"
      }
    end
  end

  # macOS environment (requires vagrant-parallels plugin)
  config.vm.define "macos" do |macos|
    macos.vm.box = "yzgyyang/macOS-12"
    macos.vm.hostname = "macos-test"
    macos.vm.provider "parallels" do |prl|
      prl.memory = "4096"
      prl.cpus = 2
    end
    macos.vm.provision "shell", inline: <<-SHELL
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      brew install ansible
    SHELL
    macos.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "main.yml"
    end
  end
end
