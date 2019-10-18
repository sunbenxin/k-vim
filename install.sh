#!/bin/bash
# ubuntu
#sudo apt-get install -y  ctags build-essential cmake python-dev nodejs  && pip install pyflakes && pip install pylint && pip install pep8 && npm install -g jslint && npm install jshint -g

# refer  spf13-vim bootstrap.sh`
BASEDIR=$(dirname $0)
cd $BASEDIR
CURRENT_DIR=`pwd`

# parse arguments
function show_help
{
    echo "install.sh [option]
    --for-vim       Install configuration files for vim, default option
    --for-neovim    Install configuration files for neovim
    --for-all       Install configuration files for vim & neovim
    --help          Show help messages
For example:
    install.sh --for-vim
    install.sh --help"
}
FOR_VIM=true
FOR_NEOVIM=false
if [ "$1" != "" ]; then
    case $1 in
        --for-vim)
            FOR_VIM=true
            FOR_NEOVIM=false
            shift
            ;;
        --for-neovim)
            FOR_NEOVIM=true
            FOR_VIM=false
            shift
            ;;
        --for-all)
            FOR_VIM=true
            FOR_NEOVIM=true
            shift
            ;;
        *)
            show_help
            exit
            ;;
    esac
fi

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
}


FILES=(~/.config/nvim  ~/.config/nvim/init.vim)
echo "Step1: backing up current vim config"
today=`date +%Y%m%d`
if $FOR_VIM; then
    for i in $HOME/.vim $HOME/.vimrc $HOME/.gvimrc $HOME/.vimrc.bundles
    do
        [ -e $i ] && [ ! -L $i ] && mv $i $i.$today
    done

    for i in $HOME/.vim $HOME/.vimrc $HOME/.gvimrc $HOME/.vimrc.bundles
    do
        [ -L $i ] && unlink $i
    done
fi

if $FOR_NEOVIM; then
    for i in "${FILES[@]}"
    do
        [ -e $i ] && [ ! -L $i ] && mv $i $i.$today;
        [ -L $i ] && unlink $i ;
    done
fi

echo "Step2: setting up symlinks"
if $FOR_VIM; then
    lnif $CURRENT_DIR/vimrc $HOME/.vimrc
    lnif $CURRENT_DIR/vimrc.bundles $HOME/.vimrc.bundles
    lnif "$CURRENT_DIR/" "$HOME/.vim"
fi
if $FOR_NEOVIM; then
    lnif "$CURRENT_DIR/" "${FILES[0]}"
    lnif $CURRENT_DIR/vimrc $CURRENT_DIR/init.vim
    lnif $CURRENT_DIR/vimrc.bundles $HOME/.vimrc.bundles
fi

echo "Step3: update/install plugins using Vim-plug"
system_shell=$SHELL
export SHELL="/bin/sh"
if $FOR_VIM; then
    vim -u $HOME/.vimrc.bundles +PlugInstall! +PlugClean! +qall
else
    nvim -u ~/.vimrc.bundles +PlugInstall! +PlugClean! +qall
fi
export SHELL=$system_shell


echo "Step4: compile YouCompleteMe"
echo "It will take a long time, just be patient!"
echo "If error,you need to compile it yourself"
echo "cd $CURRENT_DIR/bundle/YouCompleteMe/ && python install.py --clang-completer"
cd $CURRENT_DIR/bundle/YouCompleteMe/
git submodule update --init --recursive
if [ `which clang` ]   # check system clang
then
    python3 install.py --clang-completer --system-libclang   # use system clang
else
    python3 install.py --clang-completer
fi

echo "Install Done!"
