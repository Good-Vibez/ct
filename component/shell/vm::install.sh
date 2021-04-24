# vim: et ts=2 sw=2 ft=bash

main() {
  ui::doing "BASE"
  CDI::install:base_devel
  config::fish
  config::bash
  config::tmux
  config::nvim
  config::git
  config::dnsmasq
  config::resolved
  ui::doing "RBENV"
  CDI::install:rbenv
  CDI::install:user_paths.ccache
  ui::doing "HMBRW"
  CDI::install:homebrew
  ui::doing "HMBRW_PKGS"
  brew:install "${BREW_PACKAGES[@]}"
  ui::doing "NVIM"
  CDI::install:vim-plugged
  pip3 install neovim
  nvim -n --headless -c 'PlugInstall' -c 'qa!'
  (
    # plug YouCompleteMe needs gcc@5 ¯\_(ツ)_/¯
    brew install gcc@5 &&
    cd $HOME/.local/share/nvim/plugged/YouCompleteMe &&
    python3 ./install.py --rust-completer &&
    brew uninstall gcc@5 &&
    true;
  )

  ui::doing "OMF"
  CDI::install:omf
  ui::doing "CARGO"
  CDI::install:cargo
  CDI::user_init:load
  # ui::doing "XFCE4"
  # UDI::install:xfce4
  # ui::doing "CT"
  # CDI::install:ct
  config::user #(shell, ...?)

  ui::doing "CT_DEV"
  git:init https://github.com/Good-Vibez/ct ct --branch dev
  mkdir -pv ct/.local/etc
  touch ct/.local/etc/rc.env
  (
    cd ct
    direnv allow .
    ui::doing "CT_DEV-build"
    ( cd component/cargo && cargo build --workspace --all-targets )
    ui::doing "CT_DEV-build_release"
    ( cd component/cargo && cargo build --workspace --all-targets --release )
    ui::doing "CT_DEV-sudo:install"
    .cache/cargo/release/xs -f dev_exec/::sanctioned/sudo:install
  )
echo "*] Just chillin'"
}

COMMON_PACKAGES=(
  ccache
  curl
  gcc
  git
  htop
  make
  python3
  dnsmasq
)
DEBIAN_APT_NEEDS=(
  apt-utils
  build-essential
  dialog
)
DEBIAN_APT_KEPT_BACK=(
  linux-headers-generic
  linux-headers-virtual
  linux-image-virtual
  linux-virtual
  man-db
)
PACMAN_AUR_NEEDS=(
  base-devel
  pacman-contrib
  man-db
)
PACMAN_MIRROR_UTIL=rate-arch-mirrors  # AUR
UBUNTU_MIRROR_UTIL=apt-smart          # pip3
RUBY_DEPS_DEB=(
  libssl-dev
  zlib1g-dev
)
BREW_PACKAGES=(
  ${COMMON_PACKAGES[@]}

  # System and gnu
  cmake
  findutils
  gnu-sed
  grep
  zlib
  # libressl

  # Tools
  darkhttpd
  direnv
  entr
  fzf
  gnupg
  jq
  nvim
  pv

  # Dev/Workspace/Aesthetics
  fish
  lsd
  tmux
)

ui::doing() {
  printf '==> %s\n' "$1"
}
ui::add() {
  printf '(\x1b[38;5;111m+\x1b[m) \x1b[38;5;112m%s\x1b[m \x1b[38;5;118m%s\x1b[m' "$@"
}

sudo:() {
  printf '(\x1b[38;5;152msudo\x1bm) %s' "$*" #1>&2
  sudo "$@"
}

file::line:uniq() {
  local file="$1"; shift;
  local line="$1"; shift;

  if grep --fixed-strings --regexp "$line" "$file" >/dev/null 2>/dev/null
  then
    true
  else
    echo "$line"
  fi
}
file::line:add.uniq() {
  local file="$1"; shift;
  local line="$1"; shift;

  file::line:uniq "$file" "$line" >>$file
}

config::dnsmasq() {
  ui::doing "Configure dnsmasq"
  sudo tee /etc/dnsmasq.conf >/dev/null <<-'EOS'
    #address=/github.com/127.0.0.1
    #address=/ghcr.io/127.0.0.1
    #address=/github.com/::1
    #address=/ghcr.io/::1
    port=5353
EOS
  sudo systemctl restart dnsmasq
  sudo systemctl status dnsmasq
}
config::resolved() {
  local target_dir=/etc/systemd/resolved.conf.d/
  local target=70-caching.conf
  ui::doing "Configure systemd-resolved"
  sudo mkdir -p "$target_dir"
  sudo tee "$target_dir/$target" >/dev/null <<-'EOS'
[Resolve]
DNS=127.0.0.1:5353
EOS
  sudo systemctl daemon-reload
  sudo systemctl restart systemd-resolved
  sudo systemctl status systemd-resolved
}
config::apt:sources() {
  ui::doing "Install ubuntu apt sources"
  sudo tee /etc/aptlsources.list >/dev/null <<-'EOS'
    #deb http://mirror.eu.kamatera.com/ubuntu focal main restricted
    #deb http://mirror.eu.kamatera.com/ubuntu focal-updates main restricted
    #deb http://mirror.eu.kamatera.com/ubuntu focal universe
    #deb http://mirror.eu.kamatera.com/ubuntu focal-updates universe
    #deb http://mirror.eu.kamatera.com/ubuntu focal multiverse
    #deb http://mirror.eu.kamatera.com/ubuntu focal-updates multiverse
    #deb http://mirror.eu.kamatera.com/ubuntu focal-backports main restricted universe multiverse
    deb http://localhost:8080/ubuntu focal main restricted
    deb http://localhost:8080/ubuntu focal-updates main restricted
    deb http://localhost:8080/ubuntu focal universe
    deb http://localhost:8080/ubuntu focal-updates universe
    deb http://localhost:8080/ubuntu focal multiverse
    deb http://localhost:8080/ubuntu focal-updates multiverse
    deb http://localhost:8080/ubuntu focal-backports main restricted universe multiverse
    deb http://security.ubuntu.com/ubuntu focal-security main restricted
    deb http://security.ubuntu.com/ubuntu focal-security universe
    deb http://security.ubuntu.com/ubuntu focal-security multiverse
EOS
}
config::pacman:mirrorlist() {
  ui::doing "Install arch pacman mirrorlist"
  sudo tee /etc/pacman.d/mirrorlist >/dev/null <<-'EOS'
    #Server = https://archlinux.koyanet.lv/archlinux/$repo/os/$arch
    #Server = http://mirror.puzzle.ch/archlinux/$repo/os/$arch
    #Server = http://mirror.datacenter.by/pub/archlinux/$repo/os/$arch
    #Server = https://archlinux.uk.mirror.allworldit.com/archlinux/$repo/os/$arch
    #Server = http://mirror.easylee.nl/archlinux/$repo/os/$arch
    Server = http://localhost:8080/archlinux/$repo/os/$arch
EOS
}
config::fish() {
  mkdir -pv $HOME/.config/fish/conf.d
  mkdir -pv $HOME/.config/fish/functions

  tee $HOME/.config/fish/conf.d/osx_gnu.fish >/dev/null <<-'EOS'
  if test (uname -s) = "Darwin"
    set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
    set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
    set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
  end
EOS
  tee $HOME/.config/fish/conf.d/vi.fish >/dev/null <<-'EOS'
  set -g fish_key_bindings fish_vi_key_bindings
EOS
  tee $HOME/.config/fish/conf.d/key_bindings.fish >/dev/null <<-'EOS'
  bind -M insert \c] forward-char
  bind -M insert \cP "commandline --replace 'nvim (git:ls-files | fzf)'"
EOS
  tee $HOME/.config/fish/conf.d/CDI::user_init:00-user_paths.hook.fish >/dev/null <<-'EOS'
    set -x fish_user_paths (string split0 <$HOME/.user_paths | sort | uniq) $fish_user_paths
EOS
  tee $HOME/.config/fish/functions/CDI::user_init:reload.fish >/dev/null <<-'EOS'
  function CDI::user_init:reload
    set -l target $HOME/.config/fish/conf.d/CDI::user_init:01-hooks.fish
    for command in (string split0 <$HOME/.user_init | sort | uniq)
      eval "$command"
    end | tee $target
    source $target
  end
EOS
  tee $HOME/.config/fish/functions/ls.fish >/dev/null <<-'EOS'
  function ls
    /home/linuxbrew/.linuxbrew/bin/lsd $argv
  end
EOS
}
config::bash() {
  tee $HOME/.user_init.bash >/dev/null <<-'EOS'
  if test -f $HOME/.user_paths
  then
    export PATH="$(cat $HOME/.user_paths | tr \\000 :):$PATH"
  fi
  CDI::user_init:reload() {
    target=$HOME/.CDI::user_init:hook.bash
    cat $HOME/.user_init \
    | tr \\000 \\n \
    | sort \
    | uniq \
    | bash \
    | tee $target
    source $target
  }
  if test -f $HOME/.CDI::user_init:hook.bash
  then
    source $HOME/.CDI::user_init:hook.bash
  fi
EOS
  file::line:add.uniq $HOME/.bashrc source $HOME/.user_init.bash
}
config::tmux() {
  tee $HOME/.tmux.conf >/dev/null <<-'EOS'
  set -g escape-time 0
  set -g mode-keys vi
  set -g status-style bg=colour24
  set -g status-left-style bg=colour162
  set -g status-right-style bg=colour17,fg=colour92
  set -g default-terminal screen-256color
EOS
}
config::user() {
  local fish_bin="$(which fish)"

  echo "$fish_bin" | sudo tee -a /etc/shells
  sudo chsh --shell "$fish_bin" "$(id -nu)"
}
config::nvim() {
  mkdir -pv $HOME/.config/nvim
  tee $HOME/.config/nvim/init.vim >/dev/null <<-'EOS'
  call plug#begin(stdpath('data') . '/plugged')

  Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-sleuth'
  Plug 'rust-lang/rust.vim'
  Plug 'google/vim-jsonnet'
  Plug 'kyoz/purify', { 'rtp': 'vim' }
  Plug 'relastle/bluewery.vim'
  Plug 'preservim/nerdtree'
  Plug 'rafi/awesome-vim-colorschemes'
  Plug 'ron-rs/ron.vim'

  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  "Plug 'junegunn/fzf.vim'

  call plug#end()

  "nmap <C-p> :call fzf#run({'sink':'e','source':'git ls-files .','window':{'width': 0.9,'height': 0.6}})<CR>
  set termguicolors
  set number

  " """ BlueWery """
  " " For dark
  " colorscheme bluewery
  " let g:lightline = { 'colorscheme': 'bluewery' }
  "
  " "" For light
  " "colorscheme bluewery-light
  " "let g:lightline = { 'colorscheme': 'bluewery_light' }
  colorscheme apprentice
EOS
}

config::git() {
  local target_dir=$HOME/.config/git
  local target=$target_dir/config
  mkdir -pv $target_dir
  cat >$target <<-'EOS'
[alias]
s = status --short

h = log --pretty --oneline --decorate --graph
ha = h --all
h1 = h -1
hs = h --show-signature

m = commit
ma = commit --amend --reset-author

d = diff
ds = diff --cached

addu = add --update

reup = remote update

pf = push --force-with-lease

co = checkout
EOS
}

pacman:install() {
  sudo pacman -Syu --noconfirm --needed --quiet "$@"
}

apt:install() {
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install "$@" -y
}

apt:install.delayed() {
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install "$@" -y
}

aur:install() {
  local name="$1"; shift;

  curl https://aur.archlinux.org/cgit/aur.git/snapshot/$name.tar.gz >$name.tar.gz

  tar xvf $name.tar.gz
  (
    cd $name
    makepkg -sic --noconfirm
  )
}

git:init() {
  local source="$1"; shift;
  local target="$1"; shift;

  if test -d $target/.git
  then
    git -C $target remote update --prune
  else
    git clone "$@" $source $target
  fi
}

gh:init() {
  local name="$1"; shift;
  local target="$1"; shift;

  source="https://github.com/$name.git"
  git:init "$source" "$target" --depth 1 "$@"
}

CDI::linux:distro() {
  local node_name="$(uname --nodename)"
  case "$node_name" in
    ubuntu*)
      echo "Ubuntu"
      ;;
    arch*)
      echo "Arch"
      ;;
    *)
      printf 'Unknown node_name: %s\n' "$node_name" 1>&2
      exit 1
  esac
}

CDI::install:base_devel() {
  case "$( CDI::linux:distro )" in
    (Ubuntu)
      config::apt:sources
      apt:install \
	"${COMMON_PACKAGES[@]}" \
	"${DEBIAN_APT_NEEDS[@]}" \
	"${DEBIAN_APT_KEPT_BACK[@]}" \
	"${RUBY_DEPS_DEB[@]}" \
      ;;
    (Arch)
      config::pacman:mirrorlist
      pacman:install \
	"${COMMON_PACKAGES[@]}" \
	"${PACMAN_AUR_NEEDS}" \
      ;;
  esac
}

CDI::_:add() {
  local list="$1"; shift;
  local item="$1"; shift;

  format="$(
    if test -f "$HOME/.$list"
    then
      printf '%s' '\x00%s'
    else
      printf '%s' '%s'
    fi
  )"
  printf "$format" "$item" |
    tee -a "$HOME/.$list" |
    tee /dev/null >/dev/null
}
CDI::user_paths:add() {
  local extra_path="$1"; shift;
  CDI::_:add user_paths "$extra_path"
}
CDI::user_init:add.eval() {
  local hook="$1"; shift;
  CDI::_:add user_init "$hook"
}
CDI::user_init:load () {
  source $HOME/.user_init.bash
  CDI::user_init:reload
}

CDI::install:rbenv-build() {
  local target="$(rbenv root)"/plugins

  mkdir -p "$target"
  gh:init "rbenv/ruby-build" "$target/ruby-build"
}
CDI::install:rbenv() {
  if $HOME/.rbenv/bin/rbenv version >/dev/null 2>/dev/null
  then
    true
  else
    gh:init "rbenv/rbenv" "$HOME/.rbenv"
    ( cd ~/.rbenv && src/configure && make -C src )

    PATH2="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
    PATH="$PATH2" CDI::install:rbenv-build
    curl -fsSL "https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor" \
    | PATH="$PATH2" bash
  fi
  # rbenv init - will not set the PATH
  CDI::user_paths:add "$HOME/.rbenv/bin"
  CDI::user_init:add.eval '$HOME/.rbenv/bin/rbenv init -'
  CDI::user_init:load
}
CDI::install:ruby.3.0.1() {
  ui::doing "RB_3.0.1"
  if rbenv versions --bare --skip-aliases | grep 3.0.1
  then
    true
  else
    rbenv install 3.0.1
  fi
}
CDI::install:homebrew() {
  # This install script is clever enough to skip very fast
  #curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" | bash

  #if ! id -u linuxbrew
  #then
  #  ui::add user linuxbrew
  #  sudo adduser -D -s /bin/bash linuxbrew
  #fi
  #file::line:uniq \
  #  'linuxbrew ALL=(ALL) NOPASSWD:ALL' \
  #  /etc/sudoers \
  #| sudo: tee -a /etc/sudoers >/dev/null

  local target=/home/linuxbrew
  local mu="$(id -u)"
  local mg="$(id -g)"
  sudo: mkdir -pv $target
  sudo: chown -R $mu:$mg $target
  gh:init Homebrew/Brew $target/.linuxbrew

  # brew shellenv - will set the PATH
  CDI::user_init:add.eval "$target/.linuxbrew/bin/brew shellenv -"
  CDI::user_init:load

  brew update
  brew doctor
}

CDI::install:user_paths.ccache() {
  case "$( CDI::linux:distro )" in
    Ubuntu)
      CDI::user_paths:add "/lib/ccache"
      ;;
    Arch)
      CDI::user_paths:add "/lib/ccache/bin"
      ;;
  esac
}
CDI::install:vim-plugged() {
  curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}
CDI::install:omf() {
  if fish -c 'omf >/dev/null' 2>/dev/null
  then
    true
  else
    curl -sL https://get.oh-my.fish >omf::install.fish
    fish omf::install.fish --noninteractive
    fish -c 'omf install flash'
  fi
}

CDI::install:cargo() {
  if $HOME/.cargo/bin/cargo --version >/dev/null 2>/dev/null
  then
    true
  else
    ui::doing "RUST"
    brew install rustup-init
    rustup-init -y
  fi
  CDI::user_paths:add "$HOME/.cargo/bin"
  # We don't even bother with .cargo/env
}

CDI::install:ct() {
  brew tap Good-Vibez/tap
  brew:install2 --HEAD \
    Good-Vibez/tap/xs \
    Good-Vibez/tap/xc \
  ;
}

UDI::install:xfce4() {
  case "$( CDI::linux:distro )" in
    Ubuntu)
      apt:install.delayed xfce4
      ;;
    Arch)
      pacman:install xfce4 xorg-xinit
      ;;
  esac
}

brew:install() {
  brew:install2 "" "${@}"
}
brew:install2() {
  local brargs="$1"; shift;

  if jq --version >/dev/null 2>/dev/null
  # If we have no jq then it's the first brew run, and this
  # check makes no sense anyway.
  then
    brew info --json --formulae "${@}" \
    | jq \
      --raw-output \
      --join-output \
      --compact-output '.
	| map(select((.installed | length) == 0))
	| map(.name)
	| join("\u0000")
      ' \
    | xargs -0 -I::: brew install $brargs ::: # NOTE: DO NOT QUOTE $brargs
  else
    CDI::user_init:load
    brew install "${@}"
  fi
}

if test "${VMINSTALLLIB-x}" = "x"
then
  ui::doing "MAIN"
  main
fi
