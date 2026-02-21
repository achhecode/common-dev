## Verify Your JDK Installation
#``````

```sh
/usr/libexec/java_home

#check version
java -version
```

## Set JAVA_HOME Temporarily (Current Session Only)

```sh
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH
```

## Set JAVA_HOME Permanently

## Check your shell

```sh
echo $SHELL
```

- If you see `/bin/zsh` → edit `~/.zshrc`

- If you see `/bin/bash` → edit `~/.bash_profile or ~/.bashrc`

### Add JAVA_HOME to your profile file

```sh
nano ~/.zshrc
```

#### Add this line

```sh
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH
```

#### Apply changes
```sh
source ~/.zshrc
```

#### Verify it's set
```sh
echo $JAVA_HOME
```
