# Text Editors & Development Tools for Debian

Complete guide to text editors and development tools for managing your Ghostfolio deployment on Debian systems.

## 📋 Table of Contents

- [Terminal-Based Editors](#terminal-based-editors)
- [GUI Editors](#gui-editors)
- [IDE Solutions](#ide-solutions)
- [Markdown Editors](#markdown-editors)
- [File Management Tools](#file-management-tools)
- [Configuration & Setup](#configuration--setup)
- [Editor Plugins & Extensions](#editor-plugins--extensions)
- [Workflow Tips](#workflow-tips)

## 💻 Terminal-Based Editors

### nano (Beginner-Friendly)

```bash
# Install nano
sudo apt update && sudo apt install nano

# Basic usage
nano filename.txt
nano docker-compose.yml
nano .env

# Essential nano shortcuts
# Ctrl+O: Save file
# Ctrl+X: Exit
# Ctrl+W: Search
# Ctrl+\: Search and replace
# Ctrl+G: Get help
# Alt+U: Undo
# Alt+E: Redo

# Configure nano for better experience
cat << 'EOF' > ~/.nanorc
# Enable syntax highlighting
include "/usr/share/nano/*.nanorc"

# Show line numbers
set linenumbers

# Enable mouse support
set mouse

# Set tab size
set tabsize 4

# Auto-indent
set autoindent

# Smooth scrolling
set smooth

# Show cursor position
set constantshow

# Backup files
set backup
set backupdir "~/.nano/backups"

# Enable spell checking
set speller "aspell -c"
EOF

# Create backup directory
mkdir -p ~/.nano/backups
```

### vim/neovim (Advanced Users)

```bash
# Install vim
sudo apt update && sudo apt install vim

# Install neovim (modern vim)
sudo apt install neovim

# Basic vim commands for Docker/config files
vim docker-compose.yml

# Essential vim commands
# i: Insert mode
# Esc: Normal mode
# :w: Save
# :q: Quit
# :wq: Save and quit
# :q!: Quit without saving
# /search: Search
# :s/old/new/g: Replace all in line
# :%s/old/new/g: Replace all in file

# Basic vim configuration
cat << 'EOF' > ~/.vimrc
" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Enable mouse support
set mouse=a

" Set tab settings
set tabstop=4
set shiftwidth=4
set expandtab

" Enable auto-indent
set autoindent
set smartindent

" Show matching brackets
set showmatch

" Enable search highlighting
set hlsearch
set incsearch

" Better color scheme
colorscheme desert

" Enable file type detection
filetype plugin indent on

" Show status line
set laststatus=2
EOF

# Install vim-plug (plugin manager)
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### micro (Modern Terminal Editor)

```bash
# Install micro
curl https://getmic.ro | bash
sudo mv micro /usr/local/bin/

# Basic usage
micro docker-compose.yml
micro README.md

# Micro features:
# - Modern keybindings (Ctrl+S save, Ctrl+C copy, etc.)
# - Mouse support
# - Syntax highlighting
# - Plugin system
# - Easy to learn

# Configure micro
micro ~/.config/micro/settings.json

# Example configuration
cat << 'EOF' > ~/.config/micro/settings.json
{
    "autosu": false,
    "colorscheme": "monokai",
    "cursorline": true,
    "ignorecase": false,
    "indentchar": " ",
    "ruler": true,
    "savecursor": false,
    "saveundo": false,
    "scrollmargin": 3,
    "scrollspeed": 2,
    "softwrap": false,
    "splitbottom": true,
    "splitright": true,
    "statusline": true,
    "syntax": true,
    "tabsize": 4,
    "tabstospaces": true
}
EOF
```

## 🖥️ GUI Editors

### gedit (GNOME Text Editor)

```bash
# Install gedit
sudo apt update && sudo apt install gedit

# Launch gedit
gedit docker-compose.yml &
gedit README.md &

# Gedit features:
# - Simple and intuitive
# - Syntax highlighting
# - Plugin support
# - Search and replace
# - Tabbed interface

# Install useful gedit plugins
sudo apt install gedit-plugins

# Enable plugins in gedit:
# Edit → Preferences → Plugins
# Recommended plugins:
# - Bracket Completion
# - Code Comment
# - File Browser Panel
# - Word Completion
```

### Kate (KDE Advanced Text Editor)

```bash
# Install Kate
sudo apt update && sudo apt install kate

# Launch Kate
kate docker-compose.yml &

# Kate features:
# - Advanced text editor
# - Project management
# - Split view
# - Terminal integration
# - Plugin system
# - Session management
```

### Sublime Text

```bash
# Install Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update && sudo apt install sublime-text

# Launch Sublime Text
subl docker-compose.yml

# Install Package Control (plugin manager)
# Tools → Install Package Control

# Recommended packages:
# - Docker
# - YAML
# - Markdown Extended
# - SideBarEnhancements
# - GitGutter
```

## 🔧 IDE Solutions

### Visual Studio Code

```bash
# Method 1: Download from Microsoft
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install code

# Method 2: Snap package
sudo snap install code --classic

# Launch VS Code
code .  # Open current directory
code docker-compose.yml

# Essential VS Code extensions for Docker projects:
# - Docker (by Microsoft)
# - YAML (by Red Hat)
# - GitLens
# - Remote - SSH
# - Markdown All in One
# - Thunder Client (API testing)
```

### VSCodium (Open Source VS Code)

```bash
# Install VSCodium
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium

# Launch VSCodium
codium .
```

## 📝 Markdown Editors

### Typora

```bash
# Install Typora
wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
echo 'deb https://typora.io/linux ./' | sudo tee /etc/apt/sources.list.d/typora.list
sudo apt update && sudo apt install typora

# Launch Typora
typora README.md &
```

### Mark Text

```bash
# Download and install Mark Text
wget https://github.com/marktext/marktext/releases/download/v0.17.1/marktext-amd64.deb
sudo dpkg -i marktext-amd64.deb
sudo apt-get install -f  # Fix dependencies if needed

# Launch Mark Text
marktext README.md &
```

### Remarkable

```bash
# Install Remarkable
sudo apt update && sudo apt install remarkable

# Launch Remarkable
remarkable README.md &
```

### Terminal Markdown Viewers

```bash
# Install glow (markdown viewer)
sudo apt install glow

# View markdown files
glow README.md
glow docs/

# Install mdless (markdown pager)
gem install mdless
mdless README.md

# Install grip (GitHub-flavored markdown preview)
pip3 install grip
grip README.md  # Opens in browser at localhost:6419
```

## 📂 File Management Tools

### Ranger (Terminal File Manager)

```bash
# Install ranger
sudo apt update && sudo apt install ranger

# Launch ranger
ranger

# Ranger shortcuts:
# j/k: Navigate up/down
# h/l: Navigate folders
# Space: Select files
# yy: Copy
# dd: Cut
# pp: Paste
# /: Search
# S: Open shell in current directory
# q: Quit

# Configure ranger
ranger --copy-config=all

# Edit configuration
nano ~/.config/ranger/rc.conf
```

### Midnight Commander (mc)

```bash
# Install mc
sudo apt update && sudo apt install mc

# Launch mc
mc

# MC features:
# - Dual-pane interface
# - Built-in editor (mcedit)
# - FTP/SSH support
# - Archive browsing
# - Syntax highlighting
```

### GUI File Managers

```bash
# Install Thunar (lightweight)
sudo apt install thunar

# Install Dolphin (KDE)
sudo apt install dolphin

# Install Nautilus (GNOME)
sudo apt install nautilus
```

## ⚙️ Configuration & Setup

### SSH Configuration for Remote Editing

```bash
# Generate SSH key if not exists
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy SSH key to server
ssh-copy-id user@your-server.com

# Configure SSH
cat << 'EOF' > ~/.ssh/config
Host ghostfolio-server
    HostName your-server.com
    User your-username
    Port 22
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
EOF

# Use with editors
code remote-ssh://ghostfolio-server/path/to/project
nano scp://ghostfolio-server/path/to/file
```

### Git Configuration

```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
git config --global core.editor nano  # or vim, code --wait

# Useful Git aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --oneline --graph --decorate --all"
```

### Environment Setup

```bash
# Create useful aliases
cat << 'EOF' >> ~/.bashrc

# Docker aliases
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcp='docker compose ps'

# Navigation aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Ghostfolio project aliases
alias ghost='cd /path/to/ghostfolio-docker'
alias ghost-logs='docker compose logs -f'
alias ghost-status='docker compose ps'

# Editor aliases
alias vi='vim'
alias nano='nano -T 4'  # 4-space tabs
alias edit='nano'
EOF

source ~/.bashrc
```

## 🔌 Editor Plugins & Extensions

### VS Code Essential Extensions

```json
{
  "recommendations": [
    "ms-vscode.vscode-docker",
    "redhat.vscode-yaml",
    "yzhang.markdown-all-in-one",
    "eamodio.gitlens",
    "ms-vscode-remote.remote-ssh",
    "rangav.vscode-thunder-client",
    "ms-vscode.theme-monokai-dimmed",
    "streetsidesoftware.code-spell-checker",
    "shd101wyy.markdown-preview-enhanced",
    "ms-vscode.live-server"
  ]
}
```

### Vim Essential Plugins

```vim
" Add to ~/.vimrc
call plug#begin('~/.vim/plugged')

" File tree
Plug 'preservim/nerdtree'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git integration
Plug 'tpope/vim-fugitive'

" Status line
Plug 'vim-airline/vim-airline'

" Syntax highlighting
Plug 'sheerun/vim-polyglot'

" Auto pairs
Plug 'jiangmiao/auto-pairs'

" Color scheme
Plug 'morhetz/gruvbox'

call plug#end()

" Plugin configurations
map <C-n> :NERDTreeToggle<CR>
let g:airline#extensions#tabline#enabled = 1
colorscheme gruvbox
```

## 🚀 Workflow Tips

### Efficient Docker File Editing

```bash
# Create project-specific editor configuration
cd /path/to/ghostfolio-docker

# VS Code workspace settings
mkdir -p .vscode
cat << 'EOF' > .vscode/settings.json
{
    "files.associations": {
        "docker-compose*.yml": "dockercompose",
        "*.env*": "properties"
    },
    "yaml.schemas": {
        "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json": [
            "docker-compose*.yml"
        ]
    },
    "editor.rulers": [80, 120],
    "editor.renderWhitespace": "trailing",
    "files.trimTrailingWhitespace": true
}
EOF

# Create tasks for common operations
cat << 'EOF' > .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Docker Compose Up",
            "type": "shell",
            "command": "docker compose up -d",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Docker Compose Down",
            "type": "shell",
            "command": "docker compose down",
            "group": "build"
        },
        {
            "label": "View Logs",
            "type": "shell",
            "command": "docker compose logs -f",
            "group": "test"
        }
    ]
}
EOF
```

### Quick File Templates

```bash
# Create templates directory
mkdir -p ~/.config/templates

# Docker Compose template
cat << 'EOF' > ~/.config/templates/docker-compose.yml
version: '3.8'

services:
  app:
    image: 
    container_name: ${PROJECT_NAME}-app
    restart: unless-stopped
    ports:
      - "${PORT}:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - ./data:/app/data
    depends_on:
      - db

  db:
    image: postgres:15
    container_name: ${PROJECT_NAME}-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./data/db:/var/lib/postgresql/data

volumes:
  db_data:
EOF

# Environment file template
cat << 'EOF' > ~/.config/templates/.env
# Project Configuration
PROJECT_NAME=myproject
PORT=3000

# Database Configuration
DB_NAME=mydb
DB_USER=myuser
DB_PASSWORD=CHANGE_THIS_PASSWORD

# Security
JWT_SECRET=CHANGE_THIS_SECRET
EOF

# Template usage function
template() {
    if [ -f ~/.config/templates/"$1" ]; then
        cp ~/.config/templates/"$1" ./"$1"
        echo "Template $1 copied to current directory"
    else
        echo "Template $1 not found"
    fi
}

# Add to ~/.bashrc
echo 'template() { if [ -f ~/.config/templates/"$1" ]; then cp ~/.config/templates/"$1" ./"$1"; echo "Template $1 copied"; else echo "Template $1 not found"; fi }' >> ~/.bashrc
```

### Markdown Editing Workflow

```bash
# Install markdown tools
sudo apt install pandoc  # Document converter
npm install -g markdownlint-cli  # Linting
pip3 install grip  # GitHub preview

# Markdown lint configuration
cat << 'EOF' > ~/.markdownlintrc
{
  "MD013": { "line_length": 120 },
  "MD033": false,
  "MD041": false
}
EOF

# Preview markdown function
mdpreview() {
    if [ "$1" ]; then
        grip "$1" &
        echo "Markdown preview available at http://localhost:6419"
    else
        echo "Usage: mdpreview filename.md"
    fi
}

# Add to ~/.bashrc
echo 'mdpreview() { if [ "$1" ]; then grip "$1" & ; echo "Preview at http://localhost:6419"; else echo "Usage: mdpreview file.md"; fi }' >> ~/.bashrc
```

## 📝 Quick Reference

### Editor Comparison

| Editor | Difficulty | Features | Best For |
|--------|------------|----------|----------|
| nano | Easy | Basic editing | Quick edits, beginners |
| micro | Easy | Modern features | Modern terminal editing |
| vim/neovim | Hard | Highly extensible | Power users |
| gedit | Easy | GUI simplicity | Simple GUI editing |
| Kate | Medium | Advanced features | KDE users |
| VS Code | Medium | Full IDE | Development projects |
| Sublime | Medium | Fast, extensible | Professional editing |

### Essential Shortcuts

#### Nano
- `Ctrl+O`: Save
- `Ctrl+X`: Exit
- `Ctrl+W`: Search
- `Ctrl+\`: Replace

#### Vim
- `i`: Insert mode
- `Esc`: Normal mode
- `:w`: Save
- `:q`: Quit
- `/`: Search

#### VS Code
- `Ctrl+S`: Save
- `Ctrl+P`: Quick open
- `Ctrl+Shift+P`: Command palette
- `Ctrl+``: Terminal

---

💡 **Pro Tip**: Start with nano or micro for simplicity, then gradually move to more powerful editors like vim or VS Code as your needs grow. For Docker projects, VS Code with Docker extensions provides excellent integration!
