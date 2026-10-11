# my-project

## Setup

```
direnv allow .
```

This gives your shell a JDK, `gradle` and `jdtls`.

## Everyday use

```
gradle run      # build and run app.App
gradle test     # run the JUnit 5 tests
gradle build    # compile, test and package
```

## Notes

- There is no Gradle wrapper (`gradlew`): Nix provides `gradle`, and the
  wrapper's jar is a binary blob better left out of the repo. Run
  `gradle wrapper` if collaborators without Nix need one.
- The JDK major version is set in two places: `jdk` in `flake.nix` and
  `languageVersion` in `build.gradle.kts`. Change them together.
- Dependencies are downloaded from Maven Central on first build, so the
  first `gradle test` needs network access.
