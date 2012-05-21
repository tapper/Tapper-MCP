package Tapper::MCP::Net::Reset::DoNothing;

use strict;
use warnings;

use Moose;
extends 'Tapper::Base';


sub reset_host
{
        my ($self, $host, $options) = @_;

        $self->log->info("Just a fake-reboot, not real.");
        my ($error, $retval) = (1, "$host"."-".$options->{some_dummy_return_message});
        return ($error, $retval);
}

1;
