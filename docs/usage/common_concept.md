# Common Concept

## Parser

Parser is a command that collects the source file of codegen by "Pure String".
It via a root `Pipeline` has context, aka `Ctx`, `Pointer`, `Instructions`, `Config` and `Pipeline`.
It runs a `.oppl` file, shorten for `Pipeline`.
The parser has a strong feature that is to understand a language by `Config`.

### Ctx

It stores the parser's memory.
It also stores when error does it ran into.
The source code is remembered right here.

### Pointer

It is a index to tell the `Parser` where it it at.
`Parser` will go forward and check strings or chars by `Instructions`.

### Instructions

It has many name when written in `.oppl`, but they all named `Instructions` in the `.oppl` file.
It tells the `Parser` what to check, what is ok, what is not, where to go, and where to jump to.

### Config

It tells the parser, what is a comment, what is a string literature.
Or leave it blank or dont use it when natural language or something funky.

### Pipeline

It is the ultimate container of a `Parser Command`.
The command will run in a root `Pipeline`,
that has its own `Ctx`, `Pointer`, `Instructions`, `Config`.
However `pipeline` can have `subpipline`.
