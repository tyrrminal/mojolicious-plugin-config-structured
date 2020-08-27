package Mojolicious::Plugin::Config::Structured;

# ABSTRACT: Mojolicious Plugin for Config::Structured: locates and reads config and definition files and loads them into a Config::Structured instance, made available globally as 'conf'

=head1 SYNOPSIS

  # For a full Mojo app
  $self->plugin('Config::Structured' => {config_file => $filename});

  ...

  if ($c->conf->feature->enabled) {
    ...
  }

  say $c->conf->email->recipient->{some_feature};

=head1 DESCRIPTION

Initializes L<Config::Structured> from two files:

=over 

=item C<definition> 

pulled from $app_home/$moniker.conf.def

=item C<config_values> 

pulled from the first existent, readable file from:

  config_file parameter value

  $app_home/$moniker.$mode.conf

  $app_home/$moniker.conf

These files are expected to contain perl hashref structures

=back

=method conf()

Returns an L<Config::Structured> instance initialized to the root of the 
configuration definition

=cut
use 5.022;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Config::Structured;

use Readonly;

Readonly::Scalar our $PERIOD => q{.};

Readonly::Scalar our $CONF_FILE_SUFFIX => q{conf};
Readonly::Scalar our $DEF_FILE_SUFFIX  => q{def};

sub register ($self, $app, $params) {
  my @search = (
    $params->{config_file},
    $app->home->child(join($PERIOD, $app->moniker, $app->mode, $CONF_FILE_SUFFIX))->to_string,
    $app->home->child(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX))->to_string
  );
  my ($conf_file) = grep {defined && -r -f} @search;    #get the first existent, readable file
  unless (defined($conf_file)) {
    $app->log->error('[Config::Structured] Initializing with empty configuration');
  }

  @search =
    ($params->{structure_file}, $app->home->child(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX, $DEF_FILE_SUFFIX))->to_string);
  my ($def_file) = grep {defined && -r -f} @search;
  unless (defined($def_file) && -r -f $def_file) {
    $app->log->error("[Config::Structured] No configuration definition found (tried to read from `$def_file`)");
  }

  my $conf = Config::Structured->new(
    config    => $conf_file,
    structure => $def_file,
    hooks     => $params->{hooks},
  )->__register_default;

  $app->helper(
    conf => sub {
      return $conf;
    }
  );

  return;
}

1;
