package MooseX::Scaffold;

use warnings;
use strict;

=head1 NAME

MooseX::Scaffold - Template metaprogramming with Moose

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package MyScaffolder;

    use MooseX::Scaffold;

    MooseX::Scaffolder->setup_scaffolding_import;

    sub SCAFFOLD {
        my $class = shift;
        my %given = @_;

        $class->has($given{kind} => is => 'ro', isa => 'Int', required => 1);

        # Using MooseX::ClassAttribute
        $class->class_has(kind => is => 'ro', isa => 'Str');
        $class->package->kind($given{kind});
    }

    package MyAppleClass;

    use Moose;
    use MyScaffolder kind => 'apple';

    package MyBananaClass;

    use Moose;
    use MyScaffolder kind => 'banana';

    # ... meanwhile, back at the Batcave ...

    use MyAppleClass;

    my $apple = MyAppleClass->new(apple => 1);
    my $banana = MyAppleClass->new(banana => 2);

=head1 DESCRIPTION

MooseX::Scaffolder is a tool for creating or augmenting Moose classes on-the-fly. 

You can setup scaffolding to take place when a C<use> is executed (any import arguments are passed
to the scaffold subroutine) or you can explicitly call MooseX::Scaffolder->scaffold with the scaffolding
code and the package name for the class.

Depending on what you're trying to do, MooseX::Scaffolder can behave in three different ways (My::Class is the class
you're trying to create/augment):

    load_and_scaffold (scaffold)   - Attempt to require My::Class from My/Class.pm or do Moose::Meta::Class->create('My::Class')
                                     to make the package on-the-fly. Scaffold the result.

    load_or_scaffold (load)        - Attempt to require My::Class from My/Class.pm and stop if that works. If no My/Class.pm is
                                     found in @INC, then do Moose::Meta::Class->create('My::Class') to make the package on-the-fly
                                     and scaffold My::Class. This option can be used to create a default class if one isn't found.

    scaffold_without_load          - Don't attempt to require My::Class, just create it on-the-fly and scaffold it.

=head1 METHODS

MooseX::Scaffolder->load_and_scaffold

MooseX::Scaffolder->scaffold

MooseX::Scaffolder->load_or_scaffold

MooseX::Scaffolder->load

MooseX::Scaffolder->scaffold_without_load

MooseX::Scaffolder->build_scaffolding_import

MooseX::Scaffolder->setup_scaffolding_import

=cut

use Class::Inspector;
use Carp::Clan;
use Moose();
no Moose;
use Moose::Exporter;
use MooseX::ClassAttribute();

use MooseX::Scaffold::Class;

sub setup_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $exporting_package = $given{exporting_package};
    $exporting_package ||= $given{exporter} ? delete $given{exporter} : caller;

    my $scaffolder = $given{scaffolder} ||= caller;

    my ( $import, $unimport ) = $self->build_scaffolding_import(%given);

    no strict 'refs';
    *{ $exporting_package . '::import' }   = $import;
}

sub build_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $scaffolder = $given{scaffolder} ||= caller;
    my $chain_import = $given{chain_import};

    return sub {
        my $CALLER = Moose::Exporter::_get_caller(@_);
        my $exporting_package = shift;

        return if $CALLER eq 'main';

        # TODO Check to see if $CALLER is a Moose::Object?
        $self->scaffold(class_package => $CALLER, %given, exporting_package => $exporting_package, @_);

        goto &$chain_import if $chain_import;
    };
}

sub load {
    my $self = shift;
    return $self->scaffold(@_, load_or_scaffold => 1);
}

sub load_or_scaffold {
    my $self = shift;
    return $self->load(@_);
}

sub load_and_scaffold {
    my $self = shift;
    return $self->scaffold(@_);
}

sub scaffold_without_load {
    my $self = shift;
    return $self->scaffold(@_, scaffold_without_load => 1);
}

sub scaffold {
    my $self = shift;
    my %given = @_;

    my $class_package = $given{class_package} || $given{class};
    my $scaffolder = $given{scaffolding_package} || $given{scaffolder};
    my $load_or_scaffold = $given{load_or_scaffold};
    my $scaffold_without_load = $given{scaffold_without_load};

    if (! $scaffold_without_load && Class::Inspector->loaded($class_package)) {
        return if $load_or_scaffold;
    }
    else {
        if (! $scaffold_without_load && Class::Inspector->installed($class_package)) {
            eval "require $class_package;";
            die $@ if $@;
            return if $load_or_scaffold;
        }
        else {
            my $meta = Moose::Meta::Class->create($class_package);
        }
    }

    my $scaffolding_package;
    if (ref $scaffolder eq 'CODE') {
    }
    else {
        $scaffolding_package = $scaffolder;
        $self->_load_scaffolding_package($scaffolding_package);
        $scaffolder = $scaffolding_package->can('SCAFFOLD');
        croak "Unable to find method SCAFFOLD in package $scaffolding_package" unless $scaffolder;
    }

    $self->_scaffold($class_package, $scaffolder, @_, scaffolding_package => $scaffolding_package);

}

sub _load_scaffolding_package {
    my $self = shift;
    my $scaffolding_package = shift;
    return if Class::Inspector->loaded($scaffolding_package);
    eval "require $scaffolding_package;" or croak "Unable to load scaffolding class $scaffolding_package since: $@";
}

sub _scaffold {
    my $self = shift;
    my $class_package = shift;
    my $scaffolder = shift;

    my $class = MooseX::Scaffold::Class->new($class_package);
    $scaffolder->($class, @_, class_package => $class_package);
}

sub parent_package {
    my $self = shift;
    my $package = shift;
    return $self->repackage($package, undef, shift);
}

sub child_package {
    my $self = shift;
    my $package = shift;
    return $self->repackage($package, shift);
}

sub repackage {
    my $self = shift;
    my $package = shift;
    my $replacement = shift;
    my $count = shift;

    $count = 0 unless defined $count && length $count;

    return $package unless $count >= 1;
    
    my @package = split m/::/, $package;
    pop @package while $count--;
    push @package, $replacement if defined $replacement && length $replacement;
    return join '::', @package;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/moosex-classscaffold/tree/master>

    git clone git://github.com/robertkrimen/moosex-classscaffold.git MooseX-Scaffold

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-classscaffold at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Scaffold>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Scaffold


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Scaffold>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Scaffold>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Scaffold>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Scaffold>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::Scaffold
