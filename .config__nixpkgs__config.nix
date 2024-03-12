# to install all: `nix-env -iA nixpkgs.my`
# to upgrade all: `nix-env -u`
# to clean others: `nix-env -iA nixpkgs.my && nix-collect-garbage`
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
        atuin
        bash
        bat
        bc
        btop
        bzip2
        cloc
        colima
        coreutils
        curl
        curlie
        delta
        diffutils
        direnv
        dnsutils
        eza
        fd
        findutils
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
