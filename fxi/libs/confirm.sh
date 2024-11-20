#
# confirm(action,resource)
#
fluxi_confirm_dialog()
{
  [[ "$(echo -e "No\nYes ${1} the ${2}" | fzf --border=double --border-label="╢ Confirmation ╟" --margin 25% --prompt 'Are you sure? ')" == Yes* ]]
}
