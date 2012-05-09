package Tapper::MCP;
# ABSTRACT: Tapper - Central master control program of Tapper automation

use warnings;
use strict;

use Tapper::Config;
use Moose;

extends 'Tapper::Base';

sub cfg
{
        my ($self) = @_;
        return Tapper::Config->subconfig();
}

1;
