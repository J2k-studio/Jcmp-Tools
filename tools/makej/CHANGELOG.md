# Changelog

## 0.2.0
* **Several cores:** `makej -j N` (default: the number of cores that are on) builds N targets at the same time, each as soon as what it needs is done; a failed target stops new ones from starting, the others finish, the exit code is 1.

## 0.1.1
* The build file is read without taking a value out of a `Result` (a compiler before 1.0 freed it twice: the first target could be built with an empty command). Works with jcmp 0.9.206 and later.


## 0.1.0
* The first version: the build file is the file `makej` (a simple TOML: `nano makej`, `makej init`) or `makej.jk` (a J2K program); programs, libraries and steps; a target is built again only when a source is newer than the result. The tool is one file (the library is inside). A prototype: the design is in docs/usage-design.md.

## Unreleased
* `makej init -ai`: an AI project (makej, src/chat.jk, data/data.json; steps train and ask).

## 0.3.0
* list, clean, -n (dry run), install FOLDER, the time of a build, targets named in the error of a wrong name, init -ai.

## 0.3.1
* init -ai makes a small project with the library neuron (train on data/data.csv, ask the model).
