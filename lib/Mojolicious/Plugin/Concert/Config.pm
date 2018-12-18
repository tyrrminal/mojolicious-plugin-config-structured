package Mojolicious::Plugin::Concert::Config;

# ABSTRACT: Mojolicious Plugin for Concert::Config

use Mojo::Base 'Mojolicious::Plugin';
use Concert::Config;
use Concert::Constants;

sub register {
  my ($self, $app, $params) = @_;

  my $conf = {};
  my @search = (
    $params->{config_file},
    $app->home->rel_file(join($PERIOD, $app->moniker, $app->mode, 'conf')),
    $app->home->rel_file(join($PERIOD, $app->moniker,             'conf'))
  );
  my ($conf_file) = grep {$_ && -r -f $_} @search; #get the first extant, readable file
  if(defined($conf_file)) {
    $app->log->info("[Concert::Config] Initializing from '$conf_file'");
    $conf = _parse_cfg_file($conf_file);
  } else {
    $app->log->error("[Concert::Config] Initializing with empty configuration");
  }

  my $def = {};
  my $def_file = $app->home->rel_file(join($PERIOD, $app->moniker, qw(conf def)));
  if(-r -f $def_file) {
    $def = _parse_cfg_file($def_file);
  } else {
    $app->log->error("[Concert::Config] No configuration definition found (tried to read from `$def_file`)");
  }

  $app->helper(
    conf => sub {
      state $config = Concert::Config->new(
         _conf => $conf,
         _def  => $def
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
