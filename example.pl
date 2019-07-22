#! perl

use Modern::Perl;
use Crypt::CipherCube;
use Crypt::CipherCube::Cube;

# when setting cube values manually, use only binary (0/1) values
my $manual =
[
    [
        [0,1,0,1],
        [0,1,0,0],
        [0,1,0,1],
        [0,1,0,0],
    ],
    [
        [0,1,0,1],
        [0,1,0,0],
        [0,1,0,1],
        [0,1,0,0],
    ],
    [
        [0,1,0,1],
        [0,1,0,0],
        [0,1,0,1],
        [0,1,0,0],
    ],
    [
        [0,1,0,1],
        [0,1,0,0],
        [0,1,0,1],
        [0,1,1,0],
    ],
];


# create the cube object with user-defined values
my $cube1 = Crypt::CipherCube::Cube->new( 4 ); #cube => $manual );

# You can also let the cube auto-generate by giving it a size number.
# Be sure to grab $cube1->cube if you do this so you can save for later decryption
# my $cube1 = Crypt::CipherCube::Cube->new( 4 );

# initialize the cipher object with the cube, traversal key, and user-defined seed
# seed sets rotations (Rx,Ry,Rz), starting cube coordinate, and traversal sequence
my $cipher = Crypt::CipherCube->new(
    cube => $cube1,
    traversal_key => 'abcdefghijklmnopThiSIsMy^TestK3y~ê@',
    seed => [1,2,3,0,2,1,'ABCD012345EF6789'],
);

# let's encode a sample binary file
open(my $test_file, '<', 'sample.jpg') or die "no doc: $!";
binmode($test_file);

my $encoded = $cipher->enc($test_file);

close $test_file;

open(my $enc_file, '>', 'enc_doc.jpg') or die "couldn't open doc: $!";
binmode($enc_file);

print $enc_file $encoded;

close $enc_file;

my $decoded;
open(my $enc_file2, '<', 'enc_doc.jpg') or die "couldn't open doc: $!";
binmode($enc_file2);
$decoded = $cipher->dec($enc_file2);

open(my $out_file, '>', 'out_doc.jpg') or die "couldn't open doc: $!";
binmode($out_file);

print $out_file $decoded;

close $out_file;



1;