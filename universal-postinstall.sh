#!/bin/bash

# Universal Post-Installation Setup Script
# Supports: Ubuntu, Debian, Fedora
# Zero Touch Provisioning + Network Automation

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Distribution detection
DISTRO=""
DISTRO_FAMILY=""
PKG_MANAGER=""
PKG_INSTALL=""
PKG_UPDATE=""

# Print functions
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Universal Post-Installation Setup               ║"
    echo "║   Zero Touch Provisioning + Network Automation    ║"
    echo "║          CLI-Only | Server-Ready                   ║"
    echo "║   Ubuntu | Debian | Fedora                        ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}━━━ $1 ━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Detect distribution
detect_distro() {
    print_step "Detecting Distribution"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        
        case $DISTRO in
            ubuntu)
                DISTRO_FAMILY="debian"
                PKG_MANAGER="apt"
                PKG_INSTALL="apt install -y"
                PKG_UPDATE="apt update && apt upgrade -y"
                print_info "Detected: Ubuntu $VERSION_ID"
                ;;
            debian)
                DISTRO_FAMILY="debian"
                PKG_MANAGER="apt"
                PKG_INSTALL="apt install -y"
                PKG_UPDATE="apt update && apt upgrade -y"
                print_info "Detected: Debian $VERSION_ID"
                ;;
            fedora)
                DISTRO_FAMILY="redhat"
                PKG_MANAGER="dnf"
                PKG_INSTALL="dnf install -y"
                PKG_UPDATE="dnf update -y"
                print_info "Detected: Fedora $VERSION_ID"
                ;;
            rhel|centos|rocky|almalinux)
                DISTRO_FAMILY="redhat"
                PKG_MANAGER="dnf"
                PKG_INSTALL="dnf install -y"
                PKG_UPDATE="dnf update -y"
                print_info "Detected: $PRETTY_NAME"
                ;;
            *)
                print_error "Unsupported distribution: $DISTRO"
                print_info "This script supports: Ubuntu, Debian, Fedora"
                exit 1
                ;;
        esac
    else
        print_error "Cannot detect distribution!"
        exit 1
    fi
    
    print_success "Distribution detected: $DISTRO ($DISTRO_FAMILY)"
}

# Update system
update_system() {
    print_step "Step 1/10: Updating System"
    
    print_info "Updating package database and system..."
    
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        sudo apt update
        sudo apt upgrade -y
    else
        sudo dnf update -y
    fi
    
    print_success "System updated!"
}

# Install base packages
install_base_packages() {
    print_step "Step 2/10: Installing Essential Packages"
    
    print_info "Installing core packages..."
    
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        sudo apt install -y \
            build-essential \
            git \
            curl \
            wget \
            nano \
            vim \
            net-tools \
            htop \
            tmux \
            openssh-server \
            python3 \
            python3-pip \
            python3-venv \
            jq \
            unzip \
            rsync \
            tree \
            software-properties-common \
            apt-transport-https \
            ca-certificates \
            gnupg \
            lsb-release
    else
        sudo dnf install -y \
            @development-tools \
            git \
            curl \
            wget \
            nano \
            vim \
            net-tools \
            htop \
            tmux \
            openssh-server \
            python3 \
            python3-pip \
            jq \
            unzip \
            rsync \
            tree \
            dnf-plugins-core
    fi
    
    print_success "Core packages installed!"
    
    # Server/CLI utilities
    print_info "Installing system utilities..."
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        sudo apt install -y \
            screen \
            zsh \
            fish \
            bat \
            ripgrep \
            fd-find \
            ncdu \
            iotop \
            sysstat \
            dstat || print_warning "Some utilities not available"
    else
        sudo dnf install -y \
            screen \
            zsh \
            fish \
            bat \
            ripgrep \
            fd-find \
            ncdu \
            iotop \
            sysstat \
            dstat || print_warning "Some utilities not available"
    fi
    
    print_success "System utilities installed!"
}

# Install Docker
install_docker() {
    print_step "Step 3/10: Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_info "Docker already installed: $(docker --version)"
        return 0
    fi
    
    print_info "Installing Docker..."
    
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        # Docker official repository for Debian/Ubuntu
        print_info "Adding Docker repository..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        # Docker for Fedora
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    
    print_success "Docker installed!"
}

# Enable services
enable_services() {
    print_step "Step 4/10: Enabling Services"
    
    print_info "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker enabled and started"
    
    print_info "Enabling SSH service..."
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        sudo systemctl enable ssh
        sudo systemctl start ssh
    else
        sudo systemctl enable sshd
        sudo systemctl start sshd
    fi
    print_success "SSH enabled and started"
    
    print_success "All services enabled!"
}

# Configure user
configure_user() {
    print_step "Step 5/10: Configuring User Permissions"
    
    print_info "Adding user to docker group..."
    sudo usermod -aG docker $USER
    print_success "User added to docker group"
    
    print_warning "You'll need to log out and back in for group changes to take effect"
}

# Setup bash aliases
setup_aliases() {
    print_step "Step 6/10: Setting Up Shell Environment"
    
    print_info "Creating bash aliases..."
    
    # Backup existing bashrc
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Add aliases if not already present
    if ! grep -q "ZTP Custom Aliases" ~/.bashrc 2>/dev/null; then
        cat >> ~/.bashrc << 'ALIASEOF'

# ═══════════════════════════════════════════════════════════
# ZTP Custom Aliases
# ═══════════════════════════════════════════════════════════

# System management
alias ll='ls -lah --color=auto'
alias update='sudo UPDATE_CMD'
alias search='SEARCH_CMD'
alias install='sudo INSTALL_CMD'
alias cleanup='CLEANUP_CMD'

# Docker shortcuts
alias docker-clean='docker system prune -af'
alias docker-stop-all='docker stop $(docker ps -aq)'
alias docker-rm-all='docker rm $(docker ps -aq)'
alias dps='docker ps'
alias dim='docker images'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Ansible shortcuts
alias ap='ansible-playbook'
alias aping='ansible all -m ping'
alias ainv='ansible-inventory --list'
alias aplay='cd ~/ansible/playbooks'

# Terraform shortcuts
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt'

# Network automation
alias netauto='cd ~/network-automation'
alias ansibledir='cd ~/ansible'
alias tfdir='cd ~/terraform'

# Network tools
alias ports='sudo netstat -tulanp'
alias myip='curl -s https://api.ipify.org && echo'
alias netdiscover='sudo nmap -sn'

# System info
alias sysinfo='neofetch 2>/dev/null || screenfetch 2>/dev/null || echo "Install neofetch: sudo apt install neofetch"'

# Paths
export PATH="$HOME/.local/bin:$PATH"

# Editor
export EDITOR=nano
export VISUAL=nano

ALIASEOF
        
        # Replace placeholders with distro-specific commands
        if [ "$DISTRO_FAMILY" = "debian" ]; then
            sed -i 's/UPDATE_CMD/apt update \&\& apt upgrade -y/g' ~/.bashrc
            sed -i 's/SEARCH_CMD/apt search/g' ~/.bashrc
            sed -i 's/INSTALL_CMD/apt install/g' ~/.bashrc
            sed -i 's/CLEANUP_CMD/sudo apt autoremove -y \&\& sudo apt autoclean/g' ~/.bashrc
        else
            sed -i 's/UPDATE_CMD/dnf update -y/g' ~/.bashrc
            sed -i 's/SEARCH_CMD/dnf search/g' ~/.bashrc
            sed -i 's/INSTALL_CMD/dnf install/g' ~/.bashrc
            sed -i 's/CLEANUP_CMD/sudo dnf autoremove -y \&\& sudo dnf clean all/g' ~/.bashrc
        fi
        
        print_success "Aliases added to ~/.bashrc"
    else
        print_info "Aliases already present in ~/.bashrc"
    fi
    
    print_success "Shell environment configured!"
}

# Git configuration
configure_git() {
    print_step "Step 7/10: Configuring Git"
    
    if [ -z "$(git config --global user.name)" ]; then
        echo ""
        print_info "Git needs to be configured"
        echo -n "Enter your Git name (e.g., John Doe): "
        read git_name
        echo -n "Enter your Git email (e.g., john@example.com): "
        read git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        print_success "Git configured!"
    else
        print_info "Git already configured as: $(git config --global user.name) <$(git config --global user.email)>"
    fi
}

# Install Ansible
install_ansible() {
    print_step "Step 8/10: Installing Ansible"
    
    print_info "Installing Ansible..."
    
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        # Add Ansible PPA for Ubuntu/Debian
        if [ "$DISTRO" = "ubuntu" ]; then
            sudo apt-add-repository --yes --update ppa:ansible/ansible 2>/dev/null || true
        fi
        sudo apt install -y ansible
    else
        sudo dnf install -y ansible
    fi
    
    print_success "Ansible installed!"
    
    print_info "Installing Ansible collections..."
    ansible-galaxy collection install cisco.ios || true
    ansible-galaxy collection install cisco.iosxr || true
    ansible-galaxy collection install cisco.nxos || true
    ansible-galaxy collection install cisco.asa || true
    ansible-galaxy collection install community.general || true
    ansible-galaxy collection install ansible.netcommon || true
    
    print_success "Ansible collections installed!"
    
    print_info "Installing Python network libraries..."
    pip3 install --user \
        netmiko \
        paramiko \
        jinja2 \
        pyyaml \
        requests \
        xmltodict \
        textfsm \
        ntc-templates \
        napalm \
        nornir \
        nornir-napalm \
        nornir-netmiko \
        netaddr \
        ciscoconfparse \
        pysnmp \
        pexpect
    
    print_success "Python libraries installed!"
    
    # Create Ansible config
    mkdir -p ~/.ansible
    cat > ~/.ansible/ansible.cfg << 'ANSIBLEEOF'
[defaults]
inventory = ~/ansible/inventory
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
stdout_callback = yaml
bin_ansible_callbacks = True

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
ANSIBLEEOF
    
    mkdir -p ~/ansible/{inventory,playbooks,roles,group_vars,host_vars}
    
    # Create sample inventory
    cat > ~/ansible/inventory/hosts << 'INVEOF'
[all:vars]
ansible_connection=network_cli
ansible_network_os=ios
ansible_user=admin
ansible_ssh_pass=password
ansible_become=yes
ansible_become_method=enable

[cisco_routers]
# router1 ansible_host=192.168.1.1

[cisco_switches]
# switch1 ansible_host=192.168.1.2

[palo_alto]
# fw1 ansible_host=192.168.1.3

[proxmox]
# pve1 ansible_host=192.168.1.4

[versa]
# versa1 ansible_host=192.168.1.5
INVEOF
    
    # Create sample playbook
    cat > ~/ansible/playbooks/cisco-backup.yml << 'PLAYBOOKEOF'
---
- name: Backup Cisco Device Configurations
  hosts: cisco_routers,cisco_switches
  gather_facts: no
  
  tasks:
    - name: Backup running configuration
      cisco.ios.ios_config:
        backup: yes
        backup_options:
          filename: "{{ inventory_hostname }}_{{ ansible_date_time.date }}.cfg"
          dir_path: ~/network-automation/backups/
      
    - name: Save configuration
      cisco.ios.ios_command:
        commands:
          - write memory
PLAYBOOKEOF
    
    print_success "Ansible workspace configured!"
}

# Install Terraform
install_terraform() {
    print_step "Step 9/10: Installing Terraform"
    
    if command -v terraform &> /dev/null; then
        print_info "Terraform already installed: $(terraform version | head -1)"
        return 0
    fi
    
    print_info "Installing Terraform..."
    
    # Get latest version
    TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    
    if [ -z "$TERRAFORM_VERSION" ]; then
        TERRAFORM_VERSION="1.9.5"
        print_warning "Could not fetch latest version, using: $TERRAFORM_VERSION"
    fi
    
    print_info "Installing Terraform v${TERRAFORM_VERSION}..."
    
    cd /tmp
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    
    print_success "Terraform v${TERRAFORM_VERSION} installed!"
    
    # Create Terraform workspaces
    mkdir -p ~/terraform/{proxmox,paloalto,versa,cisco}
    
    # Create provider configs
    cat > ~/terraform/proxmox/providers.tf << 'TFEOF'
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}
TFEOF
    
    cat > ~/terraform/paloalto/providers.tf << 'TFEOF'
terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~> 1.11"
    }
  }
}
TFEOF
    
    cat > ~/terraform/cisco/providers.tf << 'TFEOF'
terraform {
  required_providers {
    iosxe = {
      source = "CiscoDevNet/iosxe"
      version = "~> 0.5"
    }
  }
}
TFEOF
    
    print_info "Initializing Terraform providers..."
    cd ~/terraform/proxmox && terraform init -upgrade 2>/dev/null || print_warning "Proxmox init skipped"
    cd ~/terraform/paloalto && terraform init -upgrade 2>/dev/null || print_warning "Palo Alto init skipped"
    cd ~/terraform/cisco && terraform init -upgrade 2>/dev/null || print_warning "Cisco init skipped"
    cd ~
    
    print_success "Terraform configured!"
}

# Install network tools
install_network_tools() {
    print_step "Step 10/10: Installing Network Tools"
    
    print_info "Installing network utilities..."
    
    if [ "$DISTRO_FAMILY" = "debian" ]; then
        sudo apt install -y \
            nmap \
            tcpdump \
            traceroute \
            dnsutils \
            whois \
            iproute2 \
            iputils-ping \
            iperf3 \
            wireshark-common
    else
        sudo dnf install -y \
            nmap \
            tcpdump \
            traceroute \
            bind-utils \
            whois \
            iproute \
            iputils \
            iperf3 \
            wireshark-cli
    fi
    
    print_success "Network utilities installed!"
    
    # Create workspace
    mkdir -p ~/network-automation/{scripts,configs,backups,logs,templates}
    
    # Create network scanner script
    cat > ~/network-automation/scripts/scan-network.sh << 'SCANEOF'
#!/bin/bash
# Quick network scanner
echo "Scanning network..."
echo "Usage: ./scan-network.sh 192.168.1.0/24"
nmap -sn ${1:-192.168.1.0/24}
SCANEOF
    chmod +x ~/network-automation/scripts/scan-network.sh
    
    print_success "Network automation workspace created!"
}

# Final summary
print_summary() {
    print_step "Installation Complete! 🎉"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Your system is now fully configured!             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}System Information:${NC}"
    echo "  Distribution: $DISTRO"
    echo "  Package Manager: $PKG_MANAGER"
    echo ""
    
    echo -e "${YELLOW}Installed Tools:${NC}"
    echo "  ✓ Docker & Docker Compose"
    echo "  ✓ Git, Nano, Vim"
    echo "  ✓ SSH Server"
    echo "  ✓ Network Tools (nmap, tcpdump, iperf3)"
    echo "  ✓ CLI Utilities (screen, tmux, htop, ncdu)"
    echo "  ✓ Modern CLI Tools (bat, ripgrep, fd)"
    echo "  ✓ Ansible + Cisco/Palo Alto collections"
    echo "  ✓ Terraform + Network providers"
    echo "  ✓ Python network libraries"
    echo ""
    
    echo -e "${YELLOW}Enabled Services:${NC}"
    echo "  ✓ Docker"
    echo "  ✓ SSH"
    echo ""
    
    echo -e "${YELLOW}Workspace Structure:${NC}"
    echo "  ~/ansible/              - Ansible workspace"
    echo "  ~/terraform/            - Terraform configurations"
    echo "  ~/network-automation/   - Network scripts & tools"
    echo ""
    
    echo -e "${RED}⚠ IMPORTANT:${NC}"
    echo "  ${YELLOW}Log out and log back in${NC} for Docker group to take effect!"
    echo ""
    
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  update          - Update system"
    echo "  docker ps       - List containers"
    echo "  ansible --version - Check Ansible"
    echo "  terraform version - Check Terraform"
    echo "  source ~/.bashrc - Reload aliases"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Edit inventory: nano ~/ansible/inventory/hosts"
    echo "  2. Test Ansible: ansible all -m ping"
    echo "  3. Run playbook: ap ~/ansible/playbooks/cisco-backup.yml"
    echo ""
    
    print_info "Enjoy your configured system! 🚀"
    echo ""
}

# Main execution
main() {
    print_banner
    
    echo -e "${YELLOW}This script will configure your system for network automation:${NC}"
    echo "  1. Detect distribution (Ubuntu/Debian/Fedora)"
    echo "  2. Update system packages"
    echo "  3. Install essential CLI tools and utilities"
    echo "  4. Install and configure Docker"
    echo "  5. Enable services (Docker, SSH)"
    echo "  6. Set up shell environment with aliases"
    echo "  7. Configure Git"
    echo "  8. Install Ansible with network plugins"
    echo "  9. Install Terraform with providers"
    echo "  10. Install network automation tools"
    echo ""
    echo -e "${YELLOW}Optimized for: Servers, VMs, Cloud Instances, Headless Systems${NC}"
    echo -e "${YELLOW}Estimated time: 10-15 minutes${NC}"
    echo ""
    echo -n "Press ENTER to continue or Ctrl+C to cancel..."
    read
    
    detect_distro
    update_system
    install_base_packages
    install_docker
    enable_services
    configure_user
    setup_aliases
    configure_git
    install_ansible
    install_terraform
    install_network_tools
    print_summary
}

# Run main function
main
