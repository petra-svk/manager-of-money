package MyHomeBuh::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

=head2 login
=cut
sub login
{
  my ($c) = @_;

  my $email = $c->param('email') || '';
  my $pass = $c->param('pass') || '';
  my $user_id = 0;
  unless( $user_id = $c->user->check($email, $pass) )
  {
    return $c->render;
  }

  $c->session(
    user_id => $user_id,
    email => $email,
    name=>$c->user->name,
    date_from=>$c->user->date_from,
    date_to=>$c->user->date_to
  );
  $c->flash(message => 'Вы успешно вошли в личный банк.');

  $c->redirect_to('plan');
}

=head2 logged_in

  Проверка, что мы авторизованы

=cut
sub logged_in
{
  my $c = shift;
  return 1 if $c->session('user_id');
  $c->redirect_to('login');
  return undef;
}

=head2 logout
=cut
sub logout
{
  my $c = shift;
  $c->session(expires => 1);
  $c->redirect_to('login');
}

1;