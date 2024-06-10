## fix channel (if missing)
# nix-channel --list
# nix-channel --add https://nixos.org/channels/nixpkgs-unstable
# nix-channel --list
# nix-channel --update
#
# to install all: `nix-env -iA nixpkgs.my`
# to upgrade all: `nix-env -u`
# to clean others: `nix-collect-garbage -d`
# to clean old generations: `nix-env --delete-generations old`
{
  allowUnfree = true;
  permittedInsecurePackages = [
    "libressl-3.4.3"
  ];
  packageOverrides = pkgs: with pkgs; {
    my= pkgs.buildEnv {
      name = "my";
      paths = [
        alacritty
        awscli
        bash
        bat
        bc
        btop
        bzip2
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
        kubernetes-helm
        htop
        inetutils
        iterm2
        jless
        jq
        kondo
        kubectl
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
        numbat
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
