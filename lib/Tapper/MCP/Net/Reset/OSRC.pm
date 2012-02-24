package Tapper::MCP::Net::Reset::OSRC;

use strict;
use warnings;

use File::Temp;
use File::Spec;
use Net::OpenSSH;


=head1 NAME

Tapper::MCP::Net::Reset::OSRC - Reset via OSRC reset script

=head1 DESCRIPTION

This is a plugin for Tapper.

It provides resetting a machine via the OSRC reset script (an internal
tool).

=head1

To use it add the following config to your Tapper config file:

 reset_plugin: OSRC
 reset_plugin_options:

This configures Tapper MCP to use the OSRC plugin for reset and
leaves configuration empty.

=head1 FUNCTIONS

=head2 ssh_reboot

Try to reboot the remote system using ssh. In case this is not possible
an info message is written to the log.

@param string - host name

@return success - true
@return error   - false

=cut

sub ssh_reboot
{
        my ($mcpnet, $host, $options) = @_;
        $mcpnet->log->info("Try reboot '$host' via ssh");
        my $ssh = Net::OpenSSH->new(
                                    host=>$host,
                                    user=>'root',
                                    password=>$options->{testmachine_password},
                                    timeout=> '10',
                                    kill_ssh_on_timeout => 1,
                                    master_opts => [ -o => 'StrictHostKeyChecking=no',
                                                     -o => 'UserKnownHostsFile=/dev/null' ]);
        if ($ssh->error) {
                $mcpnet->log->info("Couldn't establish SSH connection: ". $ssh->error);
                return;
        }

        my $output;
        $output = $ssh->capture("reboot");

        if ($ssh->error) {
                $mcpnet->log->info("Can not reboot $host with SSH: $output");
                return;
        } else {
                return 1;
        }
}

=head2 reset_host

The primary plugin function, does the actual resetting. Try hard to make
sure the resetting actually succeeds. This means the function calls the
resetters (SSH and osrc_reset) and watched TFTPd logs to find out
whether the reset really worked.


@param Tapper::MCP::Net object - needed to give plugin access to Tapper Base functions
@param string   - hostname
@param hash ref - options

@return success - (0, ignore)
@return error   - (1, error string)

=cut
 
sub reset_host
{
        my ($mcpnet, $host, $options) = @_;

        $mcpnet->log->info("Try reboot '$host' via SSH");

        return (0, undef) if ssh_reboot($mcpnet, $host, $options);
        
        $mcpnet->log->info("Try reboot '$host' via reset switch");
        my $cmd = "/public/bin/osrc_rst_no_menu -f $host";
        my ($error, $retval);

        # several possible TFTP daemons and logs, choose the one with latest write access
        my $log = `ls -1rt /opt/opentftp/log/opentftp*.log /var/log/atftpd.log | tail -1`; chomp $log;

        my $logbefore =
         File::Temp
                  ->new(TEMPLATE => "osrcreset-tftplog-before-XXXXXX", DIR => File::Spec->tmpdir)
                   ->filename;
 TRY:
        for my $try (1..3)
        {
                # watch tftp log for $host entries which signal successful reset
                for my $check (1..18) # 18 * 10sec sleep == 180sec per try
                {
                        # check every 10 seconds to early catch success
                        sleep 10;
                        $mcpnet->log->info("(try $try: $host, check $check)");
                        if (system("diff -u $logbefore $log | grep -q '+.*$host'") == 0) {
                                $mcpnet->log->info("(try $try: $host) reset succeeded");
                                last TRY;
                        }
                }
                # store tftp log before reset
                $mcpnet->log_and_exec("cp $log $logbefore");

                $mcpnet->log->info("(try $try: $host) $cmd");
                ($error, $retval) = $mcpnet->log_and_exec($cmd);
        }
        return ($error, $retval);
}

1;

__END__

