#!/bin/env bash

name=Unlauncher
frequency_file=~/.local/share/unlauncher/frequency
apps_dirs=/usr/share/applications:~/.local/share/applications/

parse_desktop_entry() {
    while IFS= read -r line; do
        [[ "$line" == "[Desktop Entry]" ]] && in_section=true && continue
        [[ "$line" =~ ^\[.*\]$ ]] && in_section=false
        $in_section && [[ "$line" =~ ^(Name|Exec|Terminal)= ]] && eval "${line%%=*}='${line#*=}'"
    done <"$1"
    echo -e "$(echo "$Exec" | awk '{print $1}' | xargs basename)\t$Name\t$Exec\t${Terminal:-false}"
}

selected_app=$({
    fre --store_name "${frequency_file}" --sorted
    echo "${apps_dirs}" | tr ':' '\n' | xargs -n 1 ls | while IFS= read -r entry; do
        parse_desktop_entry "${apps_dir}/${entry}"
    done
    echo $PATH | tr ':' '\n' | xargs -n 1 ls | awk '{print $0 "\t" $0 "\t" $0 "\ttrue"}'
} | awk -F'\t' '!y[$0]++ && (!x[$1]++ || $4 == "false")' | fzfmenu ${name} --with-nth=2 --delimiter='\t' --no-sort)

if [[ -n "${selected_app}" ]]; then
    echo "\"${selected_app}\"" | xargs fre --store_name "${frequency_file}" --add
    exec=$(echo "${selected_app}" | cut -f 3)
    command=$([[ "$(echo "${selected_app}" | cut -f 4)" == "true" ]] && echo "alacritty -e ${SHELL} -c '${exec} && read'" || echo "${exec}")
    hyprctl dispatch exec "${command}"
fi
