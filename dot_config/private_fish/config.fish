if status is-interactive
    # Commands to run in interactive sessions can go here
    # alias ls="ls --color=always"
    # alias gradle="./gradlew --console plain"
    # alias gr=gradle
    alias f="fvm flutter"
    alias d="fvm dart"
    alias fr="fvm flutter run"
    alias ft="fvm flutter test"
    alias fat="fvm flutter attach"
    # alias dt="d test"
    alias c='bun run --bun claude'
    alias vi='nvim'
    alias v='vi'
    alias mls='melos'
    alias mlsck='melos check'
    alias mlsbs='melos bootstrap'

    alias gpf!='git push --force'

    # direnv
    set -g direnv_fish_mode eval_on_arrow
    set -g direnv_fish_mode eval_after_arrow
    set -g direnv_fish_mode disable_arrow

    set -gx CLICOLOR true

    fish_add_path -a "/Applications/Nix Apps/WhatsApp.app/Contents/MacOS/"

    # disable abbreviation auto-expanstion
    bind ' ' self-insert

    starship init fish | source
end

alias jq="jaq"

set fish_greeting
set -g GPG_TTY $(tty)

set -g GEM_HOME "~/.gem"
set -g BUN_INSTALL "~/.bun"

fish_add_path "~/fvm/default/bin"
fish_add_path "~/.mix/escripts"
fish_add_path "~/.pub-cache/bin"
fish_add_path "~/.bun/bin"

set -gx PATH ~/fvm/default/bin $PATH
set -gx PATH ~/.mix/escripts $PATH
set -gx PATH ~/.pub-cache/bin $PATH

direnv hook fish | source
