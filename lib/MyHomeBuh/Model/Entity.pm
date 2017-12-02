package MyHomeBuh::Model::Entity;
use Mojo::Base -base;

use MyHomeBuh::LIB::MysqlDB;
use autouse 'Data::Dumper' => qw(Dumper);

sub croak {require Carp; Carp::croak(@_)}

has 'dbh' => sub {
  my $database = 'myhomebuh';
  my $user = 'myhomebuh';
  my $password = 'Hdw7d_2d@slsa;';
  state $dbh = MyHomeBuh::LIB::MysqlDB->new(database=>$database, db_user=>$user, db_password=>$password);
};

has 'table' => sub { croak('Необходимо определить таблицу в дочернем классе Entity.'); };
has 'app';

=head2 add($row)
=cut
sub add
{
  my ($m, $row) = @_;

  my $sql = "INSERT INTO ".$m->table." SET";
  my $bind = [];
  foreach my $field (keys(%$row))
  {
    $sql .= " $field=?,";
    push(@$bind, $row->{ $field });
  }
  $sql .= ' user_id=? ';
  push(@$bind, $m->user_id);
  my $count_insert = $m->dbh->do($sql, $bind);
  return $count_insert eq '0E0' ? 0 : $count_insert;
}

=head2 edit($row_edit, $row_where)
=cut
sub edit
{
  my ($m, $row_edit, $row_where) = @_;
  if(!$row_edit || !$row_where)
  {
    croak "Not enough arguments ".__PACKAGE__."->edit: ".Dumper({row_edit=>$row_edit, row_where=>$row_where});
  }

  my $sql = "UPDATE ".$m->table." SET";
  my $bind = [];
  foreach my $field (keys(%$row_edit))
  {
    $sql .= " $field=?,";
    push(@$bind, $row_edit->{ $field });
  }
  $sql =~ s/,$//;
  $sql .= " WHERE";
  foreach my $field (keys(%$row_where))
  {
    $sql .= " $field=? AND";
    push(@$bind, $row_where->{ $field });
  }
  $sql =~ s/AND$//;
  my $count = $m->dbh->do($sql, $bind);
  return $count eq '0E0' ? 0 : $count;
}


# =head2 add( $p - ссылка на хэш, параметры зависят от сущности, которую добавляем )
# =cut
# sub add
# {
#   my ($self, $p) = @_;
#   my $count_rows_action = 0; # кол-во строк, которые были вставлены

#   my $bind = [];
#   foreach (@$p{ @{ $self->sql_check_copy_bind } }) {
#     push @$bind, { val=>$_, type=>'str' }
#   }
#   my ($obj_id) = $self->dbh->do_sql_row(query=>'SELECT id FROM '.$self->table.' WHERE '.$self->sql_check_copy.' LIMIT 1',
#                                         bind=>$bind);
#   unless ($obj_id)
#   {
#     eval
#     {
#       my $sql_insert = '';
#       my $sql_bind = [];
#       foreach my $field (keys(%$p))
#       {
#         push(@$sql_bind, $p->{ $field });
#         $sql_insert.=$field."=?, ";
#       }
#       $sql_insert=~s/,\s$/ /;

#       $count_rows_action = $self->dbh->do("INSERT INTO ".$self->table." SET $sql_insert ", $sql_bind);
#     };
#     if($@) { croak $@."<br>Параметры: ".Dumper($p); }
#   }
#   return $count_rows_action;
# }

# =head2 delete({ entity_id =>XXX, filepath => XXX, fields_to_del => [ 'image', 'filename' ] })
#   filepath - путь к папке, в которой лежат файлы, которые нужно удалить
#   fields_to_del - массив полей из базы, в которых записаны имена файлов
# =cut
# sub delete
# {
#   my ($self, $p) = @_;
#   my $count_rows_action = 0; # кол-во строк, которые были удалены

#   my ($exist) = $self->dbh->do_sql_row(query=>'SELECT 1 FROM '.$self->table.' WHERE id=?',
#                                         bind=>[{ val=>$p->{ entity_id }, type=>'int' }]);
#   if($exist)
#   {
#     eval
#     {
#       my $files_to_del = $self->_get_files_to_delete($p);
#       say Dumper($files_to_del);
#       $count_rows_action = $self->dbh->do("DELETE FROM ".$self->table." WHERE id=?", [$p->{ entity_id }]);
#       if(@$files_to_del) {
#         foreach my $filename (@$files_to_del) { unlink $filename;  }
#       }
#     };
#     if($@) { croak $@."<br>Параметры: ".Dumper($p); }
#   }
#   return $count_rows_action;
# }

# =head2 delete_list(ids => $array_ref [, filepath => XXX, fields_to_del => [ 'image', 'filename' ] ])

#   Удалить список объектов.

# =cut
# sub delete_list
# {
#   my ($model, %p) = @_;

#   foreach my $id ( @{ $p{ ids } } )
#   {
#     # если не удается удалить какую-то запись
#     unless( $model->delete({ entity_id => $id, filepath => $p{filepath}, fields_to_del => $p{fields_to_del} }) )
#     {
#       return 0;
#     }
#   }
#   return 1;
# }

# =head2 update( $p - ссылка на хэш, параметры зависят от сущности, которую добавляем )
# =cut
# sub update
# {
#   my ($self, $p) = @_;
#   my $count_rows_action = 0; # кол-во строк, которые были вставлены

#   croak $@."<br>Параметры: ".Dumper($p) unless($p->{ entity_id });

#   my $bind = [ { val=>$p->{ entity_id }, type=>'int' } ];
#   my $entity_id = $p->{ entity_id };
#   delete $p->{ entity_id }; # удаляем, чтобы оно не фигурировало в sql запросе обновления

#   my ($is_exist) = $self->dbh->do_sql_row(query=>'SELECT 1 FROM '.$self->table.' WHERE id=?',
#                                           bind=>$bind);
#   if ($is_exist)
#   {
#     eval
#     {
#       my $sql_update = '';
#       my $sql_bind = [];
#       foreach my $field (keys(%$p))
#       {
#         push(@$sql_bind, $p->{ $field });
#         $sql_update.=$field."=?, ";
#       }
#       $sql_update=~s/,\s$/ /;
#       push(@$sql_bind, $entity_id);

#       say "UPDATE ".$self->table." SET $sql_update WHERE id=? ";
#       say Dumper($sql_bind);

#       $count_rows_action = $self->dbh->do("UPDATE ".$self->table." SET $sql_update WHERE id=? ", $sql_bind);
#     };
#     if($@) { croak $@."<br>Параметры: ".Dumper($p); }
#   }
#   return $count_rows_action;
# }

# =head2 data_by_id(id => XXX)

#   Получаем данные одной сущности

# =cut
# sub data_by_id
# {
#   my ($model, %p) = @_;

#   my $data_loop = $model->dbh->do_sql_array_ref(
#     "SELECT * FROM ".$model->table." WHERE id=? ",
#     [ $p{ id }, 'int'],
#     hash_ref=>1
#   );

#   return scalar(@$data_loop) ? $data_loop->[0] : {};
# }

# =head2 _get_files_to_delete({ entity_id =>XXX, filepath => XXX, fields_to_del => [ 'image', 'filename' ] })

#   filepath - путь к папке, в которой лежат файлы, которые нужно удалить
#   fields_to_del - массив полей из базы, в которых записаны имена файлов

# =cut
# sub _get_files_to_delete
# {
#   my ($model, $p) = @_;
#   my @filenames = ();

#   foreach my $field ( @{$p->{ fields_to_del } || []} ) {
#     my ($filename) = $model->dbh->do_sql_row(query=>'SELECT '.$field.' FROM '.$model->table.' WHERE id=?',
#                                             bind=>[{ val=>$p->{ entity_id }, type=>'int' }]);
#     push(@filenames, $p->{ filepath }.$filename);
#   }
#   return \@filenames;
# }


1;

=encoding utf8

=head1 NAME

MyHomeBuh::Model::Entity - базовый класс для сущностей в базе данных

=head1 SYNOPSIS

  package MyHomeBuh::Model::User;
  use Mojo::Base 'MyHomeBuh::Model::Entity';


=head1 DESCRIPTION

L<MyHomeBuh::Model::Entity> содержит базовые методы для сущностей в базе данных.

=cut
