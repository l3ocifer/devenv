#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
CLEAN_ONLY=false
PLATFORMS=("ubuntu" "wsl" "macos")
FAILED_PLATFORMS=()
TEMP_DIR_PREFIX="tmp"

function cleanup() {
    echo "Cleaning up..."
    for platform in "${PLATFORMS[@]}"; do
        rm -rf "${TEMP_DIR_PREFIX}"*
        vagrant destroy -f "$platform" > /dev/null 2>&1 || true
    done
}

function is_arm_mac() {
    [[ "$(uname -m)" == "arm64" ]] && [[ "$(uname)" == "Darwin" ]]
}

function install_vagrant_plugin() {
    local plugin=$1
    if ! vagrant plugin list | grep -q "$plugin"; then
        echo "Installing the '$plugin' plugin..."
        if [[ "$plugin" == "vagrant-utm" ]]; then
            # Try installing from RubyGems first
            if ! vagrant plugin install vagrant-utm; then
                echo -e "${YELLOW}Failed to install from RubyGems, trying alternative installation...${NC}"
                # Clone and install from local repository
                local temp_dir
                temp_dir=$(mktemp -d)
                if git clone --depth 1 https://github.com/vagrant-utm/vagrant-utm.git "$temp_dir"; then
                    (cd "$temp_dir" && gem build vagrant-utm.gemspec && vagrant plugin install ./vagrant-utm-*.gem)
                    rm -rf "$temp_dir"
                else
                    echo -e "${RED}Failed to install vagrant-utm plugin${NC}"
                    echo "Please try manually:"
                    echo "1. git clone https://github.com/vagrant-utm/vagrant-utm.git"
                    echo "2. cd vagrant-utm"
                    echo "3. gem build vagrant-utm.gemspec"
                    echo "4. vagrant plugin install ./vagrant-utm-*.gem"
                    return 1
                fi
            fi
        else
            if ! vagrant plugin install "$plugin"; then
                echo -e "${RED}Failed to install plugin: $plugin${NC}"
                return 1
            fi
        fi
    fi
}

function check_virtualization() {
    echo "Checking virtualization status..."
    if [[ "$(uname)" == "Darwin" ]]; then
        if is_arm_mac; then
            if ! command -v utm &> /dev/null; then
                echo "Installing UTM..."
                brew install --cask utm
            fi
            
            # Install Vagrant UTM plugin
            install_vagrant_plugin "vagrant-utm"
        else
            echo "Loading VirtualBox kernel extensions..."
            if ! kextstat | grep -q "org.virtualbox.kext.VBoxDrv"; then
                echo "VirtualBox kernel extensions not loaded. Attempting to load..."
                sudo kextload /Library/Application\ Support/VirtualBox/VBoxDrv.kext || {
                    echo -e "${RED}Failed to load VirtualBox kernel extensions.${NC}"
                    echo "Please try the following steps:"
                    echo "1. Open System Settings > Privacy & Security"
                    echo "2. Scroll down and look for blocked system extensions"
                    echo "3. Allow the Oracle extensions"
                    echo "4. Restart your computer"
                    exit 1
                }
                echo "Waiting for kernel extensions to load..."
                sleep 5
            fi
        fi
    fi
}

function install_prerequisites() {
    echo "Checking and installing prerequisites..."
    
    # Install Vagrant plugins
    echo "Installing Vagrant plugins..."
    install_vagrant_plugin "vagrant-vbguest"
    
    check_virtualization
}

function run_test() {
    local platform=$1
    local temp_dir="${TEMP_DIR_PREFIX}$(openssl rand -hex 6)"
    local provider
    
    if is_arm_mac; then
        provider="utm"
    else
        provider="virtualbox"
    fi
    
    echo "Testing ${platform} environment with ${provider}..."
    mkdir -p "$temp_dir"
    cp -r . "$temp_dir/"
    cd "$temp_dir"
    
    echo "Starting Vagrant for ${platform}..."
    if ! VAGRANT_DEFAULT_PROVIDER="$provider" VAGRANT_CWD="$temp_dir" vagrant up "$platform"; then
        echo -e "${RED}Vagrant up failed for ${platform}${NC}"
        FAILED_PLATFORMS+=("$platform")
        return 1
    fi
    
    echo "Running Ansible playbook for ${platform}..."
    if ! VAGRANT_DEFAULT_PROVIDER="$provider" VAGRANT_CWD="$temp_dir" vagrant provision "$platform"; then
        echo -e "${RED}Ansible playbook failed for ${platform}${NC}"
        FAILED_PLATFORMS+=("$platform")
        return 1
    fi
    
    echo -e "${GREEN}Tests passed for ${platform}${NC}"
    return 0
}

# Main execution
if [[ "${1:-}" == "-c" ]]; then
    CLEAN_ONLY=true
fi

if [[ "$CLEAN_ONLY" == true ]]; then
    cleanup
    exit 0
fi

trap cleanup EXIT

install_prerequisites

echo "Starting tests for all platforms..."
for platform in "${PLATFORMS[@]}"; do
    echo "Testing ${platform} environment..."
    if ! run_test "$platform"; then
        echo "Cleaning up environment..."
        vagrant destroy -f "$platform" > /dev/null 2>&1 || true
    fi
done

if [[ ${#FAILED_PLATFORMS[@]} -gt 0 ]]; then
    echo -e "${RED}✗ ${#FAILED_PLATFORMS[@]} tests failed: ${FAILED_PLATFORMS[*]}${NC}"
    echo "Check the logs for details."
    echo "Failed environments have been left intact for debugging."
    echo "To clean up all environments, run: ./test.sh -c"
    echo "To clean up a specific environment, run: vagrant destroy -f <platform>"
    exit 1
else
    echo -e "${GREEN}✓ All tests passed${NC}"
fi
