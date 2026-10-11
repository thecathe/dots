from my_project import greet


def test_greet() -> None:
    assert greet("nix") == "Hello, nix!"
