package Tapper::MCP::Daemon;

use 5.010;

use strict;
use warnings;

use Tapper::MCP::Master;
use Moose;
use Tapper::Config;
use Log::Log4perl;

with 'MooseX::Daemonize';


after start => sub {
                    my $self = shift;

                    return unless $self->is_daemon;

                    my $daemon = Tapper::MCP::Master->new()->run;
                   };

=head2 run

Frontend to subcommands: start, status, restart, stop.

=cut

sub run
{
        my $self = shift;

        my ($command) = @ARGV ? @ARGV : @_;
        return unless $command && grep /^$command$/, qw(start status restart stop);
        $self->$command;
        say $self->status_message;
}
;


1;
