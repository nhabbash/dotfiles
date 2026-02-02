# Kubernetes tools configuration
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    kubectx
    k9s
  ];
}
