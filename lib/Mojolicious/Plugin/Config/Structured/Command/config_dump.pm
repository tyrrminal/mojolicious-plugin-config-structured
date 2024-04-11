package Mojolicious::Plugin::Config::Structured::Command::config_dump;
use v5.26;
use warnings;

=pod

=head1 SYNOPSIS

  Usage: <APP> config-dump [--[no]formatted] [--verbose]

  Options:
    --[no]formatted     Use ANSI terminal formatting [Default: on]

=cut

use Mojo::Base 'Mojolicious::Command';
use Getopt::Long qw(GetOptionsFromArray);

use JSON qw(encode_json);
use List::Util qw(max);
use Scalar::Util qw(looks_like_number);
use Term::ANSIColor;

use experimental qw(signatures);

has description => 'Display Config::Structured configuration';
has usage       => sub ($self) { $self->extract_usage };

sub stringify_value($value) {
  return 'undef'             unless(defined($value));
  return encode_json($value) if(ref($value));
  return $value              if(looks_like_number($value));
  return qq{"$value"};
}

sub dump_node($conf, %params) {
  my $format          = $params{format}    // 1;
  my $max_depth       = $params{max_depth};
  my $depth           = $params{depth}     // 0;
  my $allow_sensitive = $params{sensitive} // 0;

  my $indent = '  'x$depth;
  my @lines = map { [$_, stringify_value($conf->$_($allow_sensitive))] } sort($conf->get_node->{leaves}->@*);
  my $m = max map { length($_->[0]) } @lines;
  printf("%s%-${m}s%s%s\n", $indent, $_->[0], ' => ', $_->[1]) foreach(@lines);
  foreach my $f (sort($conf->get_node->{branches}->@*)) {
    print $indent . $f;
    if(!defined($max_depth) || $depth < $max_depth) {
      say ' =>';
      dump_node($conf->$f, format => $format, max_depth => $max_depth, depth => $depth + 1, sensitive => $allow_sensitive)
    } else {
      say "";
    }
  }
}

sub run ($self, @args) {
  my ($format, $verbose, $depth, $path, $sensitive) = (1,0, undef, '/', 0);
  GetOptionsFromArray(\@args,
    'format!' => \$format,
    'depth=s' => sub($v) { $depth = $v - 1 },
    'path=s'  => \$path,
    'reveal-sensitive' => \$sensitive,
  );
  my $conf = $self->app->conf;
  my @path = split(q{/}, $path);
  shift(@path);
  $conf = $conf->$_ foreach(@path);
    dump_node($conf, format => $format, max_depth => $depth, sensitive => $sensitive)
}

1;
