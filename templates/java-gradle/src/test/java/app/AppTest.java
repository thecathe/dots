package app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class AppTest {
    @Test
    void greetsByName() {
        assertEquals("Hello, nix!", App.greet("nix"));
    }
}
