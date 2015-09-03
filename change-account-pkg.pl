#!/usr/bin/perl
#
# Change the user current plan for another
#
use strict;
use warnings;
use URI::Escape;
use XML::Simple;
use LWP::UserAgent;
use LWP::Protocol::https;
use MIME::Base64;

my $help;
my $old_plan = '';
my $new_plan = '';
my $username = '';
my $verbose = '';

usage() if ( @ARGV < 1 or
  ! GetOptions (
      'help|?' => \$help,
      'new_plan=s' => \$new_plan,
      'old_plan=s' => \$old_plan,
      'username=s' => \$username,
      'verbose' => \$verbose,
    )
  or defined $help );

die "old plan must not contain url encoding\n"
  if($new_plan  =~ /\%/);

die "old plan must not contain url encoding\n"
  if($old_plan  =~ /\%/);

my ($user, $pass);
open (FILE, '/root/.cpanelpwd');
while (<FILE>) {
  chomp;
  ($user, $pass) = split(" ");
}
close (FILE);

$new_plan = uri_escape($new_plan);

my $summary_url = "xml-api/accountsummary?api.version=1&user=$username";
my $data = whm_connect($user, $pass, $summary_url);

if ($data->{data}->{acct}->{plan} eq $old_plan) {
  my $pkg_url = "xml-api/changepackage?api.version=1&pkg=$new_plan&user=$username";
  my $status = whm_connect($user, $pass, $pkg_url);
  print "$status->{metadata}->{reason}\n" if ($verbose);
  exit;
}
else {
  print "No plan change applied to $username as old plan didn't match\n" if ($verbose);
  exit 1;
}

sub whm_connect {
  my ($user, $pass, $url) = @_;

  my $auth = "Basic " . MIME::Base64::encode( $user . ":" . $pass );
  my $ua = LWP::UserAgent->new(
    ssl_opts => { verify_hostname => 0, 
                  SSL_verify_mode => 'SSL_VERIFY_NONE', 
                  SSL_use_cert => 0 },
  );
  my $xml = new XML::Simple;
  my $request = HTTP::Request->new(GET => "https://127.0.0.1:2087/$url");
  $request->header( Authorization => $auth );
  my $response = $ua->request($request);

  return $xml->XMLin($response->content);
}

sub usage
{
  print "Unknown option: @_\n" if ( @_ );
  print "usage: program [--username|-u USERNAME]";
  print " [--new-plan|-n \"NEW PLAN\"]";
  print " [--old-plan|-o \"OLD PLAN\"]";
  print " [--verbose|-v]";
  print " [--help|-?]\n";
  exit;
}

