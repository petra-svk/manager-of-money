package MyHomeBuh::LIB::MysqlDB;
use strict;
use warnings;
use utf8;
use feature ':5.10';

use DBI;
use DBI qw(:sql_types);
use Carp;
use autouse 'Data::Dumper' => qw(Dumper);

=head2 new(database=>string, db_user=>string, db_password=>string)

  my $dbh = MyHomeBuh::LIB::DB->new(database=>$database, db_user=>$user, db_password=>$password);

=cut
sub new {
  my ($class, %params) = @_;

  if($params{ database } && $params{ db_user } && $params{ db_password }) {
    my $self = {
      database=>$params{ database },
      db_user=>$params{ db_user },
      db_password=>$params{ db_password },
      sql_types=>{ 'int'=>SQL_INTEGER, 'str'=>SQL_VARCHAR }
    };
    return bless($self, $class);
  }
  croak "Error: __PACKAGE__->new not enough params ".Dumper(\%params);
}


=head2 _dbh

  Получение ссылки к текущей базе данных

=cut
sub _dbh {
  my ($this) = @_;
  if(not($this->{ _dbh })) {
    $this->{ _dbh } = DBI->connect("DBI:mysql:".$this->{ database }.":localhost",
                                    $this->{ db_user }, $this->{ db_password },
                                    { RaiseError=>1, AutoCommit=>1 })
                      or croak $DBI::errstr;
    $this->{ _dbh }->{ mysql_enable_utf8 } = 1;
    $this->{ _dbh }->do('SET NAMES utf8');
  }
  return $this->{ _dbh };
}

=head2 do($query, $bind)

  Для выполнения запросов типа UPDATE, DELETE, CREATE, TRUNCATE

  $dbh->do("INSERT INTO foo VALUES (?, ?)", [2, "Jochen"]);

=head3 return int

  Кол-во обработанных строк

=cut
sub do
{
  my ($this, $query, $bind) = @_;
  croak "Error: __PACKAGE__->do not enough params for $query with ".Dumper($bind) unless($query);

  # возвращает значение больше нуля если все ок, иначе "0E0" такую загадочную комбинацию
  my $count_rows_action = $this->_dbh->do($query, undef, @{ $bind || [] }) or croak($this->_dbh->errstr);
  return $count_rows_action;
}


=head2 do_sql_array_ref($query, $bind=[ ], [ hash_ref=>1|0 ])

  my $array_ref = $dbh->do_sql_array_ref("SELECT id, title FROM foo WHERE id=?",
                                         [ 10, 'int' ], hash_ref=>1);

  Вовзращает значение, если hash_ref=1: [ { key => value, key => value }, { key => value, key => value }, { ... } ]

=cut
sub do_sql_array_ref {
  my ($this, $query, $bind, %option) = @_;
  my $sth = $this->_dbh->prepare($query);
  my $i=1;
  my $j=0;
  while($j < scalar(@{$bind || []}))
  {
    $sth->bind_param($i++, $bind->[$j++],{ TYPE => $this->{sql_types}->{$bind->[$j++]} }) or croak $sth->errstr;
  }
  $sth->execute();

  my $array_ref = [];
  if($option{ hash_ref }) {
    $array_ref = $sth->fetchall_arrayref({});
  }
  else {
    $array_ref = $sth->fetchall_arrayref();
  }
  $sth->finish();
  return $array_ref;
}


=head2 do_sql_hash_ref(query => string, bind => [ array ref ], keys => [ array_ref])

  my $hash_ref = $dbh->do_sql_hash_ref( "SELECT foo, bar, baz FROM foo WHERE foo=?",
                                        [ {val=>'school', type=>'str'} ],
                                        keys=>[qw(foo bar)] );

=cut
sub do_sql_hash_ref {
  my ($this, %params) = @_;

  my $sth = $this->_dbh->prepare($params{ query });
  my $i=1;
  foreach my $bind_data_hash (@{$params{ bind }})
  {
    $sth->bind_param($i++,
                     $bind_data_hash->{ val },
                     { TYPE => $this->{ sql_types }->{ $bind_data_hash->{ type } } }) or croak $sth->errstr;
  }
  $sth->execute();
  my $hash_ref = $sth->fetchall_hashref($params{ keys });
  $sth->finish();
  return ($hash_ref || []);
}

=head2 do_sql_row(string, bind=[array_ref])

  my ($id, $name) = $dbh->do_sql_row('SELECT id, name FROM user WHERE email LIKE ? AND password LIKE ?',
                                    [ {val=>'s@domain.ru', type=>'str'}, {val=>'d4Hsyddds454', type=>'str'}  ])

=cut
sub do_sql_row {
  my ($this, $query, $bind) = @_;

  my $sth = $this->_dbh->prepare($query);
  my $i=1;
  my $j=0;
  while($j < scalar(@{$bind || []}))
  {
    $sth->bind_param($i++, $bind->[$j++],{ TYPE => $this->{sql_types}->{$bind->[$j++]} }) or croak $sth->errstr;
  }
  $sth->execute();
  return $sth->fetchrow_array;
}

=head2 DESTROY

=cut
sub DESTROY {
  my ($this) = @_;
  $this->_dbh->disconnect if $this->_dbh;
}

1;
