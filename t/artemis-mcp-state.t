use strict;
use warnings;
use 5.010;

use Test::More;
use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Artemis::Model 'model';


BEGIN{use_ok('Artemis::MCP::State')}



# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
my $state = Artemis::MCP::State->new(23);
isa_ok($state, 'Artemis::MCP::State');


sub message_create
{
        my ($data) = @_;
        my $message = model('TestrunDB')->resultset('Message')->new
                  ({
                   message => $data,
                   testrun_id => 23,
                   });
        $message->insert;
        return $message;
}
        
        

my $timeout_span = 1;


sub initial_state
{

        {'current_state' => 'started',
          'install' => {
                        'timeout_install_span' => '7200',
                        'timeout_boot_span' => $timeout_span,
                        'timeout_current_date' => undef
                       },
                         'prcs' => [
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 5, 2],
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 5, 2],
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                     {
                                      'timeout_testprograms_span' => [ 5, 2],
                                      'timeout_boot_span' => $timeout_span,
                                      'timeout_current_date' => undef,
                                      'results' => [],
                                      'current_state' => 'preload'
                                    }
                                   ],
                                     'results' => []
                             }
}

my ($retval, $timeout);

$retval = $state->state_init(initial_state());
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));

($retval, $timeout) = $state->update_state(message_create({state => 'start-install'}));
is($retval, 0, 'start-install handled');
$retval = $state->state_details->current_state();
is($retval, 'installing', 'Current state at installation');

($retval, $timeout) = $state->update_state(message_create({state => 'end-install'}));
is($retval, 0, 'end-install handled');
$retval = $state->state_details->current_state();
is($retval, 'reboot_test', 'Current state after installation');

($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 1}));
is($retval, 0, '1. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 1. guest started');

($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 2}));
is($retval, 0, '2. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 2. guest started');

($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 3}));
is($retval, 0, '3. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 3. guest started');


($retval, $timeout) = $state->update_state(message_create({ state => 'start-testing', prc_number => 0}));
is($retval, 0, '3. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 3. guest started');


done_testing();