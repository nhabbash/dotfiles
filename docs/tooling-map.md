# Tooling Map

This repo manages the operational parts of a workstation. These are the main
tools and why they are here.

## Core Layers

- Nix / nix-darwin / home-manager
  Installs packages, apps, links repo config into the home directory, and applies macOS settings

- `scripts/dotfiles.sh`
  Main operational entry point for bootstrap, rebuild, validation, runtime services, and diagnostics

- `configs/`
  Live-editable config content for the tools below

## Windowing And Desktop

- AeroSpace
  Tiling window manager and workspace routing on macOS

- Hammerspoon
  Keyboard-driven automation and the navigation guide overlay

- Übersicht
  Desktop widget host; mainly relevant when `simple-bar` is enabled

## Terminal And Shell

- zsh
  Shared shell aliases, functions, keybindings, and host/profile overrides

- Ghostty
  Main terminal emulator config and shaders

- Zellij
  Terminal workspace/pane/tab management

## Editor And CLI

- Neovim
  Shared editor setup

- Git / gh / jj
  Version control and CLI helpers

- Claude / agents
  Local agent config and statusline behavior

## Generated And Experimental Areas

- `scripts/generated/`
  Generator implementations for derived config

- `scripts/experiments/`
  Mutable or exploratory workflows that should not be confused with baseline machine apply

## Scope Rule

Something belongs here if it is part of your baseline workstation across
multiple unrelated projects. Repo-specific toolchains should stay in those
projects instead.
