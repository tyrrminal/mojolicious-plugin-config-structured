package Mojolicious::Plugin::Concert::Config;

# ABSTRACT: Mojolicious Plugin for Concert::Config

use Mojo::Base 'Mojolicious::Plugin';
use Concert::Config;
use Concert::Constants;

sub register {
  my ($self, $app, $params) = @_;

  my $conf;
  my @search = (
    $params->{config_file},
    File::Spec->catfile($app->home,join($PERIOD, $app->moniker, $app->mode, 'conf')),
    File::Spec->catfile($app->home,join($PERIOD, $app->moniker,             'conf'))
  );
  foreach my $conf_file (grep {$_} @search) {
    if(defined($conf_file) && -e $conf_file) {
      $app->log->info("Initializing Concert::Config from '$conf_file'");
      $conf = do $conf_file; last;
    }
  }
  unless(defined($conf)) {
    $conf = {};
    $app->log->error("Initializing Concert::Config with empty configuration");
  }
  my $def_file = File::Spec->catfile($app->home,join($PERIOD, $app->moniker, qw(conf def)));

  $app->helper(
    conf => sub {
      state $config = Concert::Config->new(
         _conf => $conf,
         _def  => do $def_file
      );
    }
  );
}

1;
