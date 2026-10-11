# my-project

## Setup

```
direnv allow .
```

This gives your shell a JDK (`javac`, `java`) and `jdtls`.

## Build and run

```
javac -d out src/*.java
java -cp out Main
```

`out/` is ignored by git. Source files in `src/` can be in packages as usual;
`javac -d out` mirrors the package layout under `out/`.

## Need a build tool?

The `java-gradle` template adds Gradle and a JUnit 5 test setup:

```
nix flake init -t github:thecathe/dots#java-gradle
```
