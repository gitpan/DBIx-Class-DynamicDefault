use strict;
use warnings;

package DBIx::Class::DynamicDefault;

use parent 'DBIx::Class';

our $VERSION = '0.01';

__PACKAGE__->mk_classdata(
    __column_dynamic_default_triggers => {
        on_update => [], on_create => [],
    },
);

=head1 NAME

DBIx::Class::DynamicDefault - Automatically set and update fields

=head1 SYNOPSIS

  package My::Schema::SomeTable;

  __PACKAGE__->load_components(qw/DynamicDefault ... Core/);

  __PACKAGE__->add_columns(
          quux          => { data_type => 'integer' },
          quux_plus_one => { data_type => 'integer',
                             dynamic_default_on_create => \&quux_plus_one_default,
                             dynamic_default_on_update => 'quux_plus_one_default', },
          last_changed  => { data_type => 'integer',
                             dynamic_default_on_create => 'now',
                             dynamic_default_on_update => 'now, },
  );

  sub quux_plus_one_default {
      my ($self) = @_;
      return $self->quux + 1;
  }

  sub now {
      return DateTime->now->epoch;
  }

Now, any update or create actions will set the specified columns to the value
returned by the callback you specified as a method name or code reference.

=head1 DESCRIPTION

Automatically set and update fields with values calculated at runtime.

=cut

sub add_columns {
    my $self = shift;

    $self->next::method(@_);

    my @update_columns;
    my @create_columns;

    for my $column ($self->columns) {
        my $info = $self->column_info($column);

        my $update_trigger = $info->{dynamic_default_on_update};
        push @update_columns, [$column => $update_trigger]
            if $update_trigger;

        my $create_trigger = $info->{dynamic_default_on_create};
        push @create_columns, [$column => $create_trigger]
            if $create_trigger;
    }

    if (@update_columns || @create_columns) {
        $self->__column_dynamic_default_triggers({
            on_update => \@update_columns,
            on_create => \@create_columns,
        });
    }
}

sub insert {
    my $self = shift;

    my @columns = @{ $self->__column_dynamic_default_triggers->{on_create} };
    for my $column (@columns) {
        my $column_name = $column->[0];
        next if defined $self->get_column($column_name);

        my $meth = $column->[1];
        my $default_value = $self->$meth;

        my $accessor = $self->column_info($column_name)->{accessor} || $column_name;
        $self->$accessor($default_value);
    }

    return $self->next::method(@_);
}

sub update {
    my $self = shift;

    my %dirty = $self->get_dirty_columns;

    my @columns = @{ $self->__column_dynamic_default_triggers->{on_update} };
    for my $column (@columns) {
        my $column_name = $column->[0];
        next if exists $dirty{$column_name};

        my $meth = $column->[1];
        my $default_value = $self->$meth;

        my $accessor = $self->column_info($column_name)->{accessor} || $column_name;
        $self->$accessor($default_value);
    }

    return $self->next::method(@_);
}

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 LICENSE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
