package Crypt::CipherCube::TraversalMap;

use Mouse;
use namespace::autoclean;

has 'traversal_map'   => ( is => 'rw', isa => 'ArrayRef' );

has 'traversal_order' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 0,
    trigger => \&_check_start_num,
);


sub _check_start_num {

    my ($self, $traversal_string) = @_;


    confess "Traversal order string is not exactly 16 characters"
        unless 16 == length($traversal_string);

    foreach my $char ( qw/0 1 2 3 4 5 6 7 8 9 A B C D E F/ ) {
        my $cnt = () = $traversal_string =~ /$char/gi; # will count number of times $char found in $traversal_order
        if (0 == $cnt) {
            confess "The required character $char is missing from the traversal order string";
        }
        if ($cnt > 1) {
            confess "The character $char was found more than once in the traversal order string";
        }
    }
}


sub BUILD  {

    my $self = shift;

    my @traversals = qw/
        invert
        move_x_pos
        move_x_neg
        move_y_pos
        move_y_neg
        move_z_pos
        move_z_neg
        midline_jump_x
        midline_jump_y
        midline_jump_z
        midline_jump_xy
        midline_jump_xz
        midline_jump_yz
        split_midline_x
        split_midline_y
        split_midline_z
    /;

    my @traversal_map;
    foreach my $pos ( split('', $self->traversal_order) ) {
        my $index = sprintf("%d", hex($pos));
        push(@traversal_map, $traversals[$index]);
    }

    $self->traversal_map(\@traversal_map);
}

__PACKAGE__->meta->make_immutable;