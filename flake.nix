{
	description = "control Discord rich presence statuses from the command line";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }:
	let
		systems = [
			"x86_64-linux"
			"aarch64-linux"
		];
		forAllSystems = fn:
			nixpkgs.lib.genAttrs systems (system:
				fn (import nixpkgs {
					inherit system;
				})
			);
	in
	{
		packages = forAllSystems (pkgs: {
			default = pkgs.stdenv.mkDerivation {
				name = "discord-rpcli";
				src = ./.;
				buildInputs = with pkgs; [
					discord-rpc
					xdg-utils
				];
				nativeBuildInputs = with pkgs; [
					bmake
					ldc
					makeBinaryWrapper
				];

				buildPhase = ''
					bmake
				'';
				installPhase = ''
					mkdir -p $out/bin
					bmake DESTDIR="$out" PREFIX=/ install
					wrapProgram $out/bin/discord-rpcli \
						--prefix PATH : ${nixpkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \
						--prefix LD_LIBRARY_PATH : \
							${nixpkgs.lib.makeLibraryPath [ pkgs.discord-rpc ]}
				'';
			};
		});
	};
}
