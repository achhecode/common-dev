# Github Common Commands

### Temporarily exclude large files (≥100MB) using find and git add

```bash
find . -type f -size -100M -exec git add {} +
```

### Dynamically add large files to .git/info/exclude

```bash
find . -type f -size +100M >> .git/info/exclude
```

### Remove existing origin

```bash
git remote remove origin
```

### Remove added file

```bash
git reset
git reset path/to/file #specific
```

### Git Large File Support

```bash
git lfs install
git lfs track "*.psd"
```

### To remove files from Git entirely (if already committed or tracked):

```bash
git rm --cached path/to/file
git commit -m "Remove file from Git tracking"
```
