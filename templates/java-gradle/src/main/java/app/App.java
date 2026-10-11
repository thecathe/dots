package app;

// Delete-me smoke test (mirrors templates/haskell's app/Main.hs): confirms
// Gradle, the JDK and the application plugin line up.
public class App {
    public static String greet(String name) {
        return "Hello, " + name + "!";
    }

    public static void main(String[] args) {
        System.out.println(greet("world"));
    }
}
