### Set Your Global Username and Email (first time git user)

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### ✅ 1. Generate SSH Keys for Both Accounts

#### 🧑 Personal Account

```bash
ssh-keygen -t ed25519 -C "your_personal_email@example.com"
# Save as: C:\Users\YourName\.ssh\id_ed25519_personal
```

#### 💼 Work Account

```bash
ssh-keygen -t ed25519 -C "your_work_email@company.com"
# Save as: C:\Users\YourName\.ssh\id_ed25519_work
```


### ✅ 2. Add SSH Keys to `ssh-agent`


Start the agent(Git Bash) and add both keys:

```bash
eval `ssh-agent -s`

ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
```

On Powershell(require administrator priviledge)

```bash
ssh-add C:/Users/YourName/.ssh/id_ed25519_personal
ssh-add C:/Users/YourName/.ssh/id_ed25519_work
```


## 🧪 Verify It Works

```bash
ssh-add -l
```

## 💡 Optional: Automate Agent Start in Git Bash

If you always use Git Bash, add this to the end of your `~/.bashrc` (or `~/.bash_profile` if you're using that instead):

```bash
# Start ssh-agent if not already running
eval "$(ssh-agent -s)" > /dev/null
```


### ✅ 3. Add Public Keys to GitHub Accounts

Go to each GitHub account:

- Profile → Settings → **SSH and GPG Keys**
- Click **"New SSH Key"** and paste contents of:

```bash
cat ~/.ssh/id_ed25519_personal.pub
cat ~/.ssh/id_ed25519_work.pub
```

For Windows use below command in powershell:

```sh
gc ~/.ssh/id_ed25519_work.pub # or the exact path of the file
```


### ✅ 4. Configure SSH `config` File

Edit (or create) `~/.ssh/config`:

```bash
# Personal Account
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

# Work Account
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```



### ✅ 5. Clone Repos with Custom Hosts

##### If repository already exists

- **Personal:**
```bash
git clone git@github-personal:yourusername/repo.git
```

- **Work:**
```bash
git clone git@github-work:yourworkusername/repo.git
```


##### If creating new repository

```bash
git init

git add .
git commit -m "Initial commit"


git remote add origin git@github-personal:yourusername/my-new-project.git

git push -u origin main  # or master, depending on your branch

```

Same for Work Account Just change the remote to:

```bash
git remote add origin git@github-work:yourworkusername/work-repo.git
```

### ✅ 6. Set Git User Per Repository

Navigate into your cloned repo:

```bash
cd repo/
git config user.name "Your Personal Name"
git config user.email "your_personal_email@example.com"
```

For work repo:

```bash
cd work-repo/
git config user.name "Your Work Name"
git config user.email "your_work_email@company.com"
```


### ✅ 7. Verify

Inside a repo:

```bash
git remote -v
git config user.name
git config user.email
```

Push test commits to confirm correct identity is used.


### Test SSH connection manually

```bash
ssh -T git@github-personal
# You should see something like:
## Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```
---


### Quick summary to add new git profile and push changes

### Setting up new key

```bash

ssh-keygen -t ed25519 -C "danish.ar@test.com"

# Enter file in which to save the key (C:\Users\danish.ar/.ssh/id_ed25519): C:\Users\danish.ar\.ssh\id_ed25519_feuji

ssh-add ~/.ssh/id_ed25519_feuji

nano ~/.ssh/config

# Feuji Account
Host github-feuji
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_feuji

```
### Pushing to branch

```bash
git config user.name "A R Danish"
git config user.email "danish.ar@test.com"
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github-feuji:SunStripe-Feuji/sun-stripe-feoc.git
git push -u origin main


#optional
#verify remote
git remote -v
# setting alias if not showing Host like git@github-personal and showing github.com
git remote set-url origin git@github-personal:USERNAME/REPO.git

```

---
---
---


#### If facing issues while testing ssh connection
```sh
ssh -T git@github-personal
ssh: connect to host github.com port 22: Operation timed out
```
This timeout means your system isn’t even reaching GitHub over SSH port 22 — so this isn’t about the wrong key, it’s a connectivity problem. Happens a lot on corporate networks, VPNs, or ISPs that block port 22.

#### Option 1: Use SSH over HTTPS (port 443)

Update `~/.ssh/config`:

```ssh
Host github-1
    HostName ssh.github.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_ed25519_1
    IdentitiesOnly yes

Host github-2
    HostName ssh.github.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_ed25519_2
    IdentitiesOnly yes
```


#### Option 2: Use HTTPS remotes instead of SSH
If SSH is blocked in environment and you can’t change it, switch your remote to HTTPS:
```sh
git remote set-url origin https://github.com/USERNAME/REPO.git
```


⚡ Quick test:
Run:
```sh
nc -vz ssh.github.com 443
```
If it says `Connection to ssh.github.com port 443 [tcp/https] succeeded!`, then Option 1 will work for you.


### Happy Coding
## Achhe Code
