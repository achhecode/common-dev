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


#### Check the installed Node.js versions on your system using:

```sh
nvm ls

# if none
->       system
iojs -> N/A (default)
node -> stable (-> N/A) (default)
unstable -> N/A (default)
```

#### To see all available versions online (that you can install):
```sh
nvm ls-remote
```

#### Check if nvm is loaded correctly
Run:
```sh
command -v nvm
```


---

##### If any node versions is installed in nvm and not using nvm, remove system-installed Node.js using below command:
```sh
brew uninstall node
brew uninstall --force node
```

Verify removal:
```sh
node -v
npm -v
```

Both should now show command not found (or not exist).

If facing issues with brew and getting below error:
```sh
brew uninstall node
Error: No such keg: /opt/homebrew/Cellar/node
```

#### Find where Node is installed
```sh
which node
```

Also check:
```sh
ls -l $(which node)
```
This may point to a symlink (e.g. into /usr/local/bin/node or /usr/local/lib/node_modules).


#### Remove Node.js manually

Typical locations to check and clean up (depends on how Self Service installed it):
```sh
sudo rm -f /usr/local/bin/node
sudo rm -f /usr/local/bin/npm
sudo rm -f /usr/local/bin/npx
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf /usr/local/include/node
sudo rm -rf /usr/local/share/man/man1/node.1
```

If your which node shows /opt/homebrew/bin/node, remove from there instead:
```sh
sudo rm -f /opt/homebrew/bin/node
sudo rm -f /opt/homebrew/bin/npm
sudo rm -f /opt/homebrew/bin/npx
sudo rm -rf /opt/homebrew/lib/node_modules
```

#### Verify it’s gone
```sh
node -v
npm -v
```
You should now get command not found.


#### Reinstall via nvm

Now install and manage Node with nvm:
```sh
nvm install node #latest
nvm install --lts # recommended for most project
nvm install 18
nvm alias default 18
```
Check:
```sh
node -v
nvm ls
```

After installation, set it as the default so every new terminal uses it:
```sh
nvm alias default node      # for latest
# or
nvm alias default lts/*     # for latest LTS
```

If you want the default to always follow the latest LTS:

nvm alias default lts/*


#### If you want a specific LTS line as default (e.g., Jod / v22):
```sh
nvm alias default 22
# or explicitly
nvm alias default lts/jod
```

If you prefer the cutting-edge stable (v24):
```sh
nvm alias default node
```


### Happy Coding
## Achhe Code
