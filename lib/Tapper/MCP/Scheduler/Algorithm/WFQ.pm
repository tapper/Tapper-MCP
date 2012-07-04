## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Algorithm::WFQ;
# ABSTRACT: Scheduling algorithm "Weighted Fair Queueing"

        use Moose::Role;
        use 5.010;

        sub get_virtual_finishing_time {
                my ($self, $queue) = @_;

                my $prio = $queue->priority || 1;
                return ($queue->runcount + 1.0) / $prio;
        }


        sub lookup_next_queue {
                my ($self, $queues) = @_;

                my $vft;
                my $queue;

                foreach my $q (values %$queues)
                {
                        my $this_vft;
                        next if not $q->priority;

                        $this_vft = $self->get_virtual_finishing_time($q);

                        if (not defined $vft)
                        {
                                $vft   = $this_vft;
                                $queue = $q;
                        }
                        elsif ($vft > $this_vft)
                        {
                                $vft   = $this_vft;
                                $queue = $q;
                        }
                }
                return $queue;
        }



        sub get_next_queue
        {
                my ($self, $queues) = @_;

                my $vft;
                my $queue = $self->lookup_next_queue( $queues);
                $self->update_queue($queue);
                return $queue;
        }

        sub update_queue {
                my ($self, $q) = @_;
                $q->runcount ( $q->runcount + 1 );
                if ($q->can('update')) {
                        $q->update;
                }
        }

1;

__END__

=head1 SYNOPSIS

Implements weighted fair queueing scheduling algorithm.

=head1 FUNCTIONS

=head2 get_virtual_finishing_time

Return the virtual finishing time of a given client

@param string - client

@return success - virtual time
@return error   - error string

head2 get_next_queue

Evaluate which client has to be scheduled next.

@return success - client name;
