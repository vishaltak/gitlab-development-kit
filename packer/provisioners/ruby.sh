#!/bin/bash

# rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src

for file in ~/.bash_profile ~/.bashrc ~/.zshrc ~/.zprofile; do
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> $file
  echo 'eval "$(rbenv init -)"' >> $file
done

# load rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# ruby
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 2.6.6
