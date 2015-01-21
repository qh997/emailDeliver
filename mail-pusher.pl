#!/usr/bin/perl
use 5.010;
use warnings;
use strict;
use IO::Socket;
use IO::Select;
use MIME::Base64;

my $mail_str = '';
if (@ARGV) {
	open my $fh, '< '.$ARGV[0] or die "$@\n";
	$mail_str = join '', <$fh>;
	close $fh;
}
else {
	$mail_str = join '', <STDIN>;
}

my $socket = IO::Socket::INET->new(
	PeerAddr => '10.1.42.209',
	PeerPort => '9527',
	Type => SOCK_STREAM,
	Proto => "tcp",
) or die "Can not connection to server.\n$@";

print decode_base64(talk($socket, $mail_str));
print "\n";

$socket->close() or die "Close Socket failed.$@";

sub talk {
	my $skt = shift;
	my $str = shift;

	$skt->send(encode_base64($str, '')."\n", 0);
	$skt->autoflush(1);
}
