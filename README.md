# Pinesweeper

A simple terminal minesweeper in [Free Pascal](https://www.freepascal.org/), but with **pines 🌲**.

## Quickstart

Build it (you'll need `fpc`):

```console
$ ./build.sh
```

And run it:

```console
$ ./bin/pinesweeper
```

## Playing

- The game is based on a field filled with closed cells which can be empty or contain pines.

- When an empty cell is opened it'll show the number of bombs around that cell (including the corners).

- The game's won when all empty cells are opened and lost when a pine cell is opened.

- Cells can be flagged to indicate the presence of a pine.

### Controls

- `hkjl` to move the cursor through the field.
- `!` to flag a cell.
- `[spacebar]` to open a cell.
