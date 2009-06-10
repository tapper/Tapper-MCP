use MooseX::Declare;

    
class Artemis::MCP::Scheduler::TestRequest {

=head1 NAME
        
   Artemis::MCP::Scheduler::TestRequest - Object that handles requesting new tests

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

  artemist-testrun new --request-feature='mem =< 8000'

=cut

=head2 features

List of features that a possible host for this test request should have. May be empty.

=cut 

        has requested_features => (is => 'rw', isa => 'ArrayRef');


=head2 

List of possible hosts for this test request. May be empty. 

=cut 

        has hostnames => (is => 'rw', isa => 'ArrayRef');

=head2

Name of the queue this test request goes into. Default is 'Adhoc'

=cut 

        has queue => (is => 'rw', default => 'Adhoc');

=head2

Use this host for the test request. Will be set when the feature and host list
is evaluated.

=cut

        has on_host => (is => 'rw', isa => 'Artemis::MCP::Scheduler::Host');

=head1 FUNCTIONS

=head2 fits

Checks whether this testrequests host or feature list fits any of the free
hosts.

@param ArrayRef - list of free hosts

@return success - this object with only the fitting host in the hostnames list
@return no fit  - 0

=cut

        method fits(ArrayRef $free_hosts) {
                $self->on_host($free_hosts->[0];
                return $self;
        }

}
{
        # just for CPAN
        package Artemis::MCP::Scheduler::TestRequest;
        our $VERSION = '0.01';
}


=head1 AUTHOR

Maik Hentsche, C<< <maik.hentsche at amd.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Maik Hentsche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
