files=( .vimrc .zsh .gitconfig .gitignore_global .gemrc)

for filename in ${files[@]}
do
  [[ -s $HOME/.$filename ]] && rm $HOME/.$filename
  ln -s $PWD/.$filename ~/.$filename
done

source ~/.zshrc
