# vim: et ts=2 sw=2 ft=bash

main() {
  ui::doing "BASE"
  CDI::install:base_devel
  config::fish
  config::bash
  config::tmux
  config::nvim
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

  ui::doing "OMF"
  CDI::install:omf
  ui::doing "CARGO"
  CDI::install:cargo
  CDI::user_init:load
  ui::doing "XFCE4"
  UDI::install:xfce4
  ui::doing "CT"
  CDI::install:ct
  config::user #(shell, ...?)

  ui::doing "CT_DEV"
  git:init https://github.com/Good-Vibez/ct ct --branch dev
  mkdir -pv ct/.local/etc
  touch ct/.local/etc/rc.env
  cd ct
  direnv allow .
  ui::doing "CT_DEV-build"
  xs -f dev_exec/cargo:build
  ui::doing "CT_DEV-build_release"
  xs -f dev_exec/cargo:build_release
  ui::doing "CT_DEV-sudo:install"
  xs -f dev_exec/::sanctioned/sudo:install
echo "*] Just chillin'"
}
# plug YouCompleteMe needs gcc@5 ¯\_(ツ)_/¯

COMMON_PACKAGES=(
  ccache
  curl
  gcc
  git
  htop
  make
  python3
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
)
PACMAN_AUR_NEEDS=(
  base-devel
  pacman-contrib
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
  gcc@5
  # libressl

  # Tools
  direnv
  gnupg
  jq
  nvim
  pv
  fzf

  # Dev/Workspace/Aesthetics
  fish
  lsd
  tmux
)

ui::doing() {
  printf '==> %s\n' "$1"
}

file::line:add.uniq() {
  file="$1"; shift;
  line="$1"; shift;

  if grep --fixed-strings --regexp "$line" "$file" >/dev/null 2>/dev/null
  then
    true
  else
    echo "$line" >>$file
  fi
}

config::apt:sources() {
  ui::doing "Instal ubuntu apt sources"
  sudo tee /etc/apt/sources.list >/dev/null <<-'EOS'
    deb http://mirror.eu.kamatera.com/ubuntu focal main restricted
    deb http://mirror.eu.kamatera.com/ubuntu focal-updates main restricted
    deb http://mirror.eu.kamatera.com/ubuntu focal universe
    deb http://mirror.eu.kamatera.com/ubuntu focal-updates universe
    deb http://mirror.eu.kamatera.com/ubuntu focal multiverse
    deb http://mirror.eu.kamatera.com/ubuntu focal-updates multiverse
    deb http://mirror.eu.kamatera.com/ubuntu focal-backports main restricted universe multiverse
    deb http://security.ubuntu.com/ubuntu focal-security main restricted
    deb http://security.ubuntu.com/ubuntu focal-security universe
    deb http://security.ubuntu.com/ubuntu focal-security multiverse
EOS
}
config::pacman:mirrorlist() {
  ui::doing "Instal arch pacman mirrorlist"
  sudo tee /etc/pacman.d/mirrorlist >/dev/null <<-'EOS'
    Server = https://archlinux.koyanet.lv/archlinux/$repo/os/$arch
    Server = http://mirror.puzzle.ch/archlinux/$repo/os/$arch
    Server = http://mirror.datacenter.by/pub/archlinux/$repo/os/$arch
    Server = https://archlinux.uk.mirror.allworldit.com/archlinux/$repo/os/$arch
    Server = http://mirror.easylee.nl/archlinux/$repo/os/$arch
EOS
}
config::fish() {
  mkdir -pv $HOME/.config/fish/conf.d
  tee $HOME/.config/fish/conf.d/osx_gnu.fish >/dev/null <<-'EOS'
  if test (uname -s) = "Darwin"
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
  tee $HOME/.config/fish/conf.d/ls.fish >/dev/null <<-'EOS'
  function ls
    /home/linuxbrew/.linuxbrew/bin/lsd $argv
  end
EOS
  tee $HOME/.config/fish/conf.d/CDI::user_init.hook.fish >/dev/null <<-'EOS'
  set -x fish_user_paths (string split0 <$HOME/.user_paths) $fish_user_paths
  for command in (string split0 <$HOME/.user_init)
    eval "$command" | source
  end
EOS
}
config::bash() {
  tee $HOME/.user_init.bash >/dev/null <<-'EOS'
  if test -f $HOME/.user_paths
  then
    export PATH="$(cat $HOME/.user_paths | tr \\000 :):$PATH"
  fi
  if test -f $HOME/.user_init
  then
    eval "$(cat $HOME/.user_init | tr \\000 \\n | bash)"
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
  sudo chsh --shell "$(which fish)" "$(id -nu)"
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
  cd $name

  makepkg -sic --noconfirm
}

git:init() {
  source="$1"; shift;
  target="$1"; shift;

  if test -d $target
  then
    git -C $target remote update --prune
  else
    git clone "$@" $source $target
  fi
}

gh:init() {
  name="$1"; shift;
  target="$1"; shift;

  source="https://github.com/$name.git"
  git:init "$source" "$target" --depth 1
}

CDI::linux:distro() {
  node_name="$(uname --nodename)"
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
  list="$1"; shift;
  item="$1"; shift;

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
  extra_path="$1"; shift;
  CDI::_:add user_paths "$extra_path"
}
CDI::user_init:add.eval() {
  hook="$1"; shift;
  CDI::_:add user_init "$hook"
}
#
# CDI::user_init contract
# - Things can be added to lists user_paths, user_init
# - They can be load/reloaded with :load()
CDI::user_init:load() {
  source $HOME/.user_init.bash
}

CDI::install:rbenv-build() {
  target="$(rbenv root)"/plugins

  mkdir -p "$target"
  gh:init "rbenv/ruby-build" "$target/ruby-build"
}
CDI::install:rbenv() {
  if $HOME/.rbenv/bin/rbenv version >/dev/null 2>/dev/null
  then
    true
  else
    gh:init "rbenv/rbenv" "$HOME/.rbenv"
    cd ~/.rbenv && src/configure && make -C src

    CDI::user_paths:add "$HOME/.rbenv/bin"
    CDI::user_init:add.eval 'rbenv init -'
    CDI::user_init:load

    CDI::install:rbenv-build
    curl -fsSL "https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor" | bash
  fi
}
CDI::install:ruby.3.0.1() {
  ui::doing "RB_3.0.1"
  CDI::user_init:load
  if rbenv versions --bare --skip-aliases | grep 3.0.1
  then
    true
  else
    rbenv install 3.0.1
  fi
}
CDI::install:homebrew() {
  # Install script clever enough to skip very fast
  curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" | bash
  CDI::user_init:add.eval '/home/linuxbrew/.linuxbrew/bin/brew shellenv -'
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
    CDI::user_init:load
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
    brew: install rustup-init
    rustup-init -y
    CDI::user_paths:add "$HOME/.cargo/bin"
  fi
}

CDI::install:ct() {
  brew: tap Good-Vibez/tap
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

brew:() {
  /home/linuxbrew/.linuxbrew/bin/brew "$@"
}
rbenv:() {
  CDI::user_init:load
  rbenv "$@"
}

brew:install() {
  brew:install2 "" "${@}"
}
brew:install2() {
  brargs="$1"; shift;

  CDI::user_init:load
  if jq --version >/dev/null 2>/dev/null
  # If we have no jq then it's the first brew run, and this
  # check makes no sense anyway.
  then
    brew: info --json --formulae "${@}" \
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
    brew: install "${@}"
  fi
}

if test "${VMINSTALLLIB-x}" = "x"
then
  ui::doing "MAIN"
  main
fi
