# Development Environment Setup

Automated development environment setup for macOS, Linux, and WSL. This repository contains Ansible roles and scripts to configure a consistent development environment across different platforms.

## Quick Start

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/l3ocifer/devenv/main/setup.sh | bash
```

Or manually:

```bash
# Clone the repository
git clone https://github.com/l3ocifer/devenv.git ~/git/devenv

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
- CLI Tools (ripgrep, fd, bat, etc.)

### Applications
- Google Chrome
- Brave Browser
- Thunderbird
- VLC
- OBS
- ChatGPT
- Claude
- TestFlight
- WYZE
- Wispr Flow

## Directory Structure

```
~/
├── git/
│   └── devenv/          # This repository
└── .scripts/            # Scripts repository (https://github.com/l3ocifer/scripts)
```

## Testing

To test the setup across all platforms:

```bash
./test.sh
```

This will run parallel tests in VMs for:
- macOS
- Ubuntu Linux
- WSL (Ubuntu-based)

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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT
