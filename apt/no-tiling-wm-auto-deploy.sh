#!/bin/bash

set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be executed as root." >&2
    exit 1
fi

# Install curl and wget if not installed
for cmd in curl wget; do command -v $cmd &> /dev/null || apt install $cmd -y; done

OBSIDIAN_VERSION="1.8.10"
OBSIDIAN_DEB="obsidian_${OBSIDIAN_VERSION}_amd64.deb"
WAVETERM_VERSION="0.11.2"
WAVETERM_DEB="waveterm-linux-amd64-${WAVETERM_VERSION}.deb"
TOOLS_URL="https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/tools.list"
TMUX_CONF_URL="https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/tmux/tmux.conf"
P10K_ZSH_URL="https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/p10k.zsh"
ROOT_P10K_ZSH_URL="https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/Root/p10k.zsh"
ZSHRC_URL="https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/zshrc"
regular_user=$(users | cut -d' ' -f1)

# Change directory to tmp
cd /tmp

# Add repositories
## Kali
wget -qO - https://archive.kali.org/archive-key.asc \
    | gpg --dearmor \
    | dd of=/usr/share/keyrings/kali-archive-keyring.gpg
echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free' \
    | tee -a /etc/apt/sources.list
## VSCodium
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
    | tee /etc/apt/sources.list.d/vscodium.list
## Firejail & Firetools (GUI to manage sandboxes)
add-apt-repository ppa:deki/firejail -y

# Update & upgrade
apt update && apt upgrade -y

# Install tools from list
apt install $(wget -qO - https://raw.githubusercontent.com/fir3l1ght/dotfiles/refs/heads/main/tools.list | grep -v '^#' | tr "\n" " ") -y

# Install Brave
curl -fsS https://dl.brave.com/install.sh | sh

# Install Obsidian
curl -LO "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/${OBSIDIAN_DEB}"
apt install ./${OBSIDIAN_DEB} -y
rm ${OBSIDIAN_DEB}

# Install Wave Terminal
curl -LO "https://dl.waveterm.dev/releases-w2/${WAVETERM_DEB}"
apt install ./${WAVETERM_DEB} -y
rm ${WAVETERM_DEB}

# Set zsh as the default shell
chsh $regular_user -s /bin/zsh
chsh root -s /bin/zsh

# Download OhMyZsh & plugins
su $regular_user -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) '' --unattended || { echo -e '${regular_user}: Error while installing OhMyZsh'; exit 1; }"
su $regular_user -c "git clone https://github.com/zsh-users/zsh-autosuggestions /home/${regular_user}/.oh-my-zsh/custom/plugins/zsh-autosuggestions || { echo -e '${regular_user}: Error while cloning zsh-autosuggestions'; exit 1; }"
su $regular_user -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${regular_user}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || { echo -e '${regular_user}: Error while cloning zsh-syntax-highlighting'; exit 1; }"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) '' --unattended || { echo -e 'root: Error while installing OhMyZsh'; exit 1; }"
git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions || { echo -e 'root: Error while cloning zsh-autosuggestions'; exit 1; }
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || { echo -e 'root: Error while cloning zsh-syntax-highlighting'; exit 1; }
touch /home/${regular_user}/.hushlogin
touch /root/.hushlogin

# Download Powerlevel10k
su $regular_user -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/${regular_user}/powerlevel10k || { echo -e '${regular_user}: Error while cloning p10k'; exit 1; }"
su $regular_user -c "wget -qO /home/${regular_user}/.p10k.zsh ${P10K_ZSH_URL}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k || { echo "root: Error while cloning p10k"; exit 1; }
wget -qO /root/.p10k.zsh ${ROOT_P10K_ZSH_URL}

# Download .zshrc and create symlink for root
su $regular_user -c "wget -qO /home/${regular_user}/.zshrc ${ZSHRC_URL}"
if [ ! -L /root/.zshrc ]; then
    rm /root/.zshrc
    ln -s /home/${regular_user}/.zshrc /root/.zshrc
fi

# Install Tmux & TPM
su $regular_user -c "wget -qO /home/${regular_user}/.tmux.conf ${TMUX_CONF_URL}"
su $regular_user -c "git clone https://github.com/tmux-plugins/tpm /home/${regular_user}/.tmux/plugins/tpm || { echo -e '${regular_user}: Error while cloning tpm'; exit 1; }"
wget -qO /root/.tmux.conf ${TMUX_CONF_URL}
git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm || { echo -e 'root: Error while cloning tpm'; exit 1; }
echo -e '[Tmux & TPM]\n'
echo -e '1. Open Tmux -> tmux\n'
echo -e '2. Install plugins -> CTRL+SPACE, SHIFT+i, (when finished) ESC\n'

# Install Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
rm -rf /opt/nvim
tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm -rf nvim-linux-x86_64.tar.gz

# Install Hack Nerd Font
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz
mkdir /usr/share/fonts/hnf
tar -C /usr/share/fonts/hnf -xJf Hack.tar.xz
rm -rf Hack.tar.xz

# Install NvChad
su $regular_user -c "git clone https://github.com/NvChad/starter /home/${regular_user}/.config/nvim || { echo -e '${regular_user}: Error while cloning NvChad'; exit 1; }"
git clone https://github.com/NvChad/starter /root/.config/nvim || { echo -e 'root: Error while cloning NvChad'; exit 1; }
echo -e '[NvChad]\n'
echo -e '1. Open Neovim -> nvim\n'
echo -e '2. When lazy.nvim finished downloading plugins -> :MasonInstallAll\n'
echo -e '3. Learn customization of ui & base46 -> :h nvui\n'
echo -e '4. Update NvChad -> Lazy sync command\n'
echo -e '5. Choose theme -> SPACE+t+h\n'
rm -rf /home/${regular_user}/.config/nvim/.git
rm -rf /root/.config/nvim/.git

# Install FZF
su $regular_user -c "git clone --depth 1 https://github.com/junegunn/fzf.git /home/${regular_user}/.fzf || { echo -e '${regular_user}: Error while cloning fzf'; exit 1; }"
chmod +x /home/${regular_user}/.fzf/install
su $regular_user -c "/home/${regular_user}/.fzf/install --key-bindings --completion --update-rc || { echo -e '${regular_user}: Error while installing fzf'; exit 1; }"
git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf || { echo -e 'root: Error while cloning fzf'; exit 1; }
chmod +x /root/.fzf/install
/root/.fzf/install --key-bindings --completion --update-rc || { echo -e 'root: Error while installing fzf'; exit 1; }

# Install KASM?
#su $regular_user -c "curl -LO https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.bbc15c.tar.gz"
#su $regular_user -c "tar -xf kasm_release_1.17.0.bbc15c.tar.gz"
#su $regular_user -c "bash kasm_release/install.sh"

# Install Curlie
su $regular_user -c "curl -sS https://webinstall.dev/curlie | bash"
su $regular_user -c "source /home/${regular_user}/.config/envman/PATH.env"
curl -sS https://webinstall.dev/curlie | bash
source /root/.config/envman/PATH.env

# Install Postman and/or Posting.sh?
#pipx install posting
#mkdir myrequests && cd myrequests

# ¿TODO?: Install LM Studio and connect to Wave Terminal

# ¿TODO?: Install Warp Terminal

# TODO: Create versions for other package managers
# TODO: Create versions to install and setup BSPWM, i3, etc.
