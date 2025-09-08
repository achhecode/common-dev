![Img](/Media/Images/error-8-09-2025-1.png "Error")
---

1. Fix permissions on the npm cache

Run this command to give your user ownership of the npm cache:
```sh
sudo chown -R $(whoami) ~/.npm
```


2. (Optional) Also fix global npm modules

If you’ve used sudo npm install -g, those might also be root-owned. Run:
```sh
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
```

3. Clear the npm cache (safe)
```sh
npm cache clean --force
```


---

Avoid using sudo npm install ...

Instead, if you need global packages, it’s better to configure npm to install them in your home directory:
```sh
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
```

Then add this to your shell config (~/.bashrc, ~/.zshrc, etc.):
```sh
export PATH=$HOME/.npm-global/bin:$PATH
```

Reload your shell:
```sh
source ~/.zshrc   # or ~/.bashrc
```

Now you can install global npm packages without sudo.
