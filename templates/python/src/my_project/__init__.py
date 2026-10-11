def greet(name: str = "world") -> str:
    return f"Hello, {name}!"


# Delete-me smoke test (mirrors templates/haskell's app/Main.hs): confirms
# the interpreter, uv and the installed entry point all resolve.
def main() -> None:
    print(greet())
