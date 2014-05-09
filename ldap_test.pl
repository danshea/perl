#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use Net::LDAP;
use Data::Dumper;

my $ldap = Net::LDAP->new( 'wqldap-mdc1.med.harvard.edu' ) or die "$@";

my $mesg = $ldap->bind ;    # an anonymous bind

$mesg = $ldap->search( # perform a search
                       base   => "dc=med,dc=harvard,dc=edu",
                       filter => "(&(objectclass=posixGroup)(cn=calendars))",
                     );

$mesg->code && die $mesg->error;


say map {lc ($_->get_value ('memberUid'))} $mesg->entries;

foreach my $entry ($mesg->entries){
    foreach my $uid ($entry->get_value('memberUid')){
        say lc($uid);
    }
}

$mesg = $ldap->unbind;   # take down session