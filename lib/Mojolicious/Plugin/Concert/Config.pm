package Mojolicious::Plugin::Concert::Config;

# ABSTRACT: Mojolicious Plugin for Concert::Config

use Mojo::Base 'Mojolicious::Plugin';
use Concert::Config;
use Concert::Constants;

sub register {
  my ($self, $app) = @_;

  $app->helper(
    conf => sub {
      state $config = Concert::Config->new(
         _conf => do File::Spec->catfile($app->home,join($PERIOD, $app->moniker, $app->mode, qw(conf))),
         _def  => do File::Spec->catfile($app->home,join($PERIOD, $app->moniker, qw(conf def)))
      );
    }
  );
}

1;
