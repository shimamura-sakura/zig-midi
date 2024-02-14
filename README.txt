zig-midi
--------
a library for reading MIDI file (from a memory region) in zig

usage
-----
const midi = @import("midi.zig");
read main.zig and midi.zig for usage
this library only reads number from the file (cmd, arg1, arg2, etc.)
you need to extract things like command and channel from 'kind' by yourself.
meta event kind is in 'arg1'
data for meta and sysex event are in 'size' and 'data'

example
-------
main.zig is a note counter that counts note on and offs.
(note that it runs for 200 times)