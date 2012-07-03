package Tapper::MCP::Scheduler::ObjectBuilder;

use strict;
use warnings;

use MooseX::Singleton;
use Tapper::Model 'model';

use Tapper::MCP::Scheduler::Job;
use Tapper::MCP::Scheduler::Host;
use Tapper::MCP::Scheduler::Queue;

has jobs   => (is => 'rw', isa => 'HashRef', default => sub {{}});
has hosts  => (is => 'rw', isa => 'HashRef', default => sub {{}});
has queues => (is => 'rw', isa => 'HashRef', default => sub {{}});

sub new_job
{
        my ($self, %values) = @_;

        if (my $existing_job = $self->jobs->{$values{id}}) {
                return $existing_job;
        } else {
                my $new_job = Tapper::MCP::Scheduler::Job->new(%values);
                $self->jobs->{$new_job->id} = $new_job;
                return $new_job;
        }
}

sub new_host
{
        my ($self, %values) = @_;
        if (my $existing_host = $self->hosts->{$values{id}}) {
                return $existing_host;
        } else {
                my $new_host = Tapper::MCP::Scheduler::Host->new(%values);
                $self->hosts->{$new_host->id} = $new_host;
                return $new_host;
        }
}

sub new_queue
{
        my ($self, %values) = @_;
        if (not $values{id}) {
                use Devel::Backtrace;
                my $backtrace = Devel::Backtrace->new(-start=>2, -format => '%I. %s');
                print STDERR $backtrace;
                exit -1;

        }
        if (my $existing_queue = $self->queues->{$values{id}}) {
                return $existing_queue;
        } else {
                my $new_queue = Tapper::MCP::Scheduler::Queue->new(%values);
                $self->queues->{$new_queue->id} = $new_queue;
                return $new_queue;
        }
}

sub clear
{
        my $self = shift;
        $self->jobs({});
        $self->hosts({});
        $self->queues({});
        return;
}



1;

=head1 NAME

Tapper::MCP::Scheduler::ObjectBuilder - Creates objects for the Tapper Scheduler and makes


=head1 SYNOPSIS

Abstraction for the database table testrun_scheduling.


=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>


=head1 BUGS

None.


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

