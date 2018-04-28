# Create a new directory and enter it
function md() {
mkdir -p "$@" && cd "$@"
}
# find shorthand
function f() {
    find . -name "$1"
}
# lets toss an image onto my server and pbcopy that bitch.
function scpp() {
    scp "$1" aurgasm@aurgasm.us:~/paulirish.com/i;
    echo "http://paulirish.com/i/$1" | pbcopy;
    echo "Copied to clipboard: http://paulirish.com/i/$1"
}
# Start an HTTP server from a directory, optionally specifying the port
function server() {
local port="${1:-8080}"
open "http://localhost:${port}/"
# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}
# git log with per-commit cmd-clickable GitHub URLs (iTerm)
function gf() {
  local remote="$(git remote -v | awk '/^origin.*\(push\)$/ {print $2}')"
  [[ "$remote" ]] || return
  local user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
  git log $* --name-status --color | awk "$(cat <<AWK
    /^.*commit [0-9a-f]{40}/ {sha=substr(\$2,1,7)}
    /^[MA]\t/ {printf "%s\thttps://github.com/$user_repo/blob/%s/%s\n", \$1, sha, \$2; next}
    /.*/ {print \$0}
AWK
  )" | less -F
}
# Copy w/ progress
cp_p () {
  rsync -WavP --human-readable --progress $1 $2
}
# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}
# Syntax-highlight JSON strings or files
function json() {
if [ -p /dev/stdin ]; then
# piping, e.g. `echo '{"foo":42}' | json`
python -mjson.tool | pygmentize -l javascript
else
# e.g. `json '{"foo":42}'`
python -mjson.tool <<< "$*" | pygmentize -l javascript
fi
}
# take this repo and copy it to somewhere else minus the .git stuff.
function gitexport(){
mkdir -p "$1"
git archive master | tar -x -C "$1"
}
# get gzipped size
function gz() {
echo "orig size (bytes): "
cat "$1" | wc -c
echo "gzipped size (bytes): "
gzip -c "$1" | wc -c
}
# All the dig info
function digga() {
dig +nocmd "$1" any +multiline +noall +answer
}
# Escape UTF-8 characters into their 3-byte format
function escape() {
printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
echo # newline
}
# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
echo # newline
}
# Extract archives - use: extract <file>
# Credits to http://dotfiles.org/~pseup/.bashrc
function extract() {
if [ -f $1 ] ; then
case $1 in
*.tar.bz2) tar xjf $1 ;;
*.tar.gz) tar xzf $1 ;;
*.bz2) bunzip2 $1 ;;
*.rar) rar x $1 ;;
*.gz) gunzip $1 ;;
*.tar) tar xf $1 ;;
*.tbz2) tar xjf $1 ;;
*.tgz) tar xzf $1 ;;
*.zip) unzip $1 ;;
*.Z) uncompress $1 ;;
*.7z) 7z x $1 ;;
*) echo "'$1' cannot be extracted via extract()" ;;
esac
else
echo "'$1' is not a valid file"
fi
}
# @gf3’s Sexy Bash Prompt, inspired by “Extravagant Zsh Prompt”
# Shamelessly copied from https://github.com/gf3/dotfiles
default_username='SeungjoonLee'
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
export TERM=xterm-256color
fi
if tput setaf 1 &> /dev/null; then
tput sgr0
if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
MAGENTA=$(tput setaf 9)
ORANGE=$(tput setaf 172)
GREEN=$(tput setaf 190)
PURPLE=$(tput setaf 141)
WHITE=$(tput setaf 256)
else
MAGENTA=$(tput setaf 5)
ORANGE=$(tput setaf 4)
GREEN=$(tput setaf 2)
PURPLE=$(tput setaf 1)
WHITE=$(tput setaf 7)
fi
BOLD=$(tput bold)
RESET=$(tput sgr0)
else
MAGENTA="\033[1;31m"
ORANGE="\033[1;33m"
GREEN="\033[1;32m"
PURPLE="\033[1;35m"
WHITE="\033[1;37m"
BOLD=""
RESET="\033[m"
fi
function parse_git_dirty() {
[[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
}
function parse_git_branch() {
git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}
# Only show username/host if not default
function usernamehost() {
if [ $USER != $default_username ]; then echo "${MAGENTA}$USER ${WHITE}at ${ORANGE}$HOSTNAME $WHITEin "; fi
}
# iTerm Tab and Title Customization and prompt customization
# http://sage.ucsc.edu/xtal/iterm_tab_customization.html
# Put the string " [bash] hostname::/full/directory/path"
# in the title bar using the command sequence
# \[\e]2;[bash] \h::\]$PWD\[\a\]
# Put the penultimate and current directory
# in the iterm tab
# \[\e]1;\]$(basename $(dirname $PWD))/\W\[\a\]
PS1="\[\e]2;$PWD\[\a\]\[\e]1;\]$(basename "$(dirname "$PWD")")/\W\[\a\]${BOLD}\$(usernamehost)\[$GREEN\]\w\[$WHITE\]\$([[ -n \$(git branch 2> /dev/null) ]] && echo \" on \")\[$PURPLE\]\$(parse_git_branch)\[$WHITE\]\n\$ \[$RESET\]"


# Add your preload path separated by colon(:) eg. $PATH1:$PATH2
export PATH="$PATH"
