This is a new theoretical cipher-encryption method that uses a 3-dimensional matrix of values to encode digital data.  It is best visualized as a unit-cube, where each unit space within the cube contains a number.  For instance, a 4x4x4 cube would have 16 units on a face, 64 units in total, which also means it can contain 64 separate (yet not necessarily unique) numbers. There is no set size or upper limit for how large the cube can be, although practical computational considerations might prove a limiter for exceedingly large sizes.

Encoding happens by XORing the input data byte-by-byte against a specific unit within the cube (cube pointer) and then performing a "cube movement".  The cube movements are a defined set of operations that either alter the internal organization of the cube (e.g. splitting along the X-axis and recombining inside-out) or moves the cube pointer to another cube coordinate (e.g. move 1 in positive Y-axis).  

The specific sequence of cube moves are determined by a "traversal sequence".  The traversal sequence is a unique string similar to a passphrase.  It is applied cyclically; if more data remains to be encoded, the traversal sequence will start over again at the beginning.  

Entropy of the system is achieved along four dimensions:

    1. Contents (and size) of the cipher cube
    2. Mapping order of cube movements
    3. Traversal sequence
    4. Initialization seed, which specifies a rotation of the cube and positioning of the cube pointer at a non-origin coordinate

Method:

Give each unit in the cipher cube a value from 0 to 255.  Next, generate a traversal sequence of N moves through the cube-space.  This will be instructions to move from any given unit to another unit along the +/- X, Y, or Z axis.  If a move would go beyond the outer bounds of the cube, the move instead is "wrapped" to the unit on the opposing (perpendicular) side along the same axis as the intended travel.  There can also be instructions that split and recombine the entire cube across either the X, Y, or Z axis, or that invert the values in the whole cube.  Once the sequence is exhausted, it starts repeating again from the beginning (continuing from the current position in the cube).

There will also be a defined starting coordinate and cube orientation from normal (think of this like a salt or random seed).  First, apply any rotations to the cube to change from the normal orientation.  There can be zero to three 90 degree rotations in the positive X, Y, and Z axes, respectively.  The starting coordinate is set against the reoriented cube. This seed offset will be defined as RxRyRzXsYsZs where R for each axis is an integer from 0 to 3 (corresponding to a rotation of 0, 90, 180, or 270 degrees) and X, Y, and Z are values from 1 to N (N is the number of units on the cube edge; (1,1,1) is the origin)

NOTE: It is important to use only even numbers of cube sides.  Otherwise, there will be unit positions that lie directly on each axis, reducing their possible locations during rotation and thus decreasing the number of seed locations and randomness during traversal sequence rotations.

Cube Movements & Modifiers:

    invert
    move x+
    move x-
    move y+
    move y-
    move z+
    move z-
    jump x position across midline
    jump y position across midline
    jump z position across midline
    jump x-y position across midline
    jump x-z position across midline
    jump y-z position across midline
    split-recombine along midline x
    split-recombine along midline y
    split-recombine along midline z
        
Since there are 16 possible cube movements/modifiers, there are 65,636 possible variations that can be defined in the cube movement mapping.  Also, since all movements can be mapped into a hexadecimal string representation, this allows for human-readable mapping sequences.

In the above list, the 'invert' and 'split-recombine's are cube modifiers while the rest are path traversals.  However, only the cube inversion will not change the effective positional relationship between the current cube pointer and the cube.  In the case of a cube rotation during initialization, the cursor coordinates remain fixed and will thus begin operating on the cube in its new relative orientation.

NOTE: Rotating the cube is computationally expensive compared to the other cube movements and modifiers.  This will be prohibitively slow for encoding even moderately large files, hence the limiting of rotations to the intitialization.  Additionally, leaving the cursor fixed in cube space while rotating the cube is equivalent (from an entropy perspective) to a jump across the midline (in one or two axes).  While rotating the cube would re-orient the relationship of the cube values to the cursor, since the cursor is free to move in any direction, the rotation-as-repositioner element becomes unnecessary for encoding.

The 'split-recombine' options can conceptually be imagined as cleaving a cube exactly in half along the x-, y-, or z-axis.  The resulting halves are reassembled into a cube by joining together what were previously the outside faces that were parallel to the interior faces created by the cleaving.  During this process, the cursor position remains fixed as it did for rotations.
