#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use v5.14;

# use FindBin;
# BEGIN {
#   unshift @INC, "$FindBin::Bin/public_html/mojo";
#   unshift @INC, "$FindBin::Bin/public_html/cpan_lib";
#   unshift @INC, "$FindBin::Bin/lib/perl5";
# }

use Mojolicious;
use DBI;
use DBD::mysql;
use Digest::SHA;
use Time::Moment;




say "Mojolicious ", Mojolicious->VERSION;
say "DBI ", DBI->VERSION;
say "DBD::mysql ", DBD::mysql->VERSION;
say "Digest::SHA ", Digest::SHA->VERSION;
say "Time::Moment ", Time::Moment->VERSION;


# === на моем компе ===
#
# Mojolicious 7.25
# DBI 1.634
# DBD::mysql 4.033


1;