#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use IO::Socket;
use MIME::Base64;

my $tmp_path = '/tmp/mail-deliver';

say "$0 start.";

my $main_socket = IO::Socket::INET->new(
	'Localhost' => 'localhost',
	'LocalPort' => '9527',
	'Proto'     => 'tcp',
	'Listen'    => '5',
	'Reuse'     => '1',
) or die "Could not start : $!";

while (my $new_socket = $main_socket->accept()) {
	my $pid = fork;
	if (defined $pid && $pid == 0) {
		start($new_socket);

		exit 0;
	}

	wait();
}

close $main_socket;

sub start {
	my $socket = shift;
	
	print '*** FROM '.$socket->peerhost()."\n";
	my $id = $socket->peerhost();
	$id .= '-';
	$id .= `date +'%s'`;
	chomp $id;
	`mkdir -p $tmp_path`;
	$id = "$tmp_path/$id";

	open my $fh, "> $id";
	while (defined (my $buf = <$socket>)) {
		chomp $buf;
		print $fh decode_base64($buf);
	}
	close $fh;

	foreach (`mail-sender.pl $id 2>&1`) {
		print $_;
	}

	print '*** DONE '.$socket->peerhost()."\n";
}
