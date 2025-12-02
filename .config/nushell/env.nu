# Nushell Environment Configuration

# Import environment from .zshenv using zsh
# This sources .zshenv and captures the resulting environment
^zsh -c $"source ($env.HOME)/.zshenv && env" | lines | parse "{key}={value}" | where key !~ "^(_|SHLVL|PWD|OLDPWD)$" | each {|it| {$it.key: $it.value}} | reduce {|it, acc| $acc | merge $it} | load-env


# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
  ($nu.default-config-dir | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
  ($nu.default-config-dir | path join 'plugins')
]

# Editor configuration
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"


# customize keybindings
$env.config.keybindings = [
  {
    name: fuzzy_history
    modifier: control
    keycode: char_r
    mode: [emacs, vi_normal, vi_insert]
    event: [
      {
        send: ExecuteHostCommand
        cmd: "do {
          commandline edit --insert (
            history
            | get command
            | reverse
            | uniq
            | str join (char -i 0)
            | fzf --scheme=history 
                --read0
                --layout=reverse
                --height=40%
                # --bind 'ctrl-/:change-preview-window(right,70%|right)'
                # --preview='echo -n {} | nu --stdin -c \'nu-highlight\''
                # Run without existing commandline query for now to test composability
                # -q (commandline)
            | decode utf-8
            | str trim
          )
        }"
      }
    ]
  }
]



######### STARSHIP #########

$env.STARSHIP_SHELL = "nu"

def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "



######### HOMEBREW #########

$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"
$env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin' | prepend '/opt/homebrew/sbin')
$env.MANPATH = ($env.MANPATH? | default "" | prepend "/opt/homebrew/share/man")
$env.INFOPATH = ($env.INFOPATH? | default "" | prepend "/opt/homebrew/share/info")


######### CARAPACE #########

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"



######### PATH #########

$env.PATH = ($env.PATH | append '/usr/local/bin')

