:; # vim: set ft=sh:
:; # The line above is a no-op in bash; cmd.exe ignores `:;` and treats `#` as a label.
:; exec bash "$(dirname "$0")/$1" "${@:2}"
@echo off
bash "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
