#!/bin/sh

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

echo 'export LANG=en_US.UTF-8' >> ~/.zshrc
