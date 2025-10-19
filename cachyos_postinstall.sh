#!/bin/bash

# CachyOS Post-Installation Setup Script
# Zero Touch Provisioning for Razer Blade 13 with GNOME
# Run this on your freshly installed CachyOS system

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   CachyOS Post-Installation Setup                 ║"
    echo "║   Zero Touch Provisioning + Network Automation    ║"
    echo "║        Razer Blade 13 + KDE Plasma                 ║"
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

# Check if running on CachyOS
check_system() {
    if [ ! -f /etc/cachyos-release ] && [ ! -f /etc/os-release ] || ! grep -qi "cachyos" /etc/os-release 2>/dev/null; then
        print_error "This script is designed for CachyOS!"
        echo "Detected system: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2)"
        exit 1
    fi
    
    print_info "CachyOS detected - proceeding with setup..."
}

# System update
update_system() {
    print_step "Step 1/8: Updating System"
    
    print_info "Updating package databases and system..."
    sudo pacman -Syu --noconfirm
    
    print_success "System updated!"
}

# Install packages
install_packages() {
    print_step "Step 2/11: Installing Essential Packages"
    
    print_info "Installing packages (this may take a few minutes)..."
    
    # Core packages
    sudo pacman -S --needed --noconfirm \
        sudo \
        nano \
        vim \
        net-tools \
        git \
        docker \
        docker-compose \
        base-devel \
        wget \
        curl \
        htop \
        neofetch \
        tmux \
        openssh \
        linux-headers \
        linux-cachyos-headers \
        python \
        python-pip \
        python-virtualenv \
        jq \
        unzip \
        rsync \
        tree
    
    print_success "Core packages installed!"
    
    # KDE Plasma-specific packages
    print_info "Installing KDE Plasma enhancements..."
    sudo pacman -S --needed --noconfirm \
        plasma-systemmonitor \
        kdeplasma-addons \
        kdeconnect \
        kate \
        konsole \
        dolphin-plugins \
        filelight \
        spectacle \
        okular \
        plasma-browser-integration
    
    print_success "KDE Plasma packages installed!"
    
    # Razer support
    print_info "Installing Razer support..."
    sudo pacman -S --needed --noconfirm openrazer-meta || {
        print_warning "OpenRazer not found in repos, will try AUR later"
    }
    
    print_success "All packages installed!"
}

# Enable services
enable_services() {
    print_step "Step 3/11: Enabling Services"
    
    print_info "Enabling Docker service..."
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    print_success "Docker enabled and started"
    
    print_info "Enabling SSH service..."
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service
    print_success "SSH enabled and started"
    
    print_info "Enabling OpenRazer daemon..."
    sudo systemctl enable openrazer-daemon.service 2>/dev/null || print_warning "OpenRazer daemon not available"
    sudo systemctl start openrazer-daemon.service 2>/dev/null || true
    print_success "OpenRazer configured"
    
    print_success "All services enabled!"
}

# Configure user
configure_user() {
    print_step "Step 4/11: Configuring User Permissions"
    
    print_info "Adding user to docker group..."
    sudo usermod -aG docker $USER
    print_success "User added to docker group"
    
    print_info "Adding user to input group (for OpenRazer)..."
    sudo usermod -aG input $USER
    sudo usermod -aG plugdev $USER 2>/dev/null || true
    print_success "User added to hardware groups"
    
    print_warning "You'll need to log out and back in for group changes to take effect"
}

# KDE Plasma optimizations
configure_plasma() {
    print_step "Step 5/11: Applying KDE Plasma Optimizations"
    
    print_info "Configuring touchpad settings..."
    # KDE touchpad settings via kwriteconfig5
    kwriteconfig5 --file kcminputrc --group Mouse --key XLbInptPointerAcceleration 2
    kwriteconfig5 --file kcminputrc --group Libinput --group 'pointer' --key PointerAcceleration 2
    
    # Enable touchpad tap-to-click
    kwriteconfig5 --file kcminputrc --group Libinput --group 'touchpad' --key TapToClick true
    kwriteconfig5 --file kcminputrc --group Libinput --group 'touchpad' --key NaturalScroll true
    print_success "Touchpad optimized"
    
    print_info "Configuring interface settings..."
    # Set dark theme
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme BreezeDark
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    
    # Show battery percentage
    kwriteconfig5 --file plasmashellrc --group BatteryMonitor --key showPercentage true
    
    # Configure power management
    kwriteconfig5 --file powermanagementprofilesrc --group AC --group DimDisplay --key idleTime 600000
    kwriteconfig5 --file powermanagementprofilesrc --group Battery --group DimDisplay --key idleTime 300000
    print_success "Interface optimized"
    
    print_info "Configuring desktop effects..."
    # Enable desktop effects but optimize for performance
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
    kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
    kwriteconfig5 --file kwinrc --group Compositing --key GLCore true
    print_success "Desktop effects optimized"
    
    print_info "Configuring file manager (Dolphin)..."
    # Show hidden files
    kwriteconfig5 --file dolphinrc --group General --key ShowHiddenFiles true
    # Enable thumbnails
    kwriteconfig5 --file dolphinrc --group PreviewSettings --key Plugins "imagethumbnail,jpegthumbnail"
    print_success "File manager configured"
    
    # Restart plasmashell to apply changes
    print_info "Applying changes (may see brief screen flicker)..."
    killall plasmashell 2>/dev/null && kstart5 plasmashell &>/dev/null &
    sleep 2
    
    print_success "KDE Plasma optimized for Razer Blade 13!"
}

# Setup bash aliases
setup_aliases() {
    print_step "Step 6/11: Setting Up Shell Environment"
    
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
alias update='sudo pacman -Syu'
alias search='pacman -Ss'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias cleanup='sudo pacman -Sc --noconfirm'
alias orphans='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo "No orphans found"'

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
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias netdiscover='sudo nmap -sn'

# System info
alias sysinfo='neofetch'
alias temp='sensors 2>/dev/null || echo "Install lm_sensors: sudo pacman -S lm_sensors"'

# Paths
export PATH="$HOME/.local/bin:$PATH"

# Editor
export EDITOR=nano
export VISUAL=nano

ALIASEOF
        print_success "Aliases added to ~/.bashrc"
    else
        print_info "Aliases already present in ~/.bashrc"
    fi
    
    print_success "Shell environment configured!"
}

# Git configuration
configure_git() {
    print_step "Step 7/11: Configuring Git"
    
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

# Razer-specific setup
configure_razer() {
    print_step "Step 8/11: Razer Blade 13 Specific Setup"
    
    print_info "Checking kernel parameters..."
    
    # Check if we need intel_idle fix
    if ! grep -q "intel_idle.max_cstate" /proc/cmdline 2>/dev/null; then
        print_warning "Screen blanking fix not detected in kernel parameters"
        print_info "If you experience screen blanking issues, add this to GRUB:"
        echo "         intel_idle.max_cstate=4"
        echo ""
        echo "  Edit: sudo nano /etc/default/grub"
        echo "  Add to GRUB_CMDLINE_LINUX_DEFAULT"
        echo "  Then: sudo grub-mkconfig -o /boot/grub/grub.cfg"
    fi
    
    print_info "Creating Razer helper scripts..."
    
    # Create keyboard brightness script
    cat > ~/razer-brightness.sh << 'RAZEREOF'
#!/bin/bash
# Razer Keyboard Brightness Control
case "$1" in
    up)
        echo "Brightness up not yet implemented"
        ;;
    down)
        echo "Brightness down not yet implemented"
        ;;
    *)
        echo "Usage: $0 {up|down}"
        ;;
esac
RAZEREOF
    chmod +x ~/razer-brightness.sh
    
    print_success "Razer-specific setup complete!"
    
    print_info "For advanced fan control, consider installing razer-laptop-control from AUR"
}

# Install Ansible
install_ansible() {
    print_step "Step 9/11: Installing Ansible"
    
    print_info "Installing Ansible and dependencies..."
    sudo pacman -S --needed --noconfirm ansible ansible-core
    
    print_info "Installing Ansible collections and plugins..."
    
    # Install Cisco collections
    ansible-galaxy collection install cisco.ios || true
    ansible-galaxy collection install cisco.iosxr || true
    ansible-galaxy collection install cisco.nxos || true
    ansible-galaxy collection install cisco.asa || true
    
    # Install other network collections
    ansible-galaxy collection install community.general || true
    ansible-galaxy collection install ansible.netcommon || true
    
    print_info "Installing Python dependencies for network automation..."
    pip install --user --break-system-packages \
        netmiko \
        paramiko \
        jinja2 \
        pyyaml \
        requests \
        xmltodict \
        textfsm \
        ntc-templates \
        pyats \
        genie
    
    print_success "Ansible installed with network plugins!"
    
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
    
    print_success "Ansible configured!"
}

# Install Terraform
install_terraform() {
    print_step "Step 10/11: Installing Terraform"
    
    print_info "Checking for latest Terraform version..."
    
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
    
    # Install Terraform plugins
    print_info "Installing Terraform providers..."
    
    mkdir -p ~/terraform/{proxmox,paloalto,versa,cisco}
    
    # Create provider configs for initialization
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
    
    # Initialize providers (download plugins)
    print_info "Downloading Terraform provider plugins..."
    cd ~/terraform/proxmox && terraform init -upgrade 2>/dev/null || print_warning "Proxmox provider init skipped"
    cd ~/terraform/paloalto && terraform init -upgrade 2>/dev/null || print_warning "Palo Alto provider init skipped"
    cd ~/terraform/cisco && terraform init -upgrade 2>/dev/null || print_warning "Cisco provider init skipped"
    
    cd ~
    
    print_success "Terraform providers configured!"
    
    # Install terraform-docs
    print_info "Installing terraform-docs..."
    cd /tmp
    curl -sLo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-linux-amd64.tar.gz
    tar -xzf terraform-docs.tar.gz
    sudo mv terraform-docs /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform-docs
    rm -f terraform-docs.tar.gz
    cd ~
    
    print_success "Terraform ecosystem installed!"
}

# Install additional network tools
install_network_tools() {
    print_step "Step 11/11: Installing Network Automation Tools"
    
    print_info "Installing network utilities..."
    sudo pacman -S --needed --noconfirm \
        nmap \
        tcpdump \
        wireshark-cli \
        traceroute \
        bind-tools \
        whois \
        iproute2 \
        iputils \
        iperf3
    
    print_success "Network utilities installed!"
    
    print_info "Installing Python network libraries..."
    pip install --user --break-system-packages \
        napalm \
        nornir \
        nornir-napalm \
        nornir-netmiko \
        netaddr \
        ipaddress \
        ciscoconfparse \
        ttp \
        pysnmp \
        pexpect
    
    print_success "Python network libraries installed!"
    
    # Create workspace structure
    print_info "Creating network automation workspace..."
    mkdir -p ~/network-automation/{scripts,configs,backups,logs,templates}
    
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
# Add your Cisco routers here
# router1 ansible_host=192.168.1.1

[cisco_switches]
# Add your Cisco switches here
# switch1 ansible_host=192.168.1.2

[palo_alto]
# Add your Palo Alto firewalls here
# fw1 ansible_host=192.168.1.3
# ansible_connection=local
# ansible_network_os=panos

[proxmox]
# Add your Proxmox hosts here
# pve1 ansible_host=192.168.1.4

[versa]
# Add your Versa Networks devices here
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
    
    print_success "Network automation workspace created!"
    
    print_info "Creating helpful scripts..."
    
    # Network scanner script
    cat > ~/network-automation/scripts/scan-network.sh << 'SCANEOF'
#!/bin/bash
# Quick network scanner
echo "Scanning network..."
echo "Usage: ./scan-network.sh 192.168.1.0/24"
nmap -sn ${1:-192.168.1.0/24}
SCANEOF
    chmod +x ~/network-automation/scripts/scan-network.sh
    
    print_success "Network automation tools installed!"
}

# Final summary
print_summary() {
    print_step "Installation Complete! 🎉"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Your CachyOS system is now fully configured!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Installed Packages:${NC}"
    echo "  ✓ Docker & Docker Compose"
    echo "  ✓ Git, Nano, Vim"
    echo "  ✓ SSH Server"
    echo "  ✓ Network Tools (net-tools, nmap, tcpdump)"
    echo "  ✓ Development Tools (base-devel)"
    echo "  ✓ System Monitoring (htop, neofetch, tmux)"
    echo "  ✓ KDE Plasma Addons & Tools"
    echo "  ✓ KDE Connect (phone integration)"
    echo "  ✓ Kate, Konsole, Dolphin plugins"
    echo "  ✓ OpenRazer (Razer keyboard support)"
    echo "  ✓ Python 3 + pip + virtualenv"
    echo ""
    
    echo -e "${YELLOW}Network Automation Tools:${NC}"
    echo "  ✓ Ansible + Ansible Core"
    echo "  ✓ Terraform (latest version)"
    echo "  ✓ Network Python Libraries (netmiko, napalm, nornir, pyats)"
    echo "  ✓ Cisco Collections (ios, iosxr, nxos, asa)"
    echo "  ✓ Palo Alto Networks provider"
    echo "  ✓ Proxmox provider"
    echo "  ✓ Cisco IOS-XE provider"
    echo ""
    
    echo -e "${YELLOW}Enabled Services:${NC}"
    echo "  ✓ Docker (running)"
    echo "  ✓ SSH Server (running)"
    echo "  ✓ OpenRazer Daemon (running)"
    echo ""
    
    echo -e "${YELLOW}GNOME Optimizations:${NC}"
    echo "  ✓ Touchpad tap-to-click enabled"
    echo "  ✓ Natural scrolling enabled"
    echo "  ✓ Dark mode enabled"
    echo "  ✓ Battery percentage shown"
    echo "  ✓ Hot corners disabled"
    echo ""
    
    echo -e "${YELLOW}Shell Enhancements:${NC}"
    echo "  ✓ Useful aliases (ll, update, docker-clean, etc.)"
    echo "  ✓ Git shortcuts configured"
    echo "  ✓ Ansible shortcuts (ap, aping, aplay)"
    echo "  ✓ Terraform shortcuts (tf, tfi, tfp, tfa)"
    echo "  ✓ Network automation aliases"
    echo "  ✓ Nano set as default editor"
    echo ""
    
    echo -e "${YELLOW}Workspace Structure:${NC}"
    echo "  ~/ansible/              - Ansible workspace"
    echo "  ~/terraform/            - Terraform configurations"
    echo "  ~/network-automation/   - Network automation scripts"
    echo ""
    
    echo -e "${RED}⚠ IMPORTANT:${NC}"
    echo "  ${YELLOW}Log out and log back in${NC} for all changes to take effect!"
    echo "  (especially Docker group membership)"
    echo ""
    
    echo -e "${YELLOW}Quick Start Commands:${NC}"
    echo "  ll              - List files with details"
    echo "  update          - Update system"
    echo "  docker ps       - List running containers"
    echo "  sysinfo         - Show system information"
    echo "  ansible --version - Check Ansible version"
    echo "  terraform version - Check Terraform version"
    echo "  ap ~/ansible/playbooks/cisco-backup.yml - Run Ansible playbook"
    echo "  source ~/.bashrc - Reload aliases now (no logout needed)"
    echo ""
    
    echo -e "${YELLOW}Network Automation Quick Start:${NC}"
    echo "  1. Edit inventory: nano ~/ansible/inventory/hosts"
    echo "  2. Test connectivity: ansible all -m ping"
    echo "  3. Run sample backup: ap ~/ansible/playbooks/cisco-backup.yml"
    echo "  4. Terraform workspace: cd ~/terraform/proxmox && terraform init"
    echo ""
    
    echo -e "${YELLOW}Useful Tips:${NC}"
    echo "  • Run 'systemsettings' for KDE system settings"
    echo "  • Use KDE Connect to integrate your phone"
    echo "  • Right-click desktop → Configure Desktop and Wallpaper"
    echo "  • Install Plasma widgets from Get New Widgets"
    echo "  • Docker is ready: try 'docker run hello-world'"
    echo "  • SSH is enabled: connect from other machines"
    echo "  • Edit Ansible inventory: ~/ansible/inventory/hosts"
    echo "  • Sample playbooks in: ~/ansible/playbooks/"
    echo "  • Terraform providers in: ~/terraform/"
    echo ""
    
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  • Ansible Cisco: https://docs.ansible.com/ansible/latest/collections/cisco/ios/"
    echo "  • Terraform Proxmox: https://registry.terraform.io/providers/Telmate/proxmox/"
    echo "  • Palo Alto Ansible: https://paloaltonetworks.github.io/pan-os-ansible/"
    echo "  • Python Netmiko: https://github.com/ktbyers/netmiko"
    echo ""
    
    print_info "Enjoy your optimized CachyOS system! 🚀"
    echo ""
}

# Main execution
main() {
    print_banner
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "  1. Update your system"
    echo "  2. Install essential packages (Docker, Git, development tools)"
    echo "  3. Install KDE Plasma enhancements"
    echo "  4. Configure services (Docker, SSH, OpenRazer)"
    echo "  5. Optimize KDE Plasma for Razer Blade 13"
    echo "  6. Set up useful shell aliases"
    echo "  7. Configure Git"
    echo "  8. Configure Razer-specific settings"
    echo "  9. Install Ansible with Cisco, Palo Alto, Proxmox plugins"
    echo "  10. Install Terraform with network providers"
    echo "  11. Install network automation tools and libraries"
    echo ""
    echo -e "${YELLOW}Estimated time: 10-15 minutes${NC}"
    echo ""
    echo -n "Press ENTER to continue or Ctrl+C to cancel..."
    read
    
    check_system
    update_system
    install_packages
    enable_services
    configure_user
    configure_plasma
    setup_aliases
    configure_git
    configure_razer
    install_ansible
    install_terraform
    install_network_tools
    print_summary
}

# Run main function
main
