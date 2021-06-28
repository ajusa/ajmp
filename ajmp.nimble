# Package

version       = "0.1.0"
author        = "ajusa"
description   = "A simple command line music player"
license       = "MIT"
srcDir        = "src"
bin           = @["ajmp"]


# Dependencies

requires "nim >= 1.4.4"
requires "nimbass"
requires "cligen"
requires "notify"
