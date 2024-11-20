__prepare_flux_explain__(){
  export FLUX_RS=$1

  EXPLAIN=$(kubectl explain ${FLUX_RS} --recursive | sed -r 's/FIELDS:/---/' | sed -n '\|---|,$p' | sed -r 's/(\w+)\t.*/\1:/g' | yq -o props -P . | sed -r 's/ =//g')

  for line in $EXPLAIN; do
    echo $line
    ST=$line
    for level in $(echo $line | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/' | sed -r 's/\./ /g'); do
      ST=$(echo $ST | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/')
      echo $ST
    done
  done | sort | uniq
}

export -f __prepare_flux_explain__

explain_flux_obj(){
  export FLUX_RS=$1
  __prepare_flux_explain__ $1 | fzf --layout=reverse --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) Ctrl-f (search word) <<\n\n' \
    --preview-window=right:70% \
    --bind 'ctrl-/:change-preview-window(40%|50%|70%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-f:execute:kubectl explain ${FLUX_RS}.{1} | less' \
    --preview 'kubectl explain ${FLUX_RS}.{1}'
}
