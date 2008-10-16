package MooseX::Scaffold;

use warnings;
use strict;

=head1 NAME

MooseX::Scaffold -

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

require Exporter;
use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/Scaffold/;

sub Scaffold { __PACKAGE__ }

use Class::Inspector;
use Carp;
use Moose();
use Moose::Exporter;
use MooseX::ClassAttribute();

no Moose;

sub load_class {
    my $self = shift;
    my $class = shift;
    return 1 if Class::Inspector->loaded($class);
    return eval "require $class;" or die $@;
}

sub _load_scaffold_class {
    my $self = shift;
    my $scaffold_class = shift;
    return if Class::Inspector->loaded($scaffold_class);
    eval "require $scaffold_class;" or croak "Unable to load scaffold class $scaffold_class since: $@";
}

sub setup_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $exporting_package = $given{exporting_package} ||= caller();
    my $scaffold_class = $given{scaffold_class} ||= caller();

    my ( $import, $unimport ) = $self->build_scaffolding_import(%given);

    no strict 'refs';
    *{ $exporting_package . '::import' }   = $import;
}

sub build_scaffolding_import {
    my $self = shift;
    my %given = @_;

    my $scaffold_class = $given{scaffold_class} ||= caller();
    $self->_load_scaffold_class($scaffold_class);

    my $chain_import = $given{chain_import};

    return sub {
        my $CALLER = Moose::Exporter::_get_caller(@_);
        my $class = shift;

        return if $CALLER eq 'main';

        # TODO Check to see if $CALLER is a Moose::Object?
        $scaffold_class->SCAFFOLD($CALLER->meta, exporting_package => $class, @_);

        goto &$chain_import if $chain_import;
    };
}

sub load_or_scaffold_class {
    my $self = shift;
    my %given = @_;

    my $class = $given{class};
    my $scaffold_class = $given{scaffold_class};

    unless (Class::Inspector->loaded($class)) {
        if (Class::Inspector->installed($class)) {
            eval "require $class;";
            die $@ if $@;
            # TODO Check to see if $class is a Moose::Object?
            return $class->meta;
        }
    }

    $self->_load_scaffold_class($scaffold_class);

    my $meta = Moose::Meta::Class->create($class);

    $scaffold_class->SCAFFOLD($meta, exporting_package => undef, %given);

    return $meta;
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

sub extends {
    my $self = shift;
    my $class = shift;
    $class = $class->name if ref $class;
    return Moose::extends($class, @_);
}

sub has {
    my $self = shift;
    my $class = shift;
    $class = $class->name if ref $class;
    return Moose::has($class, @_);
}

sub class_has {
    my $self = shift;
    my $class = shift;
    $class = $class->name if ref $class;

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class => $class,
        metaclass_roles => [ 'MooseX::ClassAttribute::Role::Meta::Class' ],
    );

    return MooseX::ClassAttribute::class_has($class, @_);
}

=head1 SYNOPSIS

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
