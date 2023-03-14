# gitPruneBranches

A script to prune local git branches that are no longer needed

## Requirements

- git
- bash

## Installation

There are multiple possibilities to install this.

### Standalone script

Just download the script `gitPruneBranches.sh` from this repo, make it executable and use it:

```bash
./gitPruneBranches.sh
# or
../path/to/gitPruneBranches.sh
# or
/path/to/gitPruneBranches.sh
# or
```

You may also put it into your `PATH`, allowing to just execute it with `gitPruneBranches.sh`.

### Git Extension

You can also rename the script to `git-pruneBranches` and put it into your `PATH`.
Then you can run it with `git pruneBranches`.

### Nix Flake

This repo is also a [nix flake](https://nixos.wiki/wiki/Flakes) and thus can be installed with e.g.

```bash
nix shell github:neumantm/gitPruneBranches
```

Then you can use it with `git pruneBranches`.

When include it in another flake (e.g. your nixos configuration) it is advisable to reuse the nixpkgs flake you are already using:

```nix
{
  inputs.nixpkgs.url = "...";
  inputs.gitPruneBranches.url = "github:neumantm/gitPruneBranches";
  inputs.gitPruneBranches.inputs.nixpkgs.follows = "nixpkgs";
  ...
}
```
