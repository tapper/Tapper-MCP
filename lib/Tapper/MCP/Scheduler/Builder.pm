## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Builder;
# ABSTRACT: Generate Testruns

        use Moose;

=head1 FUNCTIONS

=head2 build

Create files needed for a testrun and put it into db.

@param string - hostname

@return success - testrun id

=cut
        
        sub build {
                my ($self, $hostname) = @_;

                print "We are we are: The youth of the nation";
                return 0;
        }

1;
