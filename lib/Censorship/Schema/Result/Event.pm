use utf8;
package Censorship::Schema::Result::Event;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('NONE');
__PACKAGE__->add_columns(
	qw(id type by description notes),
	'time' => {
		data_type => 'date',
		timezone => 'Europe/Rome',
		datetime_undef_if_invalid => 1,
	},
);

# copied from Censorship::Schema::Result::Request
__PACKAGE__->add_columns('+by' => { is_foreign_key => 1 });
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
  "by",
  "Censorship::Schema::Result::Censor",
  { id => "by" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "domains",
  "Censorship::Schema::Result::Domain",
  { "foreign.request" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->result_source_instance->name(<<'SQL');
(
  SELECT id, date AS time, 's' AS type, by, description, notes
    FROM requests
  UNION
  SELECT id, end  AS time, 'e' AS type, by, description, notes
    FROM requests WHERE (end IS NOT '' AND end IS NOT NULL)
)
SQL

1;
