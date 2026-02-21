## Download Maven Binary

Current versoin: [link](https://maven.apache.org/download.cgi), Choose - Binary zip archive

Download and put in any folder(Prefer root folder to avoid frequent change by mistakes)

Move to a standard location:
```sh
sudo mv apache-maven-3.9.12 /opt/maven
```

### Set Environment Variables

For macOS (zsh default):

```sh
nano ~/.zshrc
```

Add:
```sh
export MAVEN_HOME=/opt/maven
export PATH=$MAVEN_HOME/bin:$PATH
```

Apply changes:
```sh
source ~/.zshrc
```

## Verify
```sh
mvn -version
```


## Download Maven Daemon(Optional for faster development)
Download(for your OS from [same link](https://maven.apache.org/download.cgi) ) and put in any folder(Prefer root folder to avoid frequent change by mistakes)

Move to a standard location:
```sh
sudo mv maven-mvnd-1.0.0-darwin-* /opt/mvnd
```

Add to PATH:
```sh
nano ~/.zshrc
```

Add:
```sh
export MVND_HOME=/opt/mvnd
export PATH=$MVND_HOME/bin:$PATH
```

Apply changes:
```sh
source ~/.zshrc
```

#### Test mvnd

Go to a Maven project:
```sh
cd your-project
mvnd clean install
```


[Official docs](https://maven.apache.org/install.html)


SDKMAN (Best for Developers)
