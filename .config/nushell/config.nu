# Nushell Configuration

######### Aliases #########

# lsd aliases
# alias ls = ^lsd
alias nv = ^nvim
alias c = ^code

# Custom commands for aliases that need arguments
def l [] { lsd -la }
def la [] { lsd -a }
def lla [] { lsd -la }
def lt [] { lsd --tree }

# git commands
def gl [] { git log --oneline --decorate --all --graph }
def gs [] { git status }
def gp [] { git pull }
def gps [] { git push }
def gpsf [] { git push --force-with-lease }
def ga [] { git add -A }
def gc [...args] { git checkout ...$args }
def gcleantags [] {
  sh -c "git tag -l | xargs git tag -d && git fetch -t"
}
def gcleanup [] {
  sh -c "git fetch --prune --prune-tags && git branch -vv | grep 'origin/.*: gone]' | awk '{print \$1}' | xargs git branch -D"
}

# directory tree
def ftree [] { tree -h -C }

# SimpleHTTPServer (Python 3 version)
def serve [] { python -m http.server }

# quick cd to parent directories
def --env ".." [] { cd .. }
def --env "...." [] { cd ../.. }
def --env "......" [] { cd ../../.. }
def --env "........" [] { cd ../../../.. }


######### Custom Commands #########

# cargo features - show features for a cargo package
def cargo-features [package: string] {
    cargo metadata --format-version=1 | from json | get packages | where name == $package | get features | first
}

######### Integrations #########

source $"($nu.cache-dir)/carapace.nu"
source ~/.zoxide.nu

# this was generated using:
# cast completions nushell | sed 's/--\([a-z]*\)\.\([a-z]*\)/--\1_\2/g' > ~/.config/nushell/cast-completions.nu
source ~/.config/nushell/cast-completions.nu

######### Configuration Settings #########

# Color theme (defined first so it can be used in config)
# let dark_theme = {
#     separator: white
#     leading_trailing_space_bg: { attr: n }
#     header: green_bold
#     empty: blue
#     bool: white
#     int: white
#     filesize: cyan
#     duration: white
#     date: purple
#     range: white
#     float: white
#     string: white
#     nothing: white
#     binary: white
#     cellpath: white
#     row_index: green_bold
#     record: white
#     list: white
#     block: white
#     hints: dark_gray
# }

# Configure nushell behavior
$env.config = {
    show_banner: false

    ls: {
        use_ls_colors: true
        clickable_links: true
    }

    rm: {
        always_trash: false
    }

    table: {
        mode: rounded
        index_mode: always
        show_empty: true
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
        }
    }

    explore: {
        help_banner: true
        exit_esc: true
    }
    #
    # history: {
    #     max_size: 10000
    #     sync_on_enter: true
    #     file_format: "plaintext"
    # }
    #
    # completions: {
    #     case_sensitive: false
    #     quick: true
    #     partial: true
    #     algorithm: "fuzzy"
    # }
    #
    # cursor_shape: {
    #     emacs: line
    #     vi_insert: line
    #     vi_normal: block
    # }
    #
    # color_config: $dark_theme
    # footer_mode: 25
    # float_precision: 2
    # use_ansi_coloring: true
    # edit_mode: emacs
    # shell_integration: {
    #     osc2: true
    #     osc7: true
    #     osc8: true
    #     osc9_9: false
    #     osc133: true
    #     osc633: true
    #     reset_application_mode: true
    # }
    buffer_editor: nvim
}
