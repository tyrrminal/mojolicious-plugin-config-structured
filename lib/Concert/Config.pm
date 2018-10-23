package Concert::Config;
use Moose;
use Moose::Util::TypeConstraints;

use Data::DPath qw(dpath);

Readonly::Scalar our $CONF_FROM_ENV   => q(env);
Readonly::Scalar our $CONF_FROM_FILE  => q(conf);

#
# This instance's base path (e.g., /db)
#   Recursively constucted through re-instantiation of non-leaf config nodes
#
has '_base' => (
  is => 'ro',
  isa => 'Str',
  default => ''
);

#
# The configuration definition, from the .conf.def file
#
has '_def' => (
  is => 'ro',
  isa => 'HashRef',
  required => $TRUE
);

#
# The file-based configuration (e.g., $moniker.conf contents)
#
has '_conf' => (
  is => 'ro',
  isa => 'HashRef',
  required => $TRUE
);

#
# Toggle of whether to prefer the configuraiton file or ENV variables
#   Can be overridden by specific configuration nodes in the configuration definition
# 
has '_priority' => (
  is => 'rw',
  isa => enum([$CONF_FROM_ENV,$CONF_FROM_FILE]),
  default => $CONF_FROM_ENV
);

#
# Implement method-based handling of configuratoon directive by dpath
#
sub AUTOLOAD {
  my ($self, @params) = @_;
  our $AUTOLOAD;
  if($AUTOLOAD =~ /::([[:alpha:]]\w+)$/) {
    my $path = join('/', $self->_base, $1); # construct the new directive path by concatenating with our base
    if(my ($el) = @{dpath($path)->matchr($self->_def)}) { # search the config definition for the new directive path
      if(exists($el->{isa})) { # Detect whether the resulting node is a branch or leaf node (leaf nodes are required to have an "isa" attribute, though we don't (yet) perform type constraint validation)
        my @val;
        push(@val, @{dpath($path)->matchr($self->_conf)}); # if the configuration is set in the .conf file, add it to our possible value list (if it's not, this is a noop)
        push(@val, $ENV{$el->{env}}) if(defined($el->{env})); # if the definition sets an env var name, add its value to our possible value list
        @val = grep {defined} @val; # strip any undefs from the list

        my $priority = $self->_priority; 
        $priority = $el->{priority} if(defined($el->{priority})); #override the global priority with the directive definition's priority, if it's set
        return ($priority eq $CONF_FROM_ENV) ? pop(@val) : shift(@val); # if the priority is Environment, grab from the end of the list, otherwise, take from the front. This way if one or the other value is not populated, we'll still get the value we do have
      } else {
        return __PACKAGE__->new(_conf => $self->_conf, _base => $path, _def => $self->_def, _priority => $self->_priority); # if it's a branch node, return a new Config instance with a new base location, for method chaining (e.g., config->db->pass)
      }
    }
    die(qq{Undefined configuration path "$path"}); # while the configuration itself is not required to exist in either the configuration file or env var, we do require that a definition for it exists in the .conf.def
  }
  die(qq{Invalid configuration path}); # We hide all dynamic paths beginning with an underscore, reserving them for future meta-use in the .conf.def file
}

1;
