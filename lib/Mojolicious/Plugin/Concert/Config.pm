package Mojolicious::Plugin::Concert::Config;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;

  $app->helper(
    conf => sub {
      my $home = Mojo::Home->new;
      $home->detect;
      my $f = File::Spec->catfile($home,$app->moniker.".conf");
      state $config = Concert::Config->new(
        _conf => do $f,
         _def => do "$f.def"
      );
    }
  );
}

1;
