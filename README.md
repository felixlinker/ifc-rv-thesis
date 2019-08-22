
# ifc-rv-thesis

This repository holds the master thesis me, Felix Linker, and the code that comes with it.
The thesis is about information flow tracking for instruction set architectures using model checking.
I apply my approach to the RISC-V ISA.
For more details about the idea I direct the reader to `thesis/outline.tex`.

This document will focus on the technical aspect of the thesis.

## Tools used & setup

### nuXmv

I use a model of a simplified RISC-V ISA written in nuXmv.
In order to run the proofs you will need to install nuXmv (cf. https://nuxmv.fbk.eu).

### cpp

nuXmv is a very lightweight language that has very few features to make life of programmers easier.
Therefore I used the C-preprocessor to define macros that make the model more flexible and less redundant at times.
You will need to preprocess the model with `cpp`.

Additionally, the model supports dynamic assumptions and optional extensions.
These can be enabled with sime `#define` statements.
There is no list of all assumptions and options available but in `trace.ps1`, the default value for the `-assumptions` argument *should* give you all available assumptions and looking for `#ifdef` preprocessor-directives in the code will give you all available options and assumptions.

Assumption-macros are used in `#define assumptions` which (as of writing this) can be found in line 610.

### smvtrcviz

When nuXmv finds a property to be false, it generates a counter example.
These counter examples can be given in various forms, one of which is XML.
I wrote a command-line-tool that converts a trace given in XML into an HTML-table that can be looked at more easily.
This tool is completely optional but I found it to be very helpful.
You can find it under https://github.com/felixlinker/smvtrcviz.

## Structure of the repository

File/Folder             | Description
----------------------- | -----------
`README.md`             | You are reading this file
`trace-bmc.template`    | Template file that holds commands for nuXmv to run proofs; words written in `[...]` should be replaced
`trace.ps1`             | PowerShell-script that runs proofs, e.g. invokes `cpp` and handles templating
`model/min-rv.smv`      | The actual model
`model/partial/`        | Other auxiliary proofs and helper files
`thesis/`               | The thesis written in LaTeX
`thesis/sections/`      | Individual sections of the thesis

## Running the proofs

I wrote a runner script for PowerShell.
The syntax isn't too complicated so if you want to come up with a runner script for your platform, e.g. `trace.sh` please take the `.ps1` script as an example.
