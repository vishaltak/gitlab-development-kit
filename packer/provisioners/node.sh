#!/bin/bash

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

# load nvm
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

for file in ~/.bash_profile ~/.bashrc ~/.zshrc ~/.zprofile; do
  echo 'autoload -Uz compinit' >> $file
  echo 'compinit' >> $file
  echo 'export NVM_DIR="$HOME/.nvm"' >> $file
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> $file
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> $file
done

nvm install 12.18.3
