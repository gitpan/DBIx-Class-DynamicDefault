use strict;
use warnings;
use Test::More tests => 9;
use DBICx::TestDatabase;

BEGIN { use_ok('DBIx::Class::DynamicDefault') }

use FindBin;
use lib "$FindBin::Bin/lib";

my $schema = DBICx::TestDatabase->new('TestSchema');
my $rs     = $schema->resultset('Table');

my $row = $rs->create({});

is($row->quux, 1, 'default on create with methodname');
is($row->garply, undef, 'no default on create');
is($row->corge, 'create', 'default on create with coderef');

$row->update;

is($row->quux, 1, 'no default on update');
is($row->garply, $$, 'default on update with coderef');
is($row->corge, 'update', 'default on update with methodname');

$row->garply(-42);
$row->update;

is($row->garply, -42, 'defaults don\'t get set when a value is specified explicitly on update');

$row = $rs->create({ quux => -23 });

is($row->quux, -23, 'defaults don\'t get set when a value is specified explicitly on create');
