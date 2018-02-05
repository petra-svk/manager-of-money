package MyHomeBuh::Model::User;
use Mojo::Base 'MyHomeBuh::Model::Entity';
use Digest::SHA qw(sha1_hex);

use MyHomeBuh::Model::Income;

has ['user_id', 'name', 'email', 'date_from', 'date_to'];

use autouse 'Data::Dumper' => qw(Dumper);

=head2 check($email, $password)
=cut
sub check {
  my ($m, $email, $pass) = @_;

  my ($user_id, $name, $date_from, $date_to) = $m->dbh->do_sql_row('SELECT id, name, date_from, date_to
                                                  FROM user WHERE email LIKE ? AND password LIKE ?',
                                                  [ $email, 'str', sha1_hex($pass), 'str' ]);

  if($user_id) {
    $m->dbh->do("UPDATE user SET last_login=NOW() WHERE id=?", [ $user_id ]);
    $m->attr('user_id', $user_id);
    $m->attr('email', $email);
    $m->attr('name', $name);
    $m->attr('date_from', $date_from);
    $m->attr('date_to', $date_to);
    return $user_id;
  }
  return undef;
}

=head2 get_prev_income
=cut
sub get_prev_income
{
  my ($m) = @_;
  return $m->dbh->do_sql_row("SELECT prev_income FROM `user` WHERE id=?", [ $m->user_id, 'int' ]) || 0;
}



=head2 update_prev_income
=cut
sub update_prev_income
{
  my ($m, $income) = @_;
  $m->dbh->do("UPDATE user SET prev_income=? WHERE id=?", [$income, $m->user_id]);
}



=head2 update_date_interval
=cut
sub update_date_interval
{
  my ($m, $date_hash) = @_;
  $m->dbh->do("UPDATE user SET date_from=?, date_to=? WHERE id=?", [$date_hash->{ date_from }, $date_hash->{date_to}, $m->user_id ]);
}

1;