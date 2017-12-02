package MyHomeBuh::Model::PlanForMonth;
use Mojo::Base 'MyHomeBuh::Model::Entity';
use MyHomeBuh::Model::ExpenseCategory;

use autouse 'Data::Dumper' => qw(Dumper);

has table => sub { 'plan_for_month' };
has ['date_from', 'date_to'];

=head1 SYNOPSIS

  my $pmonth = 'MyHomeBuh::Model::PlanForMonth'->new(date_from=>'2017-10-14', date_to=>'2017-11-13');

=head1 METHODS

=head2 get(date_from=>'2017-10-14', date_to=>'2017-11-13')
=cut
sub get
{
  my ($m, %params) = @_;
  croak("Don't set date_from or date_to for ".__PACKAGE__."->get") if(!$m->date_from || !$m->date_to);

  # $m->dbh->do("TRUNCATE TABLE ".$m->table);

  my $plan_for_month_loop = $m->dbh->do_sql_array_ref(
                              'SELECT *,
                                ROUND(income,2) AS show_income,
                                ROUND(total,2) AS show_total,
                                ROUND(remaining,2) AS show_remaining
                                FROM ' . $m->table.' WHERE date_from=? AND date_to=? ',
                              [ $m->date_from, 'str', $m->date_to, 'str' ],
                              hash_ref=>1
                            );
  unless ($plan_for_month_loop->[0])
  {
    # создать новый расчетный период
    $plan_for_month_loop = $m->create(%params);
  }
  return $plan_for_month_loop;
}


=head2 create(date_from=>'2017-10-14', date_to=>'2017-11-13')
=cut
sub create
{
  my ($m, %params) = @_;
  croak("Don't set date_from or date_to for ".__PACKAGE__."->create") if(!$m->date_from || !$m->date_to);

  my $expense_category_loop = 'MyHomeBuh::Model::ExpenseCategory'->new->get_all;

  my $plan_for_month_loop = [];
  my $total_percent = 0;
  foreach my $cat (@$expense_category_loop)
  {
    my $percent_from_income = sprintf('%.2f', 100 / scalar(@$expense_category_loop));
    $total_percent += $percent_from_income;
    my $row = {
      expense_category_id => $cat->{ id },
      expense_category_title => $cat->{ title },
      percent_from_income => $percent_from_income,
      accumulated => 0,
      income => 0,
      total => 0, # income + accumulated
      expenses => 0,
      remaining => 0, # total - expenses
      date_from => $m->date_from,
      date_to => $m->date_to,
    };
    unless($m->add($row)) { croak("Can't add new plan for category - ".Dumper($row)); }
    push( @$plan_for_month_loop, $row );
  }

  # уравниваем проценты до 100
  if(100 - $total_percent)
  {
    my $recalc = $plan_for_month_loop->[0]->{ percent_from_income } + (100 - $total_percent);
    $plan_for_month_loop->[0]->{ percent_from_income } = sprintf('%.2f', $recalc);

    $m->dbh->do("UPDATE ".$m->table." SET percent_from_income=? WHERE expense_category_id=? AND date_from=?",
                [ $recalc, $plan_for_month_loop->[0]->{ expense_category_id }, $m->date_from ]);
  }

  return $plan_for_month_loop;
}

=head2 update_by_cat_id(expense_category_id=>X, percent_from_income=>X, accumulated=>X, date_to=>X, date_from=>X, total_income=>X)

  Обновление параметров для одной категории расходов

=cut
sub update_by_cat_id
{
  my ($m, %params) = @_;

  $params{ income } = sprintf( "%.6f", $params{total_income} * ( $params{percent_from_income} / 100 ) );
  $params{ total } = $params{ income } + $params{ accumulated };

  my $expenses_add = eval " $params{ expenses_add } "; # ToDO добавить проверку на корректность выражения
  $params{ expenses } += $expenses_add;
  $params{ remaining } = $params{ total } - $params{ expenses };

  delete $params{total_income};
  delete $params{expenses_add};

  my $where = { expense_category_id=>$params{ expense_category_id }, date_from=>$params{ date_from } };

  $m->edit(\%params, $where)
}



=head2 calc_total($plan_for_month_loop)

  return {
    percent_from_income => '100',
    accumulated => 'X',
    income => 'X',
    total =>'X',
    expenses=>'X',
    remaining=>'X'
  }

=cut
sub calc_total
{
  my ($m, $plan_for_month_loop) = @_;

  my $total = {
    percent_from_income => 0.0,
    accumulated => 0.0,
    income => 0.0,
    total => 0.0,
    expenses=> 0.0,
    remaining=> 0.0
  };

  foreach my $row (@$plan_for_month_loop)
  {
    $total->{ percent_from_income } += $row->{ percent_from_income };
    $total->{ accumulated } += $row->{ accumulated };
    $total->{ income } += $row->{ income };
    $total->{ total } += $row->{ total };
    $total->{ expenses } += $row->{ expenses };
    $total->{ remaining } += $row->{ remaining };
  }

  # у нас рассчитывается до 6 цифры поле запятой
  # но выводить нужно только 2
  $total->{ income } = sprintf('%.2f', $total->{ income });
  $total->{ total } = sprintf('%.2f', $total->{ total });
  $total->{ remaining } = sprintf('%.2f', $total->{ remaining });

  return $total;
}


=head2 get_sum_for_food_per_day
=cut
sub get_sum_for_food_per_day
{
  my ($m) = @_;
  croak("Don't set date_to for ".__PACKAGE__."->get_sum_for_food_per_day") if(!$m->date_to);

  my $food_remaining = $m->dbh->do_sql_row("SELECT remaining FROM ".$m->table."
                                          WHERE expense_category_id=? AND user_id=? AND date_to=?",
                                          [ MyHomeBuh::Model::ExpenseCategory->new->get_food_category, 'int',
                                            $m->user_id, 'int', $m->date_to, 'str' ]);
  my $days = $m->dbh->do_sql_row("SELECT DATEDIFF(?, CURDATE())", [ $m->date_to, 'str' ]);

  my $sum = 0;
  eval { $sum = sprintf('%.2f', $food_remaining / ($days + 1) ) };
  if($@) { croak("Error: ".$@); }

  return $sum;
}

=head2 create_from_prev(income => XXX.XX)
=cut
sub create_from_prev
{
  my ($m, %params) = @_;
  croak("Don't set income ".__PACKAGE__."->create_from_prev") unless($params{income});

  my $date_from_new = Time::Moment->from_string($m->date_from."T00:00:00Z")->plus_months(1)->strftime("%Y-%m-%d");
  my $date_to_new = Time::Moment->from_string($m->date_to."T00:00:00Z")->plus_months(1)->strftime("%Y-%m-%d");

  my $plan_prev_loop = $m->dbh->do_sql_array_ref(
                              'SELECT * FROM ' . $m->table.' WHERE date_from=? AND date_to=? AND user_id=? ',
                              [ $m->date_from, 'str', $m->date_to, 'str', $m->user_id, 'int' ],
                              hash_ref=>1
                            );
  foreach (@$plan_prev_loop)
  {
    delete $_->{ id };
    delete $_->{ user_id };
    $_->{ accumulated } = $_->{ remaining };
    $_->{ income } = sprintf( "%.6f", $params{income} * ( $_->{percent_from_income} / 100 ) );
    $_->{ total } = $_->{ income } + $_->{ accumulated };
    $_->{ expenses } = 0;
    $_->{ remaining } = $_->{ total };
    $_->{ date_from } = $date_from_new;
    $_->{ date_to } = $date_to_new;
    unless($m->add($_)) { croak("Can't add new plan for category - ".Dumper($_)); }
  }

  # TODO в user обновить date_from и date_to

  return { date_from => $date_from_new, date_to => $date_to_new };
}



1;