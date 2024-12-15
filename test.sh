#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Trap for cleanup
cleanup() {
    local exit_code=$?
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    
    # Clean up any remaining test directories
    if [ -n "$results_dir" ] && [ -d "$results_dir" ]; then
        rm -rf "$results_dir"
    fi
    
    # Clean up platform-specific test directories
    for platform in ubuntu wsl macos; do
        if [ -n "$test_dir" ] && [ -d "$test_dir" ]; then
            rm -rf "$test_dir"
        fi
    done
    
    # Destroy VMs if cleanup flag is set
    if [ "$CLEANUP" = "true" ]; then
        for platform in ubuntu wsl macos; do
            if vagrant status $platform 2>/dev/null | grep -q "$platform"; then
                echo -e "${YELLOW}Destroying $platform VM...${NC}"
                vagrant destroy -f $platform &>/dev/null
            fi
        done
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

# Function to install prerequisites
install_prerequisites() {
    echo -e "${YELLOW}Checking and installing prerequisites...${NC}"
    
    # Check for Vagrant
    if ! command -v vagrant &> /dev/null; then
        echo "Installing Vagrant..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install vagrant
        else
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            sudo apt-get update && sudo apt-get install vagrant
        fi
    fi

    # Check for VirtualBox
    if ! command -v VBoxManage &> /dev/null; then
        echo "Installing VirtualBox..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install --cask virtualbox
        else
            sudo apt-get update && sudo apt-get install virtualbox
        fi
    fi

    # Install required Vagrant plugins
    echo "Installing Vagrant plugins..."
    vagrant plugin install vagrant-vbguest
}

# Function to cleanup VMs
cleanup_vms() {
    local platform=$1
    local force=$2
    
    echo -e "${YELLOW}Cleaning up $platform environment...${NC}"
    
    # Check if VM exists
    if vagrant status $platform 2>/dev/null | grep -q "$platform"; then
        if [ "$force" = "true" ] || [ "$CLEANUP" = "true" ]; then
            vagrant destroy -f $platform &>/dev/null
            echo -e "${GREEN}✓ Cleaned up $platform environment${NC}"
        else
            echo -e "${YELLOW}⚠ $platform VM left intact for debugging${NC}"
            echo "To destroy manually, run: vagrant destroy -f $platform"
        fi
    fi
}

# Function to run tests for a specific platform
run_platform_tests() {
    platform=$1
    echo -e "${YELLOW}Testing $platform environment...${NC}"
    
    # Create a temporary directory for this platform's test
    test_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'vagrant-test')
    
    if [ ! -d "$test_dir" ]; then
        echo -e "${RED}Failed to create temporary directory${NC}"
        return 1
    fi
    
    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Create Vagrantfile for specific platform
    if [ "$platform" = "ubuntu" ]; then
        box="generic/ubuntu2204"
    elif [ "$platform" = "wsl" ]; then
        box="generic/ubuntu2204"  # Using Ubuntu for WSL testing
    else
        box="generic/ubuntu2204"  # Default to Ubuntu
    fi
    
    cat > "$test_dir/Vagrantfile" << EOL
Vagrant.configure("2") do |config|
  config.vm.box = "$box"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.synced_folder "$script_dir", "/ansible-role-personal"
  
  config.vm.provision "ansible_local" do |ansible|
    ansible.provisioning_path = "/ansible-role-personal"
    ansible.playbook = "tests/test.yml"
    ansible.galaxy_role_file = "tests/requirements.yml"
    ansible.become = true
  end
end
EOL
    
    cd "$test_dir" || return 1
    
    echo -e "${GREEN}Starting Vagrant for $platform...${NC}"
    if ! vagrant up; then
        echo -e "${RED}Vagrant up failed for $platform${NC}"
        cd - > /dev/null || return 1
        return 1
    fi
    
    echo -e "${GREEN}Running tests for $platform...${NC}"
    if ! vagrant provision; then
        echo -e "${RED}Tests failed for $platform${NC}"
        cd - > /dev/null || return 1
        return 1
    fi
    
    cd - > /dev/null || return 1
    return 0
}

# Main testing function
main() {
    # Check for cleanup flag
    CLEANUP=false
    while getopts "c" opt; do
        case $opt in
            c) CLEANUP=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        esac
    done
    shift $((OPTIND-1))

    # Install prerequisites
    install_prerequisites

    echo -e "${YELLOW}Starting tests for all platforms...${NC}"
    
    # Run tests for each platform sequentially
    local failed_platforms=()
    
    for platform in ubuntu wsl macos; do
        echo -e "${YELLOW}Testing $platform environment...${NC}"
        if ! run_platform_tests "$platform"; then
            failed_platforms+=("$platform")
            if [ "$CLEANUP" = "true" ]; then
                echo -e "${YELLOW}Cleaning up $platform environment...${NC}"
                (cd "$test_dir" && vagrant destroy -f)
            fi
        fi
    done
    
    # Report results
    local failed_count=${#failed_platforms[@]}
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}✗ $failed_count tests failed: ${failed_platforms[*]}${NC}"
        echo "Check the logs for details."
        if [ "$CLEANUP" != "true" ]; then
            echo "Failed environments have been left intact for debugging."
            echo "To clean up all environments, run: ./test.sh -c"
            echo "To clean up a specific environment, run: vagrant destroy -f <platform>"
        fi
        exit 1
    else
        echo -e "${GREEN}✓ All tests passed${NC}"
        if [ "$CLEANUP" = "true" ]; then
            cleanup_vms
        fi
        exit 0
    fi
}

# Run main function
main
