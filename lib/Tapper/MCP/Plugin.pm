package Tapper::MCP::Plugin;

use strict;
use warnings;

use Moose::Role;

use Class::Load 'load_class';

sub BUILD {
        my ($self, $config) = @_;
        if (ref($config) eq 'HASH' and
            $config->{plugin_conf}
           ) {
                my $plug_conf = $config->{plugin_conf};
                foreach my $task (keys %$plug_conf) {
                        my $role = "Tapper::MCP::Plugin";
                        $role   .= "::$task";
                        $role   .= "::".$plug_conf->{$task};
                        load_class $role;
                        Tapper::MCP::Plugin::Test::All->meta->apply($self);
                }
        }
}


=head1 NAME

Tapper::MCP::Plugin - Plugin loader class for Tapper::MCP plugins

=head1 DESCRIPTION

This is the plugin loader for Tapper::MCP plugins. There are many parts
of MCP that may be different for different users. This includes console
handling, reset handling or post processing for test
runs. Tapper::MCP plugins allow users to add their own functions for
these. This is the default plugin.


To use it add the following config to your Tapper config file:

mcp_plugin:
  Console: ConsoleRole
  Reset: ResetRole

This will load the roles Tapper::MCP::Plugin::Console::ConsoleRole and
Tapper::MCP::Plugin::Reset::ResetRole.

The keys in the config are case sensitive. Also, even though
console and reset may be natural choices for the respective role
namespaces they are not enforced.

=head1 FUNCTIONS

=head2 testrun_post_process

Empty function for testrun_post_process

=cut

sub testrun_post_process {
        my ($self) = @_;
}

=head2 console_start

Empty function for console_start

=cut

sub console_start {
        my ($self) = @_;
        return 0;
}

=head2 console_stop

Empty function for console_stop

=cut

sub console_stop {
        my ($self) = @_;
        return 0;
}

=head2 host_start

Empty function for host_start

=cut

sub host_start {
        my ($self) = @_;
        return 0;
}




1;
