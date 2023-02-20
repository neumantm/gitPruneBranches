{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.default = with pkgs; stdenv.mkDerivation {
        name = "gitPruneBranches";
        src = self;
        buildInputs = [ bash git ];
        nativeBuildInputs = [ makeWrapper ];
        installPhase = ''
          mkdir -p $out/bin
          cp gitPruneBranches.sh $out/bin/git-pruneBranches
          chmod +x $out/bin/git-pruneBranches
          wrapProgram $out/bin/git-pruneBranches \
            --prefix PATH : ${lib.makeBinPath [ bash git ]}
        '';
        meta.mainProgram = "git-pruneBranches";
      };
    }
  );
}
