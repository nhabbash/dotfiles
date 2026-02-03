{
  description = "Nassim's dotfiles - nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
    let
      username = "nassim";

      mkDarwinConfig = { hostname, system ? "aarch64-darwin", isWork ? false }: darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username hostname isWork; };
        modules = [
          ./hosts/common.nix
          (./hosts + "/${hostname}.nix")
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit username hostname isWork; enableGui = true; };
              users.${username} = import ./modules/home;
            };
          }
        ];
      };

      mkHomeConfig = { hostname, system ? "x86_64-linux", enableGui ? false }:
        let pkgs = nixpkgs.legacyPackages.${system};
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit username hostname enableGui; isWork = false; };
          modules = [
            ./modules/home
            {
              home = {
                inherit username;
                homeDirectory = "/home/${username}";
                stateVersion = "24.05";
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        "personal-macbook" = mkDarwinConfig {
          hostname = "personal-macbook";
          isWork = false;
        };
        "work-macbook" = mkDarwinConfig {
          hostname = "work-macbook";
          isWork = true;
        };
        "personal-macbook-intel" = mkDarwinConfig {
          hostname = "personal-macbook";
          system = "x86_64-darwin";
          isWork = false;
        };
      };

      homeConfigurations = {
        "linux-server" = mkHomeConfig {
          hostname = "linux-server";
          system = "x86_64-linux";
          enableGui = false;
        };
        "linux-desktop" = mkHomeConfig {
          hostname = "linux-desktop";
          system = "x86_64-linux";
          enableGui = true;
        };
      };

      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ nixfmt-classic ];
          };
        }
      );
    };
}
