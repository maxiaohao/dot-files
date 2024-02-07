# to install all: `nix-env -iA nixpkgs.my`
# to upgrade all: `nix-env -u`
# to clean others: `nix-collect-garbage`
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
        bat
        bc
        btop
        cloc
        colima
        coreutils
        curlie
        delta
        diffutils
        direnv
        dnsutils
        exa
        fd
        findutils
        fzf
        gawk
        git
        gnupg
        gnused
        gnutar
        go
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
        nmap
        nodejs-18_x
        openssh
        procps
        pv
        pwgen
        ranger
        rar
        readline
        ripgrep
        rsync
        scrcpy
        shellcheck
        stern
        tig
        tmux
        tree
        unzip
        util-linux
        vagrant
        vim
        vscode
        watch
        wget
        xz
        yarn
        yq
        yt-dlp
        zip
      ];
    };
  };
}
