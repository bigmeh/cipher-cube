package Crypt::CipherCube::Cube;

use Mouse;
use namespace::autoclean;

# planes[rows[cols]] -> z[y[x]]
has 'cube'      => ( is => 'rw', isa => 'ArrayRef', trigger => \&_validate_cube );
has 'size'      => ( is => 'rw', isa => 'Int', default => 8 );
has 'cursor'        => (
    is => 'rw',
    isa => 'ArrayRef[Int]',
    default => sub { [0,0,0] },
    required => 1,
    trigger => \&_validate_cursor,
    auto_deref => 1,
);

has '_is_valid' => ( is => 'rw', isa => 'Bool', default => 0 );


sub val_at_cursor {

    my $self = shift;

    my ($x, $y, $z) = $self->cursor;

    return $self->cube->[$z]->[$y]->[$x];
}

sub invert {

    my $self = shift;

    for (my $pln_cnt = 0; $pln_cnt < $self->size; $pln_cnt++) {
        for (my $row_cnt = 0; $row_cnt < $self->size; $row_cnt++) {
            for (my $col_cnt = 0; $col_cnt < $self->size; $col_cnt++) {
                $self->cube->[$pln_cnt]->[$row_cnt]->[$col_cnt] = $self->cube->[$pln_cnt]->[$row_cnt]->[$col_cnt] ^ 1;
            }
        }
    }
}

sub move_x_pos {

    my $self = shift;

    $self->_move_cursor(0,1);
}

sub move_x_neg {

    my $self = shift;

    $self->_move_cursor(0,-1);
}

sub move_y_pos {

    my $self = shift;

    $self->_move_cursor(1,1);
}

sub move_y_neg {

    my $self = shift;

    $self->_move_cursor(1,-1);
}

sub move_z_pos {

    my $self = shift;

    $self->_move_cursor(2,1);
}

sub move_z_neg {

    my $self = shift;

    $self->_move_cursor(2,-1);
}


sub _move_cursor {

    my ($self, $axis, $pos) = @_;

    my $current = $self->cursor->[$axis];

    # wrap back to origin (zero)
    if ($current == $self->size - 1 && 1 == $pos) {
        $self->cursor->[$axis] = 0;
    }
    # wrap to around opposite outer edge
    elsif (0 == $current && -1 == $pos) {
        $self->cursor->[$axis] = $self->size - 1;
    }
    else {
        $self->cursor->[$axis] = $self->cursor->[$axis] + $pos;
    }
}



sub midline_jump_x {

    my $self = shift;

    $self->_midline_jump(0);
}

sub midline_jump_y {

    my $self = shift;

    $self->_midline_jump(1);
}

sub midline_jump_z {

    my $self = shift;

    $self->_midline_jump(2);
}

sub midline_jump_xy {

    my $self = shift;

    $self->_midline_jump(0);
    $self->_midline_jump(1);
}

sub midline_jump_xz {

    my $self = shift;

    $self->_midline_jump(0);
    $self->_midline_jump(2);
}

sub midline_jump_yz {

    my $self = shift;

    $self->_midline_jump(1);
    $self->_midline_jump(2);
}


sub _midline_jump {

    my ($self, $axis) = @_;

    $self->cursor->[$axis] = $self->size - 1 - $self->cursor->[$axis];
}


sub split_midline_x {

    my $self = shift;

    my @temp_cube;
    my $half  = $self->size / 2;
    my $whole = $self->size;

    foreach my $z_plane (@{$self->cube}) {
        my @inner;
        foreach my $y ( @{$z_plane} ) {
            my @x = @{$y};
            push (@inner, [@x[$half..$whole-1], @x[0..$half-1]]);
        }
        push (@temp_cube, \@inner);
    }

    $self->cube( \@temp_cube );
}

sub split_midline_y {

    my $self = shift;

    my @temp_cube;
    my $half  = $self->size / 2;
    my $whole = $self->size;
    foreach my $z_plane (@{$self->cube}) {
        my @y = @{$z_plane};
        push (@temp_cube, [@y[$half..$whole-1], @y[0..$half-1]]);
    }

    $self->cube( \@temp_cube );
}

sub split_midline_z {

    my $self = shift;

    my @temp_cube = @{$self->cube};
    my $half  = $self->size / 2;
    my $whole = $self->size;

    @temp_cube = (@temp_cube[$half..$whole-1], @temp_cube[0..$half-1]);

    $self->cube( \@temp_cube );
}


# methods for rotating the 3D matrix that are (relatively) computationally
# intensive and used as part of the random seed (not used in actual encryption)

sub rotate_x {

    my $self = shift;

    my $temp_cube;
    for (my $col_cnt = 0; $col_cnt < $self->size; $col_cnt++) {
        for (my $row_cnt = 0; $row_cnt < $self->size; $row_cnt++) {
            for (my $pln_cnt = 0; $pln_cnt < $self->size; $pln_cnt++) {
                $temp_cube->[$pln_cnt]->[$row_cnt]->[$col_cnt] = $self->cube->[$col_cnt]->[$self->size-$row_cnt-1]->[$pln_cnt];
            }
        }
    }
    $self->cube( $temp_cube );
}


sub rotate_y {

    my $self = shift;

    my $temp_cube;
    for (my $row_cnt = 0; $row_cnt < $self->size; $row_cnt++) {
        for (my $pln_cnt = 0; $pln_cnt < $self->size; $pln_cnt++) {
            for (my $col_cnt = 0; $col_cnt < $self->size; $col_cnt++) {
                $temp_cube->[$row_cnt]->[$col_cnt]->[$pln_cnt] = $self->cube->[$self->size-$pln_cnt-1]->[$col_cnt]->[$row_cnt];
            }
        }
    }
    $self->cube( $temp_cube );
}


sub rotate_z {

    my $self = shift;

    my $plane_cnt = 0;
    foreach my $z_plane (@{$self->cube}) {
        my @temp_plane;
        for (my $row_cnt = 0; $row_cnt < $self->size; $row_cnt++) {
            for (my $col_cnt = 0; $col_cnt < $self->size; $col_cnt++) {
                $temp_plane[$row_cnt][$col_cnt] = $z_plane->[$self->size-$col_cnt-1]->[$row_cnt];
            }
        }
        $self->cube->[$plane_cnt] = \@temp_plane;
        $plane_cnt++;
    }
}

sub _gen_cube {

    my ($self, $size) = @_;

    $size = defined $size ? $size : $self->size;

    my $cube;
    for (my $plane=0; $plane <= $size-1; $plane++) {
        for (my $row=0; $row <= $size-1; $row++) {
            for (my $col=0; $col <= $size-1; $col++) {
                # each cell will be 8-bit (0-255) value for single-byte XOR as part of encryption
                # ^^^ I changed this at some point to be single bits in each cell.  probably need
                # to break this out into a new configuration option to do bitwise or in chunks of
                # X bytes
                $cube->[$plane]->[$row]->[$col] = int(rand(1));
            }
        }
    }

    $self->cube($cube);
    $self->_is_valid( 1 );
}


sub _validate_cube {

    my ($self, $child) = @_;

    return if $self->_is_valid;

    $self->size( scalar @{$self->cube} );

    confess "Cube size must be an even number" if $self->size % 2;

    my $plane_cnt = 0;
    foreach my $plane (@{$self->cube}) {
        my $rows = scalar @{$plane};
        confess "Not enough rows in plane $plane_cnt (got $rows, expected ".$self->size.")"
            if $rows != $self->size;

        my $row_cnt = 0;
        foreach my $row (@{$plane}) {
            my $cols = scalar @{$row};
            confess "Not enough columns in row $row_cnt, plane $plane_cnt (got $cols, expected ".$self->size.")"
                if $cols != $self->size;

            foreach my $col (@{$row}) {
                confess "Cube values can only be between 0 and 255"
                    if $col < 0 || $col > 255;
            }
        }
    }

    $self->_is_valid( 1 );
}


sub _validate_cursor {

    my ($self, $child) = @_;

    confess "Cursor array can only contain 3 values (x,y,z)"
        unless scalar @{$child} == 3;

    foreach my $pos (@{$child}) {
        confess "Cursor value cannot be greater than cube size"
            if $pos > $self->size;
        confess "Cursor value cannot be less than zero"
            if $pos < 0;
    }
}


around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    # can just pass an integer like Crypt::CipherCube::Cube->new(8) to gen
    # a new Cube, internally set 'size' property
    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$orig( size => $_[0] );
    }
    # otherwise was passed an existing Cube object
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {

    my $self = shift;

    if (!defined $self->cube) {
        $self->_gen_cube;
    }
}

__PACKAGE__->meta->make_immutable;
