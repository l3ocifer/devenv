#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check and install prerequisites
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

    # Check for Parallels (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v prlctl &> /dev/null; then
            echo "Please install Parallels Desktop manually from https://www.parallels.com/"
            echo "Then install the vagrant-parallels plugin: vagrant plugin install vagrant-parallels"
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
    test_dir=$(mktemp -d)
    cp Vagrantfile "$test_dir/"
    cp -r ansible-role-personal "$test_dir/"
    
    (cd "$test_dir" && {
        # Bring up the VM
        vagrant up $platform &> "vagrant-$platform.log"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to start $platform environment${NC}"
            echo "See vagrant-$platform.log for details"
            cleanup_vms $platform false
            return 1
        fi

        # Run the playbook
        vagrant provision $platform &> "provision-$platform.log"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Provisioning failed for $platform${NC}"
            echo "See provision-$platform.log for details"
            cleanup_vms $platform false
            return 1
        fi

        # Run verification tests
        vagrant ssh $platform -c "ansible-playbook main.yml --tags verify" &> "verify-$platform.log"
        test_result=$?
        
        if [ $test_result -eq 0 ]; then
            echo -e "${GREEN}All tests passed for $platform${NC}"
            cleanup_vms $platform true
            return 0
        else
            echo -e "${RED}Tests failed for $platform${NC}"
            echo "See verify-$platform.log for details"
            cleanup_vms $platform false
            return 1
        fi
    })
    
    # Store the result
    result=$?
    
    # Clean up test directory
    rm -rf "$test_dir"
    
    return $result
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

    # Create a temporary directory for test results
    results_dir=$(mktemp -d)
    cd "$results_dir"

    # Run tests in parallel
    echo -e "${YELLOW}Starting parallel tests for all platforms...${NC}"
    
    for platform in ubuntu wsl macos; do
        run_platform_tests $platform &
        pids[$platform]=$!
    done

    # Wait for all tests to complete
    failed=0
    for platform in "${!pids[@]}"; do
        if wait ${pids[$platform]}; then
            echo -e "${GREEN}✓ $platform tests completed successfully${NC}"
        else
            echo -e "${RED}✗ $platform tests failed${NC}"
            failed=1
        fi
    done

    # Clean up results directory
    cd - > /dev/null
    rm -rf "$results_dir"

    # Final status and instructions
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All platform tests completed successfully!${NC}"
        echo -e "${GREEN}All test environments have been cleaned up.${NC}"
    else
        echo -e "${RED}Some platform tests failed. Check the logs for details.${NC}"
        if [ "$CLEANUP" = "true" ]; then
            echo -e "${YELLOW}All environments have been cleaned up due to -c flag${NC}"
        else
            echo -e "${YELLOW}Failed environments have been left intact for debugging.${NC}"
            echo "To clean up all environments, run: $0 -c"
            echo "To clean up a specific environment, run: vagrant destroy -f <platform>"
        fi
    fi

    exit $failed
}

# Run main function
main
