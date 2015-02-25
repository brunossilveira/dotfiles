#!/bin/bash

files=( .vimrc .zshrc .gitconfig .gitignore_global .gemrc .alias )

for filename in ${files[@]}
do
  [[ -s $HOME/$filename ]] && rm $HOME/$filename
  ln -s $PWD/$filename ~/$filename
done

dirs=( .vim )

for dir in ${dirs[@]}
do
  [[ -s $HOME/$dir ]] && rm -rf $HOME/$dir
  ln -s $PWD/$dir ~/$dir
done

source ~/.zshrc
