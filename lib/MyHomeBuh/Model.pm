package MyHomeBuh::Model;
use Mojo::Base -base;
use Mojo::Loader qw(find_modules load_class);

use Carp qw/ croak /;
use autouse 'Data::Dumper' => qw(Dumper);

has modules => sub { {} };

sub new
{
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);

  my @model_packages = find_modules 'MyHomeBuh::Model';
  for my $pm (grep { $_ ne 'MyHomeBuh::Model::Entity' } @model_packages)
  {
    # Load them safely
    my $e = load_class $pm;
    warn qq{Loading "$pm" failed: $e} and next if ref $e;
    my ($basename) = $pm =~ /MyHomeBuh::Model::(.*)/;
    $self->modules->{$basename} = $pm->new(%args);
  }
  return $self;
}



sub get
{
    my ($self, $model) = @_;
    return $self->modules->{$model} || croak "Unknown model '$model'";
}

1;