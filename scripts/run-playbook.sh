#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directory setup - use git root directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

playbooks_dir="$GIT_ROOT/playbooks"
roles_dir="$GIT_ROOT/roles"
config_file="$GIT_ROOT/.playbook-runner.conf"

# Load last run configuration if exists
if [ -f "$config_file" ]; then
    source "$config_file"
fi

# Scan playbooks directory
playbook_names=()
playbook_paths=()

# Get relative path in a portable way
get_relative_path() {
    local path=$1
    local base=$2
    echo "${path#$base/}"
}

# Load playbooks dynamically
while IFS= read -r -d '' playbook; do
    rel_path=$(get_relative_path "$playbook" "$GIT_ROOT")
    playbook_names+=("$rel_path")
    playbook_paths+=("$playbook")
done < <(find "$playbooks_dir" -maxdepth 1 -name "*.yml" -print0 | sort -z)

# Environment options
environments=("alef" "legion")

# Print header
echo -e "${BLUE}=== Ansible Playbook Runner ===${NC}"

# List available playbooks
echo -e "\n${GREEN}Available Playbooks:${NC}"
if [ ${#playbook_names[@]} -eq 0 ]; then
    echo "No playbooks found in $playbooks_dir"
    exit 1
fi

for i in "${!playbook_names[@]}"; do
    echo "$((i+1))) ${playbook_names[$i]}"
done

# Get playbook selection with default
default_playbook=${LAST_PLAYBOOK:-1}
read -p "Select playbook number [${default_playbook}]: " playbook_num
playbook_num=${playbook_num:-$default_playbook}
playbook_index=$((playbook_num-1))

if [ -z "${playbook_names[$playbook_index]}" ]; then
    echo "Invalid playbook selection"
    exit 1
fi

# List environment options
echo -e "\n${GREEN}Target Environments:${NC}"
for i in "${!environments[@]}"; do
    echo "$((i+1))) ${environments[$i]}"
done

# Get environment selection with default
default_env=${LAST_ENV:-1}
read -p "Select environment number [${default_env}]: " env_num
env_num=${env_num:-$default_env}
env_index=$((env_num-1))

if [ -z "${environments[$env_index]}" ]; then
    echo "Invalid environment selection"
    exit 1
fi

# Additional options with defaults
echo -e "\n${GREEN}Additional Options:${NC}"
default_keep=${LAST_KEEP:-"N"}
read -p "Keep resources after run? (y/N) [${default_keep}]: " keep_resources
keep_resources=${keep_resources:-$default_keep}

default_test=${LAST_TEST:-"Y"}
read -p "Run in test mode? (Y/n) [${default_test}]: " test_mode
test_mode=${test_mode:-$default_test}

# Save current selections as defaults
cat > "$config_file" << EOF
LAST_PLAYBOOK=$playbook_num
LAST_ENV=$env_num
LAST_KEEP=$keep_resources
LAST_TEST=$test_mode
EOF

# Convert responses to ansible variables
cleanup_success="true"
if [[ $keep_resources =~ ^[Yy]$ ]]; then
    cleanup_success="false"
fi

test_mode_value="true"
if [[ $test_mode =~ ^[Nn]$ ]]; then
    test_mode_value="false"
fi

# Execute playbook from git root
cd "$GIT_ROOT"
echo -e "\n${BLUE}Running playbook with selected options...${NC}"
ANSIBLE_ROLES_PATH="$roles_dir" ansible-playbook "${playbook_paths[$playbook_index]}" \
    -e "target_env=${environments[$env_index]}" \
    -e "cleanup_on_success=${cleanup_success}" \
    -e "test_mode=${test_mode_value}" 