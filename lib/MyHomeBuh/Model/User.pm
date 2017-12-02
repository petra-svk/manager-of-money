package MyHomeBuh::Model::User;
use Mojo::Base 'MyHomeBuh::Model::Entity';
use Digest::SHA qw(sha1_hex);

has ['id', 'name', 'email', 'date_from', 'date_to'];

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
    $m->attr('id', $user_id);
    $m->attr('email', $email);
    $m->attr('name', $name);
    $m->attr('date_from', $date_from);
    $m->attr('date_to', $date_to);
    return $user_id;
  }
  return undef;
}

1;