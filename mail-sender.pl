#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use MIME::Base64;
use Net::SMTP_auth;

my $mail_str = '';
if (@ARGV) {
	open my $fh, '< '.$ARGV[0] or die "$@\n";
	$mail_str = join '', <$fh>;
	close $fh;
}
else {
	$mail_str = join '', <STDIN>;
}

my %conf = get_config('config.conf');

my %email = (
	to => [],
	cc => [],
	attach => [],
	subject => '',
	body => '',
);
get_email($mail_str, \%email);

my $mail_from = $conf{'smtp-server'};
$mail_from =~ s{^.*?\.}{\@};
$mail_from = $conf{'smtp-user'}.$mail_from;

my $smtp = Net::SMTP_auth->new(
    Host => $conf{'smtp-server'},
    Port => $conf{'smtp-port'},
    Hello => $conf{'smtp-server'},
    Debug => 1,
) or die 'Cannot connect '.$conf{'smtp-server'}.':'.$conf{'smtp-port'}." $!\n";

$smtp->auth('NTLM', $conf{'smtp-user'}, $conf{'smtp-passwd'})
	or die "Can't authenticate: $!\n";
$smtp->mail($mail_from);
$smtp->to($mail_from);
grep {$smtp->to($_);} @{$email{to}};
grep {$smtp->to($_);} @{$email{cc}};
$smtp->data();

$smtp->datasend("Content-Type: multipart/mixed; boundary=a; charset=utf-8\n");
$smtp->datasend("From: $mail_from\n");
grep {$smtp->datasend("To: ".$_."\n");} @{$email{to}};
grep {$smtp->datasend("Cc: ".$_."\n");} @{$email{cc}};
$smtp->datasend("Subject: $email{subject}\n\n");

$smtp -> datasend("--a\n\n");
$smtp -> datasend($email{body});
$smtp -> datasend("\n");

$smtp -> datasend("\n");
$smtp -> datasend("--a--\n");
$smtp -> dataend();
$smtp -> quit();

sub get_config {
	my $config_file = shift;

	open my $CF, "< $config_file" or die 'cannot open file : '.$config_file;
	my @file_content = <$CF>;
	close $CF;

	my %configs;
	foreach my $line (@file_content) {
		chomp $line;

		next if $line =~ m/^\s*#/;
		next if $line !~ m/=/;

		if ($line =~ m{^\s*(.*?)\s*=\s*(.*)\s*$}) {
			$configs{$1} = $2;
		}
	}

	return %configs;
}

sub get_email {
	my $draft_str = shift;
	my $_mail = shift;

	my @file_content = split "\n", $draft_str;

	foreach my $line (@file_content) {
		chomp $line;

		if ($line =~ m/^#/) {
			next;
		}
		elsif ($line =~ m/^to:(.*)/) {
			push(@{$_mail->{to}}, grep(s/^\s*(\S+)\s*$/$1/, split(/[,;\s]/, $1)));
		}
		elsif ($line =~ m/^cc:(.*)/) {
			push(@{$_mail->{cc}}, grep(s/^\s*(\S+)\s*$/$1/, split(/[,;\s]/, $1)));
		}
		elsif ($line =~ m/^attach:(.*)/) {
			push(@{$_mail->{attach}}, grep(s/^\s*(\S+)\s*$/$1/, split(/[,;\s]/, $1)));
		}
		elsif ($line =~ m/^subject:(.*)/) {
			$_mail->{subject} = $1;
			$_mail->{subject} =~ s/^\s+//;
			$_mail->{subject} =~ s/\s+$//;
		}
		else {
			$_mail->{body} .= $line."\n";
		}
	}
}
