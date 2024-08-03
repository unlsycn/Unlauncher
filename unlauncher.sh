#!/bin/env bash

name=Unlauncher
script_file=~/.scripts/bin/unlauncher
frequency_file=~/.local/share/unlauncher/frequency

launcher_cmd() {
    {
        fre --store_name "${frequency_file}" --sorted
        echo $PATH | tr ':' '\n' | xargs -n 1 ls
    } | awk '!x[$0]++' | fzf --no-sort | tee >(xargs -n 1 fre --store_name "${frequency_file}" --add) | xargs -n 1 hyprctl dispatch exec
}

launcher_launch() {
    hyprctl clients | rg "title: ${name}$" || alacritty -T ${name} -o 'font.size=18' -e bash ${script_file} cmd
    hyprctl dispatch focuswindow "title:${name}$"
}

if [ "$1" == "cmd" ]; then
    launcher_cmd
else
    launcher_launch
fi
