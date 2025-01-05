#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
deployment_types=("dev" "test" "prod")

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

# List deployment types
echo -e "\n${GREEN}Deployment Type:${NC}"
echo -e "${YELLOW}dev${NC}  - Development environment (no cleanup)"
echo -e "${YELLOW}test${NC} - Test environment (with cleanup)"
echo -e "${YELLOW}prod${NC} - Production environment (with load balancer)"
for i in "${!deployment_types[@]}"; do
    echo "$((i+1))) ${deployment_types[$i]}"
done

# Get deployment type selection with default
default_type=${LAST_TYPE:-2}  # Default to test
read -p "Select deployment type [${default_type}]: " type_num
type_num=${type_num:-$default_type}
type_index=$((type_num-1))

if [ -z "${deployment_types[$type_index]}" ]; then
    echo "Invalid deployment type selection"
    exit 1
fi

# Get instance count with default
echo -e "\n${GREEN}Instance Configuration:${NC}"
default_count=${LAST_COUNT:-1}
read -p "Number of instances to create [${default_count}]: " instance_count
instance_count=${instance_count:-$default_count}

if ! [[ "$instance_count" =~ ^[0-9]+$ ]] || [ "$instance_count" -lt 1 ]; then
    echo "Invalid instance count. Must be a positive number."
    exit 1
fi

# Additional options with defaults
echo -e "\n${GREEN}Additional Options:${NC}"
if [ "${deployment_types[$type_index]}" != "test" ]; then
    default_cleanup=${LAST_CLEANUP:-"N"}
    read -p "Run cleanup? (y/N) [${default_cleanup}]: " cleanup_requested
    cleanup_requested=${cleanup_requested:-$default_cleanup}
fi

# Save current selections as defaults
cat > "$config_file" << EOF
LAST_PLAYBOOK=$playbook_num
LAST_ENV=$env_num
LAST_TYPE=$type_num
LAST_COUNT=$instance_count
LAST_CLEANUP=$cleanup_requested
EOF

# Convert responses to ansible variables
cleanup_requested_value="false"
if [[ $cleanup_requested =~ ^[Yy]$ ]]; then
    cleanup_requested_value="true"
fi

# Execute playbook from git root
cd "$GIT_ROOT"
echo -e "\n${BLUE}Running playbook with selected options...${NC}"
ANSIBLE_ROLES_PATH="$roles_dir" ansible-playbook "${playbook_paths[$playbook_index]}" \
    -e "target_env=${environments[$env_index]}" \
    -e "deployment_type=${deployment_types[$type_index]}" \
    -e "instance_count=${instance_count}" \
    -e "cleanup_requested=${cleanup_requested_value}" 