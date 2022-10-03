#!/usr/bin/perl

#===============================================================================
# Flegmaker v0.1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (C) Thransoft, 2022
# GPL v3.
# soft.thran.uk
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Initially generate a random flag.
# Later allow parameters for customisation.
#
#===============================================================================

use v5.32;
use warnings;

use GD;
use CGI;

my $VERSION = "0.9";

#===============================================================================
# Begin Globals and Conf
#===============================================================================

my ($fleg_width, $fleg_height) = (700, 460);
my $use_cgi = 0;
my $true_random = 1;
my $fleg_write_path;

my $fleg_canvas; # Global, written by all make_$FLAGTYPE functions
my ($c_white, $c1, $c2, $c3);


#===============================================================================
# End globals, begin phrasemaker
#===============================================================================
my @epithet = qw(People's Princely Grand Holy Stately Great Ancient Old 
Democratic Theocratic Free High Noble Liberal Serene Socialist);

my @state_type = qw(Republic Kingdom Duchy Despotate Empire Nation Calphate
Lordship Earldom States);

my @land_name1 = qw(Shi Leo Lea Orm Mos);
my @land_name2 = qw(topia land ville field shire istan ca iffi ton ina rie via);

#===============================================================================
# End Phrasemaker, Begin CSS
#===============================================================================

my $STYLESHEET = << "EOF";

body { 
    text-align: center; 
    background-color: gray;
}

p#countryName {
    font-family: serif;
    font-style: italic;
}

EOF

#===============================================================================
# End CSS. Begin HTML
#===============================================================================
my %fillers = (
    title => "",
);

my $HEADER = << "EOF";
<!doctype HTML>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style type="text/css">
    $STYLESHEET
    </style>

    <title>FLEGMAKER $fillers{title}</title>
</head>
<body>
EOF

my $FOOTER = << "EOF";
<p>Flegmaker v$VERSION, by Thransoft.</p>
</body>
</html>
EOF

#===============================================================================
# End HTML. Begin Perl fndef
#===============================================================================

sub make_tricolour {
    my $third = $fleg_width/3;

    $fleg_canvas->filledRectangle(0, $fleg_height, $third, 0, $c1);
    $fleg_canvas->filledRectangle($third, $fleg_height, 2*$third, 0, $c2);
    $fleg_canvas->filledRectangle(2*$third, $fleg_height, $fleg_width, 0, $c3);
}

sub get_color {
    # Limit range so we're neither too bright nor too dim
    return 20 + int rand(210); 
}

#===============================================================================
# End fndef. Begin Perl exec
#===============================================================================

$fleg_canvas = GD::Image->new($fleg_width, $fleg_height, 1);
# TODO: Make list of flag safe colours?? or allow trueRandom.
$c_white = $fleg_canvas->colorAllocate(255,255,255); # white

# Allocate to colour table and return index.
if ($true_random) {
    my @rands;
    $rands[0] = get_color;
    $rands[1] = get_color;
    $rands[2] = get_color;

    $c1 = $fleg_canvas->colorAllocate($rands[0],$rands[1],$rands[2]);
    $c2 = $fleg_canvas->colorAllocate($rands[2],$rands[1],$rands[0]);
    $c3 = $fleg_canvas->colorAllocate($rands[1],$rands[0],$rands[2]);
} else {
    die "not implemented";
}

$fleg_canvas->fill(0,0,$c_white);

# TODO: Other flag styles.
make_tricolour;

open (my $TMPFILE, ">", "./tmp.png") or die "Cannot open";

binmode $TMPFILE;
print $TMPFILE $fleg_canvas->png;
close $TMPFILE;
