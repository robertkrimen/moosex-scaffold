package MooseX::Scaffold::Class;

use strict;
use warnings;

use overload
    "" => \&name,
    fallback => 1,
;

sub new {
    my $self = bless {}, shift;
    my $package = $self->{package} = shift;
    return $self;
}

sub name {
    return shift->package;
}

sub package {
    return shift->{package};
}

sub meta {
    return shift->package->meta;
}

for my $method (qw/ extends has before after around super override augment /) {
    no strict 'refs';
    my $moose_method = Moose->can($method);
    *$method = sub {
        my $self = shift;
        return $moose_method->($self->package, @_);
    };
}

sub class_has {
    my $self = shift;
    # TODO Check to see if the proper role has been applied first
    return MooseX::ClassAttribute::class_has($self->package, @_);
}

1;
