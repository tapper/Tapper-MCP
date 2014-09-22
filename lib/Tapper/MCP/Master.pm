## no critic (RequireUseStrict)
package Tapper::MCP::Master;
# ABSTRACT: Wait for new testruns and start a new child when needed

        use 5.010;
        use Moose;
        use parent "Tapper::MCP";
        use Devel::Backtrace;
        use File::Path;
        use Log::Log4perl;
        use POSIX ":sys_wait_h";
        use Try::Tiny;
        use UNIVERSAL;
        use constant HARNESS_ACTIVE => $ENV{HARNESS_ACTIVE};

        use Tapper::Cmd::Testrun;
        use Tapper::MCP::Child;
        use Tapper::MCP::Net;
        use Tapper::MCP::Scheduler::Controller;
        use Tapper::Model 'model';

=head1 SYNOPSIS

 use Tapper::MCP::Master;
 my $mcp = Tapper::MCP::Master->new();
 $mcp->run();

=head1 Attributes


=head2 dead_child

Number of pending dead child processes.

=cut

        has dead_child   => (is => 'rw', default => 0);

=head2 child

Contains all information about all child processes.

=cut

        has child        => (is => 'rw', isa => 'HashRef', default => sub {{}});

=head2

Associated Scheduler object.

=cut

        has scheduler    => (is => 'rw', isa => 'Tapper::MCP::Scheduler::Controller');

=head1 FUNCTIONS

=cut

sub BUILD
{
        my $self = shift;
        $self->scheduler(Tapper::MCP::Scheduler::Controller->new());
}


=head2 cleanup_output_dir

Clean up the output directory for this test.

@param int - testrun id

=cut

sub cleanup_output_dir
{
        my ($self, $testrun_id) = @_;
        my $path = $self->cfg->{paths}{output_dir}."/$testrun_id";
        File::Path::rmtree($path);
}

=head2 set_interrupt_handlers

Set interrupt handlers for important signals. No parameters, no return values.

@return success - 0

=cut

        sub set_interrupt_handlers
        {
                my ($self) = @_;
                $SIG{CHLD} = sub {
                        $self->dead_child($self->dead_child + 1);
                };

                # give me a stack trace when ^C
                $SIG{INT} = sub {
                        $SIG{INT}  = 'IGNORE'; # make handler reentrant, don't handle signal twice

                        # stop all children
                        $SIG{CHLD} = 'IGNORE';
                        foreach my $pid (keys %{$self->child}) {
                                kill 15, $pid;
                        }

                        my $backtrace = Devel::Backtrace->new(-start=>2, -format => '%I. %s');
                        print $backtrace;

                        exit -1;
                };
                return 0;
        }

=head2 handle_dead_children

Each test run is handled by a child process. All information needed for
communication with this child process is kept in $self->child. Reset all these
information when the test run is finished and the child process ends.

=cut

        sub handle_dead_children
        {
                my ($self) = @_;
        CHILD: while ($self->dead_child) {
                        $self->log->debug("Number of dead children is ".$self->dead_child);
                        my $dead_pid = waitpid(-1, WNOHANG);  # don't use wait(); qx() sends a SIGCHLD and increases $self->deadchild, but wait() for the return value and thus our wait would block

                        $self->dead_child($self->dead_child - 1);
                        next if not $self->child->{$dead_pid}; # sig raised by qx()

                        my $host = $self->child->{$dead_pid}->{job}->host->name;
                        $self->log->debug("test on $host finished");
                        $self->scheduler->mark_job_as_finished( $self->child->{$dead_pid}->{job} );
                        delete $self->child->{$dead_pid};
                }
        }


=head2 notify_event

Inform the notification framework that an event occured in MCP.

@param string - event name
@param hash ref - message

=cut

        sub notify_event
        {
                my ($self, $event, $message) = @_;
                try
                {
                        my $new_event = model('TestrunDB')->resultset('NotificationEvent')->new({type => $event,
                                                                                                 message => $message,
                                                                                                });
                        $new_event->insert();
                } catch {
                        $self->log->error("Unable notify user of event $event: $_");
                };

                return;
        }


=head2 run_due_tests

Run the tests that are due.

@param TestrunScheduling - job to run
@param boolean - are we in revive mode?

@retval success - 0
@retval error   - error string

=cut

        sub run_due_tests
        {
                my ($self, $job, $revive) = @_;
                $self->log->debug('run_due_test');

                my $system = $job->host->name;
                my $id = $job->testrun->id;

                $self->log->info("start testrun $id on $system");
                # check if this system is already active, just for error handling

                $self->scheduler->mark_job_as_running($job) unless $revive;

                my $pid = fork();
                die "fork failed: $!" if (not defined $pid);

                # hello child
                if ($pid == 0) {

                        # don't leave creating output dir to later workers (Installer/PRC)
                        $self->makedir($self->cfg->{paths}{output_dir}."/$id");

                        my $child = Tapper::MCP::Child->new( $id );
                        my $retval;
                        eval {
                                $retval = $child->runtest_handling( $revive );
                        };
                        $retval = $@ if $@;

                        $self->notify_event('testrun_finished', {testrun_id => $id});
                        $child->testrun_post_process();
                        $self->cleanup_output_dir($id);
                        if ( ($retval or $child->rerun) and $job->testrun->rerun_on_error) {
                                my $cmd  = Tapper::Cmd::Testrun->new();
                                my $new_id;
                                eval {
                                        my $or_new_testrun = $cmd->rerun($id, {rerun_on_error => $job->testrun->rerun_on_error - 1});
                                           $new_id         = $or_new_testrun->id;
                                };
                                if ($@) {
                                        $self->log->error($@);
                                } else {
                                        $self->log->debug("Restarted testrun $id with new id $new_id because ".
                                                          "an error occurred and rerun_on_error was ".
                                                          $job->testrun->rerun_on_error);
                                }
                        }
                        if ($retval) {
                                $self->log->error("Testrun $id ($system) error occurred: $retval");
                        } else {
                                $self->log->info("Testrun $id ($system) finished successfully");
                        }
                        exit 0;
                } else {

                        $self->child->{"$pid"}->{test_run} = $id;
                        $self->child->{"$pid"}->{job}      = $job;
                }
                return 0;

        }


=head2 runloop

Main loop of this module. Checks for new tests and runs them. The looping
itself is put outside of function to allow testing.

=cut

        sub runloop
        {
                my ($self, $lastrun) = @_;
                my $timeout          = $lastrun + $self->cfg->{times}{poll_intervall} - time();
                $timeout = 0 if $timeout < 0;

                sleep $timeout;
                $self->handle_dead_children() if $self->dead_child;


                my @jobs;
                my $pid = open(my $fh, "-|");
                if ($pid == 0) {
                        my @jobs = $self->scheduler->get_next_job;
                        print join ",", map {$_->id} @jobs;
                        exit;
                } else {
                        my $ids_joined = <$fh>;
                        {
                                no warnings 'uninitialized'; # we may not have ids_joined when no test is due
                                foreach my $next_id (split ',', $ids_joined) {
                                        push @jobs, model('TestrunDB')->resultset('TestrunScheduling')->find($next_id);
                                }
                        }
                }

                foreach my $job (@jobs) {
                        $self->run_due_tests($job);
                }
                $lastrun = time();

                return $lastrun;
        }


=head2 prepare_server

Create communication data structures used in MCP.

@return

=cut

        sub prepare_server
        {
                my ($self) = @_;
                Log::Log4perl->init($self->cfg->{files}{log4perl_cfg});

                return 0;
        }

=head2 revive_children

Restart the children that were running before MCP was shut
down/crashed. The function expects no parameters and has no return
values.

=cut

sub revive_children
{
        my ($self) = @_;
        my $jobs = model->resultset('TestrunScheduling')->running;
        foreach my $job ($jobs->all) {
                $self->run_due_tests($job, "revive");
        }
}



=head2 run

Set up all needed data structures then wait for new tests.

=cut

        sub run
        {
                my ($self) = @_;
                $self->set_interrupt_handlers();
                $self->prepare_server();
                $self->revive_children();
                my $lastrun = time();
                while (1) {
                         $lastrun = $self->runloop($lastrun);
                }

        }

1;
