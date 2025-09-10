### Use nvm (Node Version Manager – for Linux/macOS)

Install nvm [link](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating):
```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash



# Success response
=> If you wish to uninstall them at a later point (or re-install them under your
=> `nvm` node installs), you can remove them from the system Node as follows:

     $ nvm use system
     $ npm uninstall -g a_module

=> Close and reopen your terminal to start using nvm or run the following to use it now:

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


=> OR
To restart your shell or source your profile:
source ~/.bashrc   # or ~/.zshrc
```


Usage:
```sh
nvm install 18     # install Node.js v18
nvm install 20     # install Node.js v20

nvm use 18         # switch to v18
nvm use 20         # switch to v20

nvm alias default 20   # always use v20 by default
nvm alias dev 18       # create a custom alias
nvm use dev            # switch to alias
```




