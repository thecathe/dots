module Main (main) where

import MyLib (greet)

main :: IO ()
main = putStrLn (greet "world")
