{
  allowUnfree = true;
  packageOverrides = pkgs: with pkgs; {
    my= pkgs.buildEnv {
      name = "my";
      paths = [
        alacritty
        bat
        bc
        btop
        cloc
        coreutils
        curlie
        direnv
        exa
        fd
        fzf
        git
        gnupg
        go
        htop
        iterm2
        jq
        lsd
        lsof
        meld
        ncmpc
        neofetch
        nmap
        nodejs-18_x
        pv
        ranger
        readline
        ripgrep
        rsync
        scrcpy
        shellcheck
        tig
        tmux
        tree
        vagrant
        vim
        vscode
        watch
        wget
        yarn
        yq
        yt-dlp
      ];
    };
  };
}
