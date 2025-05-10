# Citronic Autocue
Disassembly and rewrite of Citronic Autocue as fitted to the 'Micro' range of Citronic disco consoles (Tamar, Isis and Thames-II), late 1980s to early 1990s.

## Build steps

1. Install cc65 from https://cc65.github.io/

2. Get the code from here

3. Compile using `make`, which should give you `autocue.bin`:

```
    % make
    ca65 -U -o autocue.o -l autocue.lst autocue.s
    ld65 -o autocue.bin -t none autocue.o
    %
```

## Checking Build

The md5 will be `e7d3017812a0e49411d76f40937de220` if it's identical to the original fitted V2.19AN ROM.

```
    % md5sum autocue.bin
    e7d3017812a0e49411d76f40937de220  autocue.bin
    %
```
This can then be burned to a 2716 EPROM to use in the Autocue unit.

## More information

More information, hardware notes, etc. at [Jessica's Project Page](https://jessicat.uk/autocue).
