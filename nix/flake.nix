{
  description = "Nassim's Home Manager configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: nix-darwin for macOS system settings (uncomment if needed)
    # darwin = {
    #   url = "github:lnl7/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Supported systems
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];

      # Helper to generate attrs for each system
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        # macOS (Apple Silicon) - primary config
        "nassim@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            hostname = "macbook";
            isWork = false;
          };
        };

        # macOS (Intel) - if needed
        "nassim@macbook-intel" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-darwin;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            hostname = "macbook-intel";
            isWork = false;
          };
        };

        # Linux config - if you ever use Linux
        "nassim@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            hostname = "linux";
            isWork = false;
          };
        };
      };

      # Development shell for working on these dotfiles
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ home-manager nixfmt-classic ];
          };
        }
      );
    };
}
