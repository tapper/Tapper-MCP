package Tapper::MCP::Plugin::Test::All;

use strict;
use warnings;
use Moose::Role;

=head2 console_start

Empty function for console_start

=cut

sub console_start {
        my ($self) = @_;
        return 'test';
}

=head2 console_stop

Empty function for console_stop

=cut

sub console_stop {
        my ($self) = @_;
        return 'test';
}


1;
