package MyHomeBuh::Controller::Plan;
use Mojo::Base 'Mojolicious::Controller';

use MyHomeBuh::Model::ExpenseCategory;
use MyHomeBuh::Model::PlanForMonth;

use autouse 'Data::Dumper' => qw(Dumper);


=head2 index
=cut
sub index
{
  my $c = shift;

  my $pmonth = $c->get_model('PlanForMonth');
  my $plan_for_month_loop = $pmonth->get;

  my $total_by_col = $pmonth->calc_total($plan_for_month_loop);
  $c->render(
    template => 'plan/index',
    plan_for_month_loop => $plan_for_month_loop,
    date_from => $pmonth->date_from,
    date_to => $pmonth->date_to,
    total_income => $c->get_model('User')->get_prev_income,
    %$total_by_col,
    for_food_per_day => $pmonth->get_sum_for_food_per_day
  );
}


=head2 edit_plan
=cut
sub edit_plan
{
  my ($c) = @_;
  my $data = {
    date_from => $c->session('date_from'),
    date_to => $c->session('date_to'),
    total_income => $c->param('total_income') || 0
  };

  my $pmonth = 'MyHomeBuh::Model::PlanForMonth'->new;
  my $expense_category = 'MyHomeBuh::Model::ExpenseCategory'->new->get_all;
  foreach my $expense (@$expense_category)
  {
    my $form_data = {};
    foreach my $field (qw(expense_category_id  percent_from_income accumulated expenses expenses_add))
    {
      $form_data->{ $field } = $c->req->body_params->param($field.$expense->{ id }) || 0;
    }
    # say Dumper($form_data);
    $pmonth->update_by_cat_id( %$form_data, %$data );
  }

  $c->redirect_to('plan');
}

=head2 create
=cut
sub create
{
  my ($c) = @_;
  my $income = $c->get_model('Income')->calc_income;
  my $new_dates = $c->get_model('PlanForMonth')->create_from_prev(income=>$income);
  $c->session(
    date_from=>$new_dates->{ date_from },
    date_to=>$new_dates->{ date_to }
  );
  $c->index;
}

1;
