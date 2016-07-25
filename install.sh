#!/bin/bash

curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

files=( .vimrc .neovimrc .zshrc .gitconfig .gitignore_global .gemrc .alias )

for filename in ${files[@]}
do
  [[ -s $HOME/$filename ]] && rm $HOME/$filename
  ln -s $PWD/$filename ~/$filename
done

dirs=( .vim .nvim )

for dir in ${dirs[@]}
do
  [[ -s $HOME/$dir ]] && rm -rf $HOME/$dir
  ln -s $PWD/$dir ~/$dir
done

mkdir -p ${XDG_CONFIG_HOME:=$HOME/.config}
ln -s ~/.neovimrc $XDG_CONFIG_HOME/nvim/init.vim

source ~/.zshrc
