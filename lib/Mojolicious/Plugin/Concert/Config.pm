package Mojolicious::Plugin::Concert::Config;

# ABSTRACT: Mojolicious Plugin for Concert::Config

use Config::Structured;

sub register {
  my ($self, $app, $params) = @_;

  my $conf = {};
  my @search = (
    $params->{config_file},
    $app->home->rel_file(join($PERIOD, $app->moniker, $app->mode, 'conf')),
    $app->home->rel_file(join($PERIOD, $app->moniker,             'conf'))
  );
    $app->log->info("[Config::Structured] Initializing from '$conf_file'");
    $conf = _parse_cfg_file($conf_file);
  } else {
    $app->log->error("[Config::Structured] Initializing with empty configuration");
  }

  my $def = {};
  my $def_file = $app->home->rel_file(join($PERIOD, $app->moniker, qw(conf def)));
  if(-r -f $def_file) {
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


# Someday we'll handle json/yml/xml?/ini? here, but for now just supports perl structure
sub _parse_cfg_file {
  my $f = shift;
  return do $f;
}

1;
