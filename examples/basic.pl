#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);

# Declare a scalar
my $scalar = 5;

# Declare an array
#my @array = qw(1 2 3 4 5);
my @array = (1, 2, 3, 4, 5);

# Declare a hash
#my %hash = qw(key1 value1 key2 value2 key3 value3);
my %hash = ( key1 => "value1",
             key2 => "value2",
             key3 => "value3",
);

# Access scalar
say "\$scalar = ",$scalar;

# Access array
say "\$array[0] = ",$array[0];

# Access hash
say "\$hash{key1} = ",$hash{key1};

# Declare a reference to a scalar
my $scalar_ref = \$scalar;

# Declare a reference to an array
my $array_ref = \@array;

# Declare a reference to a hash
my $hash_ref = \%hash;

# Access a scalar reference
say "\$scalar_ref = ",$scalar_ref;
say "\$\$scalar_ref = ",$$scalar_ref;

# Access an array reference
say "\$array_ref = ",$array_ref;
say "\$array_ref->[0] = ",$array_ref->[0];

# Access a hash reference
say "\$hash_ref = ",$hash_ref;
say "\$hash_ref->{key1} = ",$hash_ref->{key1};
