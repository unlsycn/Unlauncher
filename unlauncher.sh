#!/usr/bin/env bash

name=Unlauncher
frequency_file=~/.local/share/unlauncher/frequency

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
    echo $XDG_DATA_DIRS | sed 's|:|/applications:|g;s|$|/applications|' | tr ':' '\n' | while read -r d; do ls $d | rg '\.desktop$' | while read -r e; do parse_desktop_entry "$d/$e"; done; done
    echo $PATH | tr ':' '\n' | xargs -n 1 ls | awk '{print $0 "\t" $0 "\t" $0 "\ttrue"}'
} | awk -F'\t' '!y[$0]++ && (!x[$1]++ || $4 == "false")' | fzfmenu $name --with-nth=2 --delimiter='\t' --no-sort)

[[ -n "$selected_app" ]] && {
    echo "\"$selected_app\"" | xargs fre --store_name "$frequency_file" --add
    systemd-run --user --scope $(cut -f3 <<<"$selected_app")
}
