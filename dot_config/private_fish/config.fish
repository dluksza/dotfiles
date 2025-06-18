if status is-interactive
    # Commands to run in interactive sessions can go here
    # alias ls="ls --color=always"
    # alias gradle="./gradlew --console plain"
    # alias gr=gradle
    # alias f="flutter"
    # alias d="dart"
    # alias ft="f test"
    # alias dt="d test"
    alias vi='nvim'
    alias v='vi'
    alias mls='melos'
    alias mlsck='melos check'
    alias mlsbs='melos bootstrap'

    # direnv
    set -g direnv_fish_mode eval_on_arrow
    set -g direnv_fish_mode eval_after_arrow
    set -g direnv_fish_mode disable_arrow

    set -gx CLICOLOR true

    starship init fish | source
end

direnv hook fish | source
