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
        gnugrep
        gnupg
        gnused
        gnutar
        go
        gron
        gzip
        htop
        inetutils
        iterm2
        jq
        kubectl
        less
        lsd
        lsof
        mediainfo
        meld
        ncmpc
        neofetch
        neovim
        nmap
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
        tig
        tmux
        tree
        unzip
        util-linux
        vifm
        vim
        vscode
        watch
        wget
        xz
        yarn
        yq
        yt-dlp
        zip
        zoxide
        zsh
      ];
    };
  };
}
