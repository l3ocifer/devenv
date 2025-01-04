#!/bin/bash

# List of roles to generate
ROLES=(
    # Core Infrastructure
    "traefik"          # Reverse proxy and SSL
    "authelia"         # Authentication
    "wireguard"        # VPN
    "fail2ban"         # Intrusion prevention
    "ufw"             # Firewall
    "iptables_config" # Base firewall rules
    
    # Network & DNS
    "hickory_dns"     # DNS server
    
    # Monitoring & Metrics
    "prometheus"      # Metrics collection
    "grafana"         # Visualization
    "loki"           # Log aggregation
    "node_exporter"  # System metrics
    "uptime-kuma"    # Uptime monitoring
    
    # Storage & Sync
    "syncthing"      # File sync
    "restic"         # Backup solution
    
    # Security & Identity
    "vaultwarden"    # Password management
    "logto"          # Identity management
    
    # Media & Gaming
    "kodi"           # Media center
    "retro_pi"       # Retro gaming
    
    # Home Automation
    "home_assistant" # Home automation
    "homekit_bridge" # Apple HomeKit
    "diyhue"         # Philips Hue emulation
    
    # Communication
    "matrix"         # Chat server
    "jitsi"          # Video conferencing
    "guacamole"      # Remote desktop
    
    # AI and Automation
    "librechat"      # Chat interface
    "ollama"         # AI models
    "mistral_rs"     # Rust inference
    "openwebui"      # UI for AI
    "huginn"         # Automation agents
    "n8n"            # Workflow automation
    "whodb"          # Database
    
    # Development
    "rustdesk"       # Remote desktop
    "rustpad"        # Collaborative editor
    "coolify"        # Self-hosting
    "postiz"         # Documentation
    
    # System Management
    "cockpit"        # System management
)

# Base directory for roles
ROLES_DIR="roles"
TEMPLATE_DIR="roles/service-template"

# Create each role
for role in "${ROLES[@]}"; do
    echo "Generating role: $role"
    
    # Replace hyphens with underscores for directory names
    role_dir="${role//-/_}"
    
    # Copy template to new role
    cp -r "$TEMPLATE_DIR" "$ROLES_DIR/$role_dir"
    
    # Update role name in defaults/main.yml
    sed -i "s/service_name: myservice/service_name: $role_dir/" "$ROLES_DIR/$role_dir/defaults/main.yml"
    
    # Create README.md for the role
    cat > "$ROLES_DIR/$role_dir/README.md" << EOF
# Ansible Role: $role

This role installs and configures $role for the homelab environment.

## Requirements

- Ansible 2.10 or higher
- Linux host

## Role Variables

See \`defaults/main.yml\` for all variables and their default values.

## Dependencies

None.

## Example Playbook

\`\`\`yaml
- hosts: servers
  roles:
    - $role_dir
\`\`\`

## License

MIT

## Author Information

Created by l3o
EOF
    
    echo "Role $role generated successfully"
done

echo "All roles have been generated!"
