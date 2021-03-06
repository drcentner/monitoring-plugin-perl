# Monitoring::Plugin test set 2, testing MP::Functions wrapping

use strict;
use Test::More tests => 103;

BEGIN { use_ok("Monitoring::Plugin") }
require Monitoring::Plugin::Functions;
Monitoring::Plugin::Functions::_fake_exit(1);

# Hardcoded checks of constants
my %ERRORS = %Monitoring::Plugin::Functions::ERRORS;
is(OK,          $ERRORS{OK},            "OK        => $ERRORS{OK}");
is(WARNING,     $ERRORS{WARNING},       "WARNING   => $ERRORS{WARNING}");
is(CRITICAL,    $ERRORS{CRITICAL},      "CRITICAL  => $ERRORS{CRITICAL}");
is(UNKNOWN,     $ERRORS{UNKNOWN},       "UNKNOWN   => $ERRORS{UNKNOWN}");
is(DEPENDENT,   $ERRORS{DEPENDENT},     "DEPENDENT => $ERRORS{DEPENDENT}");

my $plugin = 'TEST_PLUGIN';
my $np = Monitoring::Plugin->new( shortname => $plugin );
is($np->shortname, $plugin, "shortname() is $plugin");

# Test plugin_exit( CONSTANT, $msg ), plugin_exit( $string, $msg )
my $r;
my @ok = (
    [ OK,        "OK",           'test the first',  ],
    [ WARNING,   "WARNING",      'test the second', ],
    [ CRITICAL,  "CRITICAL",     'test the third',  ],
    [ UNKNOWN,   "UNKNOWN",      'test the fourth', ],
    [ DEPENDENT, "DEPENDENT",    'test the fifth',  ],
);
for (@ok) {
    # CONSTANT
    $r = $np->plugin_exit($_->[0], $_->[2]);
    is($r->return_code, $_->[0],
        sprintf('plugin_exit(%s, $msg) returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$plugin\b.*$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_exit(%s, $msg) output matched "%s"', $_->[1],
            $plugin . ' ' . $_->[1] . '.*' . $_->[2]));

    # $string
    $r = $np->plugin_exit($_->[1], $_->[2]);
    is($r->return_code, $_->[0],
        sprintf('plugin_exit("%s", $msg) returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$plugin\b.*$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_exit("%s", $msg) output matched "%s"', $_->[1],
            $plugin . ' ' . $_->[1] . '.*' . $_->[2]));
    like($r, qr/$plugin\b.*$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_exit("%s", $msg) stringified matched "%s"', $_->[1],
            $plugin . ' ' . $_->[1] . '.*' . $_->[2]));
}

# plugin_exit code corner cases
my @ugly1 = (
    [ -1, 'testing code -1' ],
    [ 7, 'testing code 7' ],
    [ undef, 'testing code undef' ],
    [ '', qq(testing code '') ],
    [ 'string', qq(testing code 'string') ],
);
for (@ugly1) {
    $r = $np->plugin_exit($_->[0], $_->[1]);
    my $display = defined $_->[0] ? "'$_->[0]'" : 'undef';
    is($r->return_code, UNKNOWN, "plugin_exit($display, \$msg) returned ". UNKNOWN);
    like($r->message, qr/UNKNOWN\b.*\b$_->[1]$/,
        sprintf('plugin_exit(%s, $msg) output matched "%s"',
            $display, 'UNKNOWN.*' . $_->[1]));
}

# plugin_exit message corner cases
my @ugly2 = (
    [ '' ],
    [ undef ],
    [ UNKNOWN ],
);
for (@ugly2) {
    $r = $np->plugin_exit(CRITICAL, $_->[0]);
    my $display1 = defined $_->[0] ? "'$_->[0]'" : "undef";
    my $display2 = defined $_->[0] ? $_->[0] : '';
    like($r->message, qr/CRITICAL\b.*\b$display2$/,
        sprintf('plugin_exit(%s, $msg) output matched "%s"',
            $display1, "CRITICAL.*$display2"));
}

# Test plugin_die( $msg )
my @msg = (
    [ 'die you dog' ],
    [ '' ],
    [ undef ],
);
for (@msg) {
    $r = $np->plugin_die($_->[0]);
    my $display1 = defined $_->[0] ? "'$_->[0]'" : "undef";
    my $display2 = defined $_->[0] ? $_->[0] : '';
    is($r->return_code, UNKNOWN,
        sprintf('plugin_die(%s) returned UNKNOWN', $display1));
    like($r->message, qr/UNKNOWN\b.*\b$display2$/,
        sprintf('plugin_die(%s) output matched "%s"', $display1,
            "UNKNOWN.*$display2"));
}

# Test plugin_die( CONSTANT, $msg ), plugin_die( $msg, CONSTANT ),
#   plugin_die( $string, $msg ), and plugin_die( $msg, $string )
@ok = (
    [ OK,        "OK",           'test the first',  ],
    [ WARNING,   "WARNING",      'test the second', ],
    [ CRITICAL,  "CRITICAL",     'test the third',  ],
    [ UNKNOWN,   "UNKNOWN",      'test the fourth', ],
    [ DEPENDENT, "DEPENDENT",    'test the fifth',  ],
);
for (@ok) {
    # CONSTANT, $msg
    $r = $np->plugin_die($_->[0], $_->[2]);
    is($r->return_code, $_->[0],
        sprintf('plugin_die(%s, $msg) returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die(%s, $msg) output matched "%s"',
            $_->[1], $_->[1] . '.*' . $_->[2]));

    # $msg, CONSTANT
    $r = $np->plugin_die($_->[2], $_->[0]);
    is($r->return_code, $_->[0],
        sprintf('plugin_die($msg, %s) returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die($msg, %s) output matched "%s"',
            $_->[1], $_->[1] . '.*' . $_->[2]));

    # $string, $msg
    $r = $np->plugin_die($_->[1], $_->[2]);
    is($r->return_code, $_->[0],
        sprintf('plugin_die("%s", $msg) returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die("%s", $msg) output matched "%s"', $_->[1],
            $_->[1] . '.*' . $_->[2]));
    like($r, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die("%s", $msg) stringified matched "%s"', $_->[1],
            $_->[1] . '.*' . $_->[2]));

    # $string, $msg
    $r = $np->plugin_die($_->[2], $_->[1]);
    is($r->return_code, $_->[0],
        sprintf('plugin_die($msg, "%s") returned %s', $_->[1], $_->[0]));
    like($r->message, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die($msg, "%s") output matched "%s"', $_->[1],
            $_->[1] . '.*' . $_->[2]));
    like($r, qr/$_->[1]\b.*\b$_->[2]$/,
        sprintf('plugin_die($msg, "%s") stringified matched "%s"', $_->[1],
            $_->[1] . '.*' . $_->[2]));
}


# shortname testing
SKIP: {
    skip "requires File::Basename", 2 unless eval { require File::Basename };
    $np = Monitoring::Plugin->new( version => "1");
    $plugin = uc File::Basename::basename($0);
    $plugin =~ s/\..*$//;
    is($np->shortname, $plugin, "shortname() is '$plugin'");
    $r = $np->plugin_exit(OK, "foobar");
    like($r->message, qr/^$plugin OK/, "message begins with '$plugin OK'");
}
