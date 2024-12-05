#!/usr/bin/bash

for shotcutfolder in $(find $FLUXI_PATH/fxi/libs -type f -name "*.sh"); do
  source $shotcutfolder
  export -f $(<"$(echo "${shotcutfolder}" | sed 's/\.sh/\.entrypoint/')")
done

__parse_command() {
  local input="$1"

  params=""
  options=()

  local args=($input)

  local skip_next=false
  for i in "${!args[@]}"; do
    if $skip_next; then
      skip_next=false
      continue
    fi

    local arg="${args[$i]}"

    if [[ "$arg" == --*=* ]]; then
      options+=("$arg")
    elif [[ "$arg" == -* && "${args[$i+1]}" != -* && "${args[$i+1]}" != "" ]]; then
      options+=("$arg ${args[$i+1]}")
      skip_next=true
    elif [[ "$arg" == -* ]]; then
      options+=("$arg")
    else
      params="$params $arg"
    fi
  done

  params=$(echo "$params" | xargs)
}

__get_flux_events_all__() {
  flux events -A | fzf --info=inline --header-lines=1 --layout=reverse \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') > " \
    --header $'>> Ctrl+r: Reload  <<\n\n' \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:flux events -A'
}

__get_flux_obj_all__(){
  flux get $FLUX_RS -A | fzf --layout=reverse -m --header-lines=1 --info=inline \
    --prompt "[ $FLUX_RS ] CL: $(kubectl config current-context | sed 's/-context$//')  >" \
    --header $"${HEADER}" \
    --preview-window 'bottom,30%' \
    --bind 'ctrl-/:change-preview-window(99%|70%|30%|0|50%)' \
    --bind 'enter:accept' \
    --bind "ctrl-r:reload:flux get $FLUX_RS -A" \
    --bind "ctrl-x:reload:flux get $FLUX_RS -A --status-selector=ready=false" \
    --bind "ctrl-z:reload:flux get $FLUX_RS -A --status-selector=ready=true" \
    "${PARAMS[@]}" \
    --preview "flux events --for $EVENTS_FOR/{2} -n {1}"
}

__flux_logs__(){
  kubectl api-resources | grep flux | sed -E 's/^.*\s([A-Z]?.*$)/\1/' | fzf --info=inline --layout=reverse --header-lines=0 \
   --prompt "CL: $(kubectl config current-context | sed 's/-context$//') > " \
   --header $'>> CTRL-L (open log in editor) || CTRL-/ (change view) || Ctrl-Alt-e (log level ERROR) || Ctrl-Alt-d (log level DEBUG) || Ctrl-Alt-r (log level INFO) <<\n\n' \
   --bind 'ctrl-/:change-preview-window(50%|80%)' \
   --bind 'ctrl-l:execute:${EDITOR:-vim} <(flux logs --kind={1} -A) > /dev/tty' \
   --bind 'ctrl-alt-r:preview:flux logs -f --kind={1} --since=1h -A' \
   --bind 'ctrl-alt-e:preview:flux logs -f --kind={1} --since=1h -A --level=error' \
   --bind 'ctrl-alt-d:preview:flux logs -f --kind={1} --since=1h -A --level=debug' \
   --preview-window up:follow,80%,wrap \
   --preview 'flux logs -f --kind={1} --since=1h -A'
}

__init_obj__() {
  export FLUX_RS="$1"
  export EVENTS_FOR=$(detect_export_kind "$(kubectl api-resources | grep flux)" "$FLUX_RS" | sed -E 's/^.*\s([A-Z]?.*$)/\1/')
  export EXPORT_KIND=$(detect_export_kind "$(curl https://fluxcd.io/flux/cmd/flux/ 2>&1 | grep -oP '<span>flux export .*?</span>' |  sed 's/<\/\?span>//g' | sed 's/flux\sexport//' | grep -v "all")" "$FLUX_RS")
  export FLUX_SR_TYPE=$(detect_export_kind "$(curl https://fluxcd.io/flux/cmd/flux/ 2>&1 | grep -oP '<span>flux suspend .*?</span>' |  sed 's/<\/\?span>//g' | sed 's/flux\ssuspend//' | grep -v "all")" "$FLUX_RS")
  source "$FLUXI_PATH"/fxi/default/config
  if [[ -f "$FLUXI_PATH"/fxi/"$(echo ${FLUX_RS} | sed -E 's/\s/_/')"/config ]]; then
    source "$FLUXI_PATH"/fxi/"$(echo ${FLUX_RS} | sed -E 's/\s/_/')"/config
  fi
}
__obj_diff__() {
  if [[ "$2" == "full" ]]; then
    mode="^$"
  else
    mode="^[[:space:]]*[^|>]*$"
  fi
  local_kustomization=$(kustomize build $(dirname ${1}) | awk 'NR==1 && $0!="---" {print "---"} {print}')
  target=$(echo "${local_kustomization}" | head -10 | grep -E 'kind:|name:|namespace:' | cut -d ':' -f 2 | tr '[:upper:]' '[:lower:]')
  type=$(echo $target | awk '{print $1}')
  if [[ "$type" == "helmrelease" || "$type" == "kustomization" ]]; then
    colordiff -y <(printf "%s\n" "${local_kustomization}") <(printf "%s\n" "$(flux export $(echo $target | awk '{print $1}') $(echo $target | awk '{print $2}') -n $(echo $target | awk '{print $3}'))")  | grep -v $mode | less -R
  else
    cat << EOF
▗▄▄▄▖▗▖ ▗▖▗▄▄▄▖ ▗▄▄▖     ▗▄▖  ▗▄▄▖▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖                                                         
  █  ▐▌ ▐▌  █  ▐▌       ▐▌ ▐▌▐▌     █    █  ▐▌ ▐▌▐▛▚▖▐▌                                                         
  █  ▐▛▀▜▌  █   ▝▀▚▖    ▐▛▀▜▌▐▌     █    █  ▐▌ ▐▌▐▌ ▝▜▌                                                         
  █  ▐▌ ▐▌▗▄█▄▖▗▄▄▞▘    ▐▌ ▐▌▝▚▄▄▖  █  ▗▄█▄▖▝▚▄▞▘▐▌  ▐▌                                                         
                                                                                                                
                                                                                                                
                                                                                                                
▗▄▄▄▖ ▗▄▄▖    ▗▖  ▗▖ ▗▄▖▗▄▄▄▖    ▗▖  ▗▖ ▗▄▖ ▗▖   ▗▄▄▄▖▗▄▄▄                                                      
  █  ▐▌       ▐▛▚▖▐▌▐▌ ▐▌ █      ▐▌  ▐▌▐▌ ▐▌▐▌     █  ▐▌  █                                                     
  █   ▝▀▚▖    ▐▌ ▝▜▌▐▌ ▐▌ █      ▐▌  ▐▌▐▛▀▜▌▐▌     █  ▐▌  █                                                     
▗▄█▄▖▗▄▄▞▘    ▐▌  ▐▌▝▚▄▞▘ █       ▝▚▞▘ ▐▌ ▐▌▐▙▄▄▖▗▄█▄▖▐▙▄▄▀                                                     
                                                                                                                
                                                                                                                
                                                                                                                
▗▄▄▄▖ ▗▄▖ ▗▄▄▖     ▗▄▄▄▖▗▖ ▗▖▗▄▄▄▖ ▗▄▄▖    ▗▄▄▄▖▗▖  ▗▖▗▄▄▖ ▗▄▄▄▖     ▗▄▖ ▗▄▄▄▖     ▗▄▖ ▗▄▄▖    ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌      █  ▐▌ ▐▌  █  ▐▌         █   ▝▚▞▘ ▐▌ ▐▌▐▌       ▐▌ ▐▌▐▌       ▐▌ ▐▌▐▌ ▐▌   ▐▌▐▌   ▐▌     █  
▐▛▀▀▘▐▌ ▐▌▐▛▀▚▖      █  ▐▛▀▜▌  █   ▝▀▚▖      █    ▐▌  ▐▛▀▘ ▐▛▀▀▘    ▐▌ ▐▌▐▛▀▀▘    ▐▌ ▐▌▐▛▀▚▖   ▐▌▐▛▀▀▘▐▌     █  
▐▌   ▝▚▄▞▘▐▌ ▐▌      █  ▐▌ ▐▌▗▄█▄▖▗▄▄▞▘      █    ▐▌  ▐▌   ▐▙▄▄▖    ▝▚▄▞▘▐▌       ▝▚▄▞▘▐▙▄▞▘▗▄▄▞▘▐▙▄▄▖▝▚▄▄▖  █  
                                                                                                                
EOF
  fi
}
__obj_diff_explorer__() {
  find ${HOME} -name "kustomization.y?ml" | fzf --info=inline \
  --layout=reverse \
  --header-lines=0 \
  --header '==========================================================================================================
[F3]Full diff
=========================================================================================================='\
  --border=double \
  --bind "f3:execute:__obj_diff__ {1} 'full'" \
  --preview-window up:follow,70%,wrap \
  --border-label="╢ Add file to diff ╟" --preview "__obj_diff__ {1} 'brief'"
}

export -f __obj_diff__

fluxi() {
  __parse_command "$(echo "$@")"
  case "$params" in
    "get alert-providers" )
      __init_obj__ "alert-providers"
      __get_flux_obj_all__ ;;
    "get alerts" )
      __init_obj__ "alerts"
      __get_flux_obj_all__ ;;
    "get images policy" )
      __init_obj__ "images policy"
      __get_flux_obj_all__ ;;
    "get images repository" )
      __init_obj__ "images repository"
      __get_flux_obj_all__ ;;
    "get images update" )
      __init_obj__ "images update"
      __get_flux_obj_all__ ;;
    "get receivers" )
      __init_obj__ "receivers"
      __get_flux_obj_all__ ;;
    "get sources bucket" )
      __init_obj__ "sources bucket"
      __get_flux_obj_all__ ;;
    "get sources chart" )
      __init_obj__ "sources chart"
      __get_flux_obj_all__ ;;
    "get sources git" )
      __init_obj__ "sources git"
      __get_flux_obj_all__ ;;
    "get sources helm" )
      __init_obj__ "sources helm"
      __get_flux_obj_all__ ;;
    "get sources oci" )
      __init_obj__ "sources oci"
      __get_flux_obj_all__ ;;
    "get kustomizations" )
      __init_obj__ "kustomizations"
      __get_flux_obj_all__ ;;
    "get helmreleases" )
      __init_obj__ "helmreleases"
      __get_flux_obj_all__ ;;
    "get" )
      __init_obj__ "$(curl https://fluxcd.io/flux/cmd/flux/ 2>&1 | grep -oP '<span>flux get .*?</span>' |  sed 's/<\/\?span>//g' | sed 's/flux\sget//' | grep -v "all" | fzf)"
      __get_flux_obj_all__ ;;
    "events" ) __get_flux_events_all__;;
    "event" ) __get_flux_events_all__;;
    "logs" ) __flux_logs__;;
    "log" ) __flux_logs__;;
    "compare" ) __obj_diff_explorer__;;
    *) flux $cmd;;
  esac
}
