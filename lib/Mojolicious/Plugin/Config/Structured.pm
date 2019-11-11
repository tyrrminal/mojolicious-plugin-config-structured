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
    $app->home->rel_file(join($PERIOD, $app->moniker, $app->mode, $CONF_FILE_SUFFIX)),
    $app->home->rel_file(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX))
  );

  my $conf = {};
  my ($conf_file) = grep {defined && -r -f} @search;    #get the first existent, readable file
  if (defined($conf_file)) {
    $app->log->info("[Config::Structured] Initializing from '$conf_file'");
    $conf = _parse_cfg_file($conf_file);
  } else {
    $app->log->error('[Config::Structured] Initializing with empty configuration');
  }

  my $def = {};
  my ($def_file) = $app->home->rel_file(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX, $DEF_FILE_SUFFIX));
  if (defined($def_file) && -r -f $def_file) {
    $def = _parse_cfg_file($def_file);
  } else {
    $app->log->error("[Config::Structured] No configuration definition found (tried to read from `$def_file`)");
  }

  $app->helper(
    conf => sub {
      Config::Structured->get() // Config::Structured->new(
        config_values => $conf,
        definition    => $def
      )->__register_default;
    }
  );

  return;
}

# TODO: handle files in other formats (yml, json, xml?) rather than just perl structure
sub _parse_cfg_file($f) {
  return do $f;
}

1;
