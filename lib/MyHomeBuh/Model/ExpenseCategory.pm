package MyHomeBuh::Model::ExpenseCategory;
use Mojo::Base 'MyHomeBuh::Model::Entity';

use autouse 'Data::Dumper' => qw(Dumper);

has table => sub { 'expense_category_id' };


=head2 get_all
=cut
sub get_all
{
  my ($m) = @_;
  # запрос проверка, что есть пользователь с такими логином и паролем.
  return $m->dbh->do_sql_array_ref('SELECT * FROM ' . $m->table, [], hash_ref=>1);
}

=head2 get_food_category
=cut
sub get_food_category { my ($m) = @_; return $m->dbh->do_sql_row("SELECT id FROM " . $m->table." WHERE class = 'food'"); }

1;