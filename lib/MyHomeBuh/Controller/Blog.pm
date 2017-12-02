package MyHomeBuh::Controller::Blog;
use Mojo::Base 'Mojolicious::Controller';

use autouse 'Data::Dumper' => qw(Dumper);


=head2 index
=cut
sub index
{
  my $c = shift;

  $c->render();
}

1;