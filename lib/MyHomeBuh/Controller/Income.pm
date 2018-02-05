package MyHomeBuh::Controller::Income;
use Mojo::Base 'Mojolicious::Controller';


use autouse 'Data::Dumper' => qw(Dumper);



sub index
{
  my $c = shift;

  $c->render(
    template => 'income/index',
    income_type_loop => $c->get_model('Income')->income_type_for_select,
    current_date => Time::Moment->now->strftime("%Y-%m-%d"),
    income_loop => $c->get_model('Income')->get_income_loop,
    total_income => $c->get_model('Income')->calc_income
  );
}

=head2 add
=cut
sub add
{
  my ($c) = @_;
  my $valid = $c->validate('income');
  if ($valid->has_error)
  {
    $c->stash( error =>'Неверно заполнены поля. Все поля обязательны для заполнения.' );
  }
  else
  {
    $c->get_model('Income')->add($valid->output);
  }

  $c->index;
}

1;