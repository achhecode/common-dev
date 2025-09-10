## Node issues
```sh
> npm install


npm error code EACCES
npm error syscall mkdir
npm error path /Users/<whoami>/Documents/Projects/CDE/UI/test/node_modules/vite/node_modules/@esbuild/aix-ppc64
npm error errno -13
npm error [Error: EACCES: permission denied, mkdir '/Users/<whoami>/Documents/Projects/CDE/UI/test/node_modules/vite/node_modules/@esbuild/aix-ppc64'] {
npm error   errno: -13,
npm error   code: 'EACCES',
npm error   syscall: 'mkdir',
npm error   path: '/Users/<whoami>/Documents/Projects/CDE/UI/test/node_modules/vite/node_modules/@esbuild/aix-ppc64'
npm error }
npm error
npm error The operation was rejected by your operating system.
npm error It is likely you do not have the permissions to access this file as the current user
npm error
npm error If you believe this might be a permissions issue, please double-check the
npm error permissions of the file and its containing directories, or try running
npm error the command again as root/Administrator.
npm error A complete log of this run can be found in: /Users/<whoami>/.npm/_logs/2025-09-10T15_49_24_907Z-debug-0.log
```

### Fix

🔧 Step 1: Clean up node_modules and lock files
```sh
rm -rf node_modules package-lock.json
npm cache clean --force
```

Then try again:
```sh
npm install
```
🔧 Step 2: Fix permissions in your project

Run this from the root of your project:
```sh
sudo chown -R $(whoami) .
```

This gives your current user ownership of all files/folders in the project.
```sh
🔧 Step 3: Fix global npm directory (if needed)
```
Sometimes npm is using a global folder that needs sudo. You can reconfigure npm to use a user-local directory:
```sh
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
```

Then add this to your shell profile (~/.zshrc or ~/.bashrc):
```sh
export PATH=$HOME/.npm-global/bin:$PATH
```

Reload your shell:
```sh
source ~/.zshrc   # or ~/.bashrc
```
🔧 Step 4: Use a Node version manager (recommended)

Instead of fixing permissions every time, install nvm (Node Version Manager) and install Node locally:
```sh
brew install nvm   # if on macOS
```

Then:
```sh
nvm install --lts
nvm use --lts
```

Now, all npm install runs will be under your user account, no sudo needed.

The fastest fix is likely:
```sh
rm -rf node_modules package-lock.json
sudo rm -rf node_modules package-lock.json (optional)
sudo chown -R $(whoami) .
npm install
```


### Happy Coding,
## Achhe Code
