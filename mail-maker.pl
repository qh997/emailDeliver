#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Getopt::Long;

my $temp_root = '/etc/mail-deliver/template';
my $tmp_root = '/tmp/mail-deliver/';
my $mail_pusher = '/usr/local/bin/mail-pusher.pl';

my $start = undef;
my $finish = 0;
my $id = '';
GetOptions (
	's|start=s' => \$start,
	'f|finish' => \$finish,
	'i|id=s' => \$id,
) or die "Error in command line arguments\n";

`mkdir -p $tmp_root`;

if ($id && ! -e "$tmp_root/$id") {
	say "ERROR - ID `$id' doesn't exists.";
	exit 1;
}

if (defined $start) {
	if (-e "$temp_root/$start.template") {
		$id = `date +'%s'`;
		chomp $id;
		`cp "$temp_root/$start.template" "$tmp_root/$id"`;
		say $id;
	}
	else {
		say "ERROR - Unknow template `$start'";
		exit 1;
	}
}

if (!$id) {
	say "ERROR - Use -i|--id to specify ID.";
	exit 1;
}

if (@ARGV) {
	open my $ifh, "< $tmp_root/$id";
	my @draft = <$ifh>;
	close $ifh;

	foreach my $arg (@ARGV) {
		chomp $arg;
		if ($arg =~ m/(.*?)=(.*)/) {
			my $para = $1;
			my $value = $2;

			if (replace_draft(\@draft, $para, $value)) {
				say "ERROR - No such parameter `$para'";
				exit 1;
			}
		}
		else {
			say "ERROR - Wrong format for `$arg'";
			exit 1;
		}
	}

	open my $ofh, "> $tmp_root/$id";
	print $ofh join '', @draft;
	close $ofh;
}

if ($finish) {
	system("$mail_pusher < $tmp_root/$id");
}

sub replace_draft {
	my $_draft = shift;
	my $_p = shift;
	my $_v = shift;

	my $nofound = 1;
	foreach my $line (@$_draft) {
		if ($line =~ s/<$_p>/$_v/g) {
			$nofound = 0;
		}
	}

	return $nofound;
}
