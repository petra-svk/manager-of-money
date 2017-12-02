package MyHomeBuh;
use Mojo::Base 'Mojolicious';
use Time::Moment;
use MyHomeBuh::Model;
require MyHomeBuh::Model::User;

# Хэш-таблица  функций валидации форм на сайте
my %VALIDATORS = (
  income=> \&_validate_income,
);

# This method will run once at server start
sub startup
{
  my $app = shift;

  # Make signed cookies tamper resistant
  $app->secrets(['Gt64_=@ddY64jdh1fsnvldi87gSea!fdsf63gs-gdsahj@']);
  $app->set_helpers;

  # Router
  my $r = $app->routes;

  $r->get('/')->to('Blog#index')->name('blog');

  # Личный кабинет
  $r->any('/cabinet')->to('User#login')->name('login');

  my $protected = $r->under('/cabinet')->to('User#logged_in');
  $protected->get('/plan')->to('Plan#index')->name('plan');
  $protected->post('/plan/edit')->to('Plan#edit_plan')->name('edit_plan');
  $protected->get('/plan/create')->to('Plan#create')->name('create_plan');

  $protected->get('/income')->to('Income#index')->name('income');
  $protected->any(['GET', 'POST'] => '/income/add')->to('Income#add')->name('add_income');

  $protected->get('/logout')->to('User#logout')->name('logout');
}



sub set_helpers
{
  my ($app) = @_;
  # объект текущего пользователя
  $app->helper( 'user' => sub { state $user = 'MyHomeBuh::Model::User'->new } );

  # создадим соответствующий хелпер для вызова модели из контроллеров
  my $model = 'MyHomeBuh::Model'->new(app => $app);
  $app->helper( 'get_model' => sub {
    my ($c, $module_name) = @_;
    my $m = $model->get($module_name);
    $m->attr('date_from', $c->session('date_from'));
    $m->attr('date_to', $c->session('date_to'));
    $m->attr('user_id', $c->session('user_id'));
    return $m;
  });

  # функции валидации различных форм
  $app->helper( 'validate' => sub {
    my ($c, $form_name) = @_;
    my $out = $VALIDATORS{$form_name}->($c->validation);
    return $out;
  });

  # текущая корневая папка проекта
  $app->helper( 'home_dir' => sub {
    my $home = 'Mojo::Home'->new;
    $home->detect;
    return "$home";
  });
}



sub _validate_income
{
  my $validation = shift;
  $validation->csrf_protect;
  $validation->required('sum', 'trim')->like(qr/^[0-9]{1,6}\.?[0-9]{1,2}$/);
  $validation->required('income_type_id')->like(qr/^[1-9][0-9]?$/);
  $validation->required('date')->like(qr/^(2\d{3})\-((0[1-9])|1[0-2])\-(([0-2][1-9])|(3[01])|10|20)$/);

  return $validation;
}

1;
