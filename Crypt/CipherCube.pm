package Crypt::CipherCube;

use Mouse;
use Encode;
use namespace::autoclean;

has 'cube'          => ( is => 'ro', isa => 'Crypt::CipherCube::Cube', required => 1 );
has 'traversal_key' => ( is => 'ro', isa => 'Str', required => 1 );
has 'seed'          => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {[0,0,0,0,0,0,'0123456789ABCDEF']}, # no rotations, start at position (0,0,0), default traversal map
    # ***should this even be done?  won't warn about insecure default
#    trigger => \&_apply_seed,
);

has '_traversal_map'      => ( is => 'rw', isa => 'Crypt::CipherCube::TraversalMap' );
has '_traversal_key_hex'  => ( is => 'rw', isa => 'ArrayRef[Str]' );
has '_orig_cube'          => ( is => 'rw', isa => 'ArrayRef' );

sub enc {

    my ($self, $data) = @_;

    confess "Nothing to encode" if !defined $data;

    $self->cube->cube( $self->_orig_cube );
    $self->_apply_seed;

    my $key_size = scalar @{$self->_traversal_key_hex};
    my $key_pos = 0;

    my $encoded;
    if (-f $data) { # is a filehandle

        my @data;
        while (read($data, my $byte, 1024)) {

            my @bits = unpack('B8' x 1024, $byte);

            push(@data, @bits);
        }
        my $traversal_map = $self->_traversal_map->traversal_map;
        foreach my $byte (@data) {

            my $tk = hex $self->_traversal_key_hex->[$key_pos];
            my $traversal = $traversal_map->[$tk];

            $self->cube->$traversal;

            $encoded .= pack('B*', unpack('B8', $self->cube->val_at_cursor) ^ $byte);

            $key_pos++;
            $key_pos = 0 if $key_pos >= $key_size;
        }
    }
    else { # is a string of data
        foreach my $bit (unpack( 'B*', $data)) {
            my $tk = hex $self->_traversal_key_hex->[$key_pos];
            my $traversal = $self->_traversal_map->traversal_map->[$tk];

            $self->cube->$traversal;

            $encoded .= $bit ^ $self->cube->val_at_cursor;

            $key_pos++;
            $key_pos = 0 if $key_pos >= $key_size;
        }
    }

    return $encoded;
}


sub dec {

    my ($self, $data) = @_;

    confess "Nothing to decode" if !defined $data;

    $self->cube->cube( $self->_orig_cube );
    $self->_apply_seed;

    my $key_size = scalar @{$self->_traversal_key_hex};
    my $key_pos = 0;

    my $decoded;

    if (-f $data) { # is a filehandle
        my @data;
        while (read($data, my $byte, 1024)) {

            my @bits = unpack('B8' x 1024, $byte);

            push(@data, @bits);
        }

        foreach my $byte (@data) {
            my $tk = hex $self->_traversal_key_hex->[$key_pos];
            my $traversal = $self->_traversal_map->traversal_map->[$tk];

            $self->cube->$traversal;

            my $bitmask = unpack('B8', $self->cube->val_at_cursor);

            $decoded .= pack('B8', $bitmask ^ $byte);

            $key_pos++;
            $key_pos = 0 if $key_pos >= $key_size;
        }
    }
    else { # is a string of data
        my @data = split('', $data );

        foreach my $byte (@data) {
            $byte = unpack('B*', $byte);
            my $tk = hex $self->_traversal_key_hex->[$key_pos];
            my $traversal = $self->_traversal_map->traversal_map->[$tk];

            $self->cube->$traversal;

            my $bitmask = unpack('B8', $self->cube->val_at_cursor);

            $decoded .= pack('B8', $bitmask ^ $byte);

            $key_pos++;
            $key_pos = 0 if $key_pos >= $key_size;
        }
    }
    return $decoded;
}


sub _apply_seed {

    my ($self) = @_;

    my $child = $self->seed;

    use Crypt::CipherCube::TraversalMap;

    my %rotations = (
        0 => 'rotate_x',
        1 => 'rotate_y',
        2 => 'rotate_z',
    );

    for (my $i=0; $i<=2; $i++) {
        confess "Rotation seed numbers must be values from 0 to 3"
            if $child->[$i] !~ /^[0-3]$/;

        my $rotation = $rotations{$i};
        $self->cube->$rotation( $child->[$i] );
    }

    my $set_cursor;
    for (my $i=3; $i<=5; $i++) {
        confess "Position seed numbers must be values from 0 to one less than the edge length of the cube"
            if $child->[$i] < 1 || $child->[$i] >= $self->cube->size;

        $set_cursor->[$i-3] = $child->[$i];
    }
    $self->cube->cursor( $set_cursor );

    #my $traversal_start = defined $child->[6] ? $child->[6] : 0;
    my $traversal_order = defined $child->[6] ? uc($child->[6]) : '0123456789ABCDEF';
    warn "No traversal order string used, default used instead (this is much less secure)"
        if (!defined $child->[6]);

    $self->_traversal_map( Crypt::CipherCube::TraversalMap->new( traversal_order => $traversal_order ) );
}


sub BUILD {

    my $self = shift;

    my $key = encode_utf8($self->traversal_key);

    my $tk = unpack('H*', $key);
    my @tk = split('', $tk);

    $self->_traversal_key_hex( \@tk );

    my @cube_copy = @{$self->cube->cube};

    $self->_orig_cube( \@cube_copy );

    $self->_apply_seed;
}

__PACKAGE__->meta->make_immutable;
