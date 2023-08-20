{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
	buildInputs = with pkgs.buildPackages; [
		discord-rpc
		xdg-utils
	];
	nativeBuildInputs = with pkgs.buildPackages; [
		bmake
		ldc
	];
	shellHook = "alias make=bmake";
}
