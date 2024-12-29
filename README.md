# Home Infrastructure as Code

This repository contains Ansible roles and playbooks for managing personal development environment and home infrastructure services.

## Repository Structure

```
.
├── inventory/          # Inventory files
│   └── hosts.yml      # Main inventory file
├── group_vars/        # Variables for groups of hosts
├── host_vars/         # Host-specific variables
├── playbooks/         # Task playbooks for specific purposes
├── roles/             # All roles live here
│   ├── devenv/        # Development environment setup role
│   └── ... (other roles)
└── site.yml           # Main playbook that ties everything together
```

## Available Roles

- `devenv`: Sets up a development environment with necessary tools and configurations
- (Add new roles here as they are created)

## Adding New Roles

To create a new role:

1. Create a new directory under `roles/`:
   ```bash
   ansible-galaxy init roles/new-role-name
   ```

2. Add your role to the appropriate playbook in `site.yml`

3. Update inventory and group variables as needed

## Usage

1. Copy `secrets.yml.example` to `secrets.yml` and fill in your values
2. Run the main playbook:
   ```bash
   ansible-playbook -i inventory/hosts.yml site.yml
   ```

## Prerequisites

Before running the setup, you'll need to configure your secrets file:

1. Copy the example secrets file:
```bash
mkdir -p ~/.config/personal
cp secrets.yml.example ~/.config/personal/secrets.yml
```

2. Edit the secrets file with your information:
```bash
# Use your preferred editor
vim ~/.config/personal/secrets.yml
```

Required configurations in secrets.yml:
- Git user information
- SSH keys
- API tokens (if using GitHub, OpenAI, etc.)
- AWS credentials (if using AWS)

## Quick Start

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/l3ocifer/devenv/main/setup.sh | bash
```

Or manually:

```bash
# Clone the repository
git clone https://github.com/l3ocifer/devenv.git ~/git/devenv

# Setup secrets (if not done already)
mkdir -p ~/.config/personal
cp ~/git/devenv/secrets.yml.example ~/.config/personal/secrets.yml
vim ~/.config/personal/secrets.yml  # Edit with your details

# Run setup script
cd ~/git/devenv
./setup.sh
```

## What's Included

### Development Tools
- Cursor - AI-powered IDE
- Zed - High-performance code editor
- Pulsar - Modern text editor
- Logseq - Knowledge management

### Programming Languages
- Python (via Miniconda)
- Node.js
- Rust
- Go
- Ruby
- Java

### DevOps Tools
- Docker Desktop
- Colima
- Podman
- AWS CLI
- Terraform
- kubectl

### Utilities
- Git + Configuration
- SSH Setup
- Shell Configuration (zsh)
- CLI Tools (ripgrep, fd, bat, eza, etc.)

## Configuration

### Secrets Management
The `~/.config/personal/secrets.yml` file contains your personal configurations:
```yaml
# Example structure (see secrets.yml.example for full template)
git_user_name: "Your Name"
git_user_email: "your.email@example.com"
ssh_keys:
  - name: id_rsa
    key: |
      -----BEGIN RSA PRIVATE KEY-----
      Your private key here
      -----END RSA PRIVATE KEY-----
```

### Directory Structure

```
~/
├── git/
│   └── devenv/          # This repository
└── .scripts/            # Scripts repository (https://github.com/l3ocifer/scripts)
```

## Testing

Run the test suite to verify the setup:
```bash
./test.sh         # Run tests, preserve failed VMs for debugging
./test.sh -c      # Run tests, clean up all VMs regardless of result
```

## Manual Installation

If you prefer to install specific components:

```bash
# Install only programming languages
ansible-playbook main.yml --tags languages

# Install only applications
ansible-playbook main.yml --tags apps

# Install everything
ansible-playbook main.yml --tags all
```

## Maintenance

### Updating
```bash
cd ~/git/devenv
git pull
./setup.sh
```

### Troubleshooting
If you encounter issues:
1. Check the ansible logs in `~/.ansible/log/`
2. Verify your secrets.yml configuration
3. Run setup.sh with -v flag for verbose output

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - See LICENSE file for details
