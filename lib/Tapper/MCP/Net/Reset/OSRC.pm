package Tapper::MCP::Net::Reset::OSRC;

use strict;
use warnings;

use File::Temp;
use File::Spec;
 
sub reset_host
{
        my ($mcpnet, $host, $options) = @_;

        # essentiall simply call osrc_rst
        #
        # but additionally watch opentftp logs whether the host really
        # requested it's install config so we know the RESET worked!
        
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
                # store tftp log before reset
                $mcpnet->log_and_exec("cp $log $logbefore");

                $mcpnet->log->info("(try $try: $host) $cmd");
                ($error, $retval) = $mcpnet->log_and_exec($cmd);

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
        }
        return ($error, $retval);
}

1;

__END__

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

=head2 reset_host ($mcpnet, $host, $options)

The primary plugin function.

It is called with the Tapper::MCP::Net object (for Tapper logging),
the hostname to reset and the options from the config file.
