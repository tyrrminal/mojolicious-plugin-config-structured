package Mojolicious::Plugin::Config::Structured 1.000;

# ABSTRACT: Mojolicious Plugin for Config::Structured: locates and reads config and definition files and loads them into a Config::Structured instance, made available globally as 'conf'
use v5.22;

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
  my ($conf_file) = grep {$_ && -r -f $_} @search;    #get the first existent, readable file
  if (defined($conf_file)) {
    $app->log->info("[Config::Structured] Initializing from '$conf_file'");
    $conf = _parse_cfg_file($conf_file);
  } else {
    $app->log->error("[Config::Structured] Initializing with empty configuration");
  }

  my $def = {};
  my ($def_file) = grep {-r -f $_} $app->home->rel_file(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX, $DEF_FILE_SUFFIX));
  if (defined($def_file)) {
    $def = _parse_cfg_file($def_file);
  } else {
    $app->log->error("[Config::Structured] No configuration definition found (tried to read from `$def_file`)");
  }

  $app->helper(
    conf => sub {
      state $config = Config::Structured->new(
        config_values => $conf,
        definition    => $def
      );
    }
  );
}


# TODO: handle files in other formats (yml, json, xml?) rather than just pl
sub _parse_cfg_file($f) {
  return do $f;
}

1;
