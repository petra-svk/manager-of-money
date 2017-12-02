package MyHomeBuh::Model::Income;
use Mojo::Base 'MyHomeBuh::Model::Entity';

use autouse 'Data::Dumper' => qw(Dumper);

has table => sub { 'income' };


=head2 income_type_for_select

=cut
sub income_type_for_select
{
  my ($m) = @_;

  my $array_ref = $m->dbh->do_sql_array_ref("SELECT id, title FROM income_type_id WHERE user_id=? ORDER BY title",
                                            [$m->user_id, 'int'], hash_ref=>1);
  my $loop = [['Выберите источник' => '0']];
  foreach (@$array_ref)
  {
    push(@$loop, [ $_->{ title } => $_->{ id } ]);
  }
  return $loop;
}

=head2 get_income_loop
=cut
sub get_income_loop
{
  my ($m) = @_;

  return $m->dbh->do_sql_array_ref("SELECT income.sum, t.title, income.date FROM income AS income
                                     LEFT JOIN income_type_id AS t ON income.income_type_id=t.id
                                     WHERE income.user_id=? AND income.date BETWEEN CAST(? AS DATE) AND CAST(? AS DATE) ORDER BY income.date DESC",
                                    [$m->user_id, 'int', $m->date_from, 'str', $m->date_to, 'str'], hash_ref=>1);
}



1;