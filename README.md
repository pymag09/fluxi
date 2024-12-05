# fluxi
Simple and light-weight UI for flux.

## Dependencies

* `fzf` (command-line fuzzy finder) - [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf)
* `yq` (portable command-line YAML processor)
* `colordiff` a wrapper for diff and produces the same output as diff but with coloured syntax highlighting at the command line to improve readability

## Installation
fluxi requires you to add two line to your .bashrc file.
* export FLUXI_PATH=<PATH_TO_FLUXI_DIRE>
* source ${FLUXI_PATH}/fluxi.sh
When the lines are in-place, reboot or source the .bashrc (source ~/.bashrc)

## How to use it.
Supported commands:
* fluxi get alert-providers
* fluxi get alerts
* fluxi get images policy
* fluxi get images repository
* fluxi get images update
* fluxi get receivers
* fluxi get sources bucket
* fluxi get sources chart
* fluxi get sources git
* fluxi get sources helm
* fluxi get sources oci
* fluxi get kustomizations
* fluxi get helmreleases
* fluxi get
* fluxi events
* fluxi logs

`fluxi get` + `enter` give you the list of all available commands, sort of command completion but a bit more interactive.
