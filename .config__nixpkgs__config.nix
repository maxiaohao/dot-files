## fix channel (if missing)
# nix-channel --list
# nix-channel --add https://nixos.org/channels/nixpkgs-unstable
# nix-channel --list
#
## 1) we need to update the channel before doing an upgrade for pkgs
# nix-channel --update
#
## 2) to install all:
# nix-env -iA nixpkgs.my
#
# to upgrade all: `nix-env -u` ## this does NOT actually upgrade (use the install cmd for an upgrade)
# to clean garbage: `nix-collect-garbage -d`
# to clean old gen: `nix-env --delete-generations old`
# - Done
#
# Troubleshooting: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Connection refused
# Try:
# sudo launchctl list | grep org.nixos
# sudo launchctl kickstart -k system/org.nixos.nix-daemon
#
# Fix ssl cert: https://github.com/NixOS/nix/issues/8081#issuecomment-1962419263
#
# Or, manually run the daemon on demand: sudo nix-daemon
{
  allowUnfree = true;
  permittedInsecurePackages = [
    "libressl-3.4.3"
  ];
  packageOverrides = pkgs: with pkgs; {
    my= pkgs.buildEnv {
      name = "my";
      paths = [
        awscli
        bash
        bat
        bc
        btop
        bzip2
        clipcat
        cloc
        colima
        coreutils
        csharp-ls
        curl
        curlie
        delta
        diffutils
        direnv
        dnsutils
        eza
        fd
        findutils
        fish
        flameshot
        fnm
        fzf
        gawk
        git
        glow
        gnugrep
        gnupg
        gnused
        gnutar
        go
        gopls
        gron
        gum
        gzip
        htop
        inetutils
        iterm2
        jless
        jq
        kondo
        kubectl
        kubernetes-helm
        lazygit
        less
        lsd
        lsof
        mediainfo
        meld
        mprocs
        navi
        ncmpc
        neofetch
        neovim
        nmap
        nodePackages.bash-language-server
        notcurses
        openssh
        procps
        pv
        pwgen
        pyenv
        ranger
        rar
        readline
        ripgrep
        rsync
        scrcpy
        shellcheck
        starship
        stern
        tealdeer
        tig
        tmux
        tokei
        tree
        unzip
        util-linux
        vifm
        vim
        vivid
        vscode
        watch
        wget
        xh
        xz
        yarn
        yazi
        yq
        yt-dlp
        zip
        zoxide
        zsh
      ];
    };
  };
}
