# List Installed Java Versions


```sh
/usr/libexec/java_home -V
```

## Set Java Version Temporarily (Current Terminal Only)

Switch to Java 17:

```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

Switch to Java 21:

```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH
```

## Verify
```sh
java -version
echo $JAVA_HOME
```


## Set Default Java Version Permanently

### Edit your shell profile(check zsh or bashrc).
```sh
nano ~/.zshrc
```
Add:
```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH
```
Apply changes:
```sh
source ~/.zshrc
```

## Create Quick Switch Aliases (Optional)


Add this to `~/.zshrc`:
```sh
alias j17='export JAVA_HOME=$(/usr/libexec/java_home -v 17)'
alias j21='export JAVA_HOME=$(/usr/libexec/java_home -v 21)'
```

Then run:
```sh
j21
java -version
```


# For GUI prefer [SDKMAN](https://sdkman.io/)
