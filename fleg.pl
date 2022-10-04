#!/usr/bin/perl
#===============================================================================
# Flegmaker v0.1
#===============================================================================
# (C) Thransoft, 2022
# GPL v3.
# soft.thran.uk
# Authored: 03/10/2022
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Initially generate a random flag.
# Later allow parameters for customisation.
#
#===============================================================================

use v5.25;
use warnings;
use Time::HiRes qw(gettimeofday);

use GD;
use CGI;
use Template;

my $VERSION = "0.1";

#===============================================================================
# Begin Globals and Conf
#===============================================================================

my ($fleg_width, $fleg_height) = (700, 460);
my $use_cgi = 1;
my $fleg_write_dir = "./img";

my $fleg_canvas;            # Global, written by all make_$FLAGTYPE functions
my ($c_white, $c1, $c2, $c3);       # Predeclare colours
my ($t_begin, $t_end) = ("" , "");  # Predeclare time for stats
my $fleg_write_path = "";           # Final full path where fleg is written
my $country_name = "";              # A fine nation worthy of the ages.

my $template = Template->new();
my $tpl    = join "\n", <DATA>;
my %model;

$t_begin = gettimeofday;

#===============================================================================
# End globals, begin phrasemaker
#===============================================================================

my @epithet = qw(People's Princely Grand Holy Stately Great Ancient Old 
Democratic Theocratic Free High Noble Liberal Serene Socialist Anarchic Nordic
Eternal Soviet Blessed Absolutist Bourbon Martial Almighty Presidential
Teutonic Mercantile Maritime Provisional Metropolitan Unified Greater Papal);

my @state_type = qw(Republic Kingdom Duchy Despotate Empire Nation Caliphate
Lordship Earldom States Junta Reich Commonwealth Confederation Bailiwick
Order Archipelago League Collective Protectorate Union Province );

my @land_prefix = qw(Shi Leo Lea Orm Mos Amer Brit Zimbab Allo Les Clay Poll
Cross Bomb Ethel Amer Flow Gurg Kor Shef Bess Long Lank Arme Nin Nam Ever Mar
Hol Fran Shlo Pel);

my @land_suffix = qw(topia land ville field shire istan ca iffi ton ina rie via
ica net ria ova aty ava ah);

#===============================================================================
# End Phrasemaker, Begin CSS
#===============================================================================

my $STYLESHEET = << "EOF";

body { 
    text-align: center; 
    background-color: #fdfdfd;
    margin: 0;
}

div#countryName {
    font-family: serif;
    font-style: italic;
}

div#greetLeader { }

div#countryName {
    display: inline-block;
    background-color: #feffcb;

    font-family: Palatino, Georgia, serif;
    font-size: 2em;

    padding: 4px;
    margin-top: 10px;
    margin-bottom: 30px;

    border-radius: 15px;
    border-style: ridge;
}

p.footer_text {
    font-family: Verdana, Arial, sans-serif;
    font-size: 0.8em;
}

h1#leadTitle {
    margin-top: 0px;
    margin-bottom: 2px;
}

div#subTitle { }

div#leadSection {
    font-family: Palatino, Georgia, serif;
    margin: 0px 0px 20px 0px;
    padding: 20px 0 20px 0;
    background-color: #ffff1f;
    border-bottom: 2px solid black;
}

span.big_slant {
    font-size: 2em;
    font-style: italic;
}

EOF

#===============================================================================
# End CSS. Begin fndef
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

sub christen_the_land {
   $country_name .= "$epithet[int rand(scalar(@epithet))] "; 
   $country_name .= "$state_type[int rand(scalar(@state_type))] of "; 
   $country_name .= $land_prefix[int rand(scalar(@land_prefix))]; 
   $country_name .= $land_suffix[int rand(scalar(@land_suffix))]; 
}

sub do_cgi {
    my $cgi = CGI->new();

    $model{stylesheet} = $STYLESHEET;
    $model{fleg_write_path} = $fleg_write_path;
    $model{country_name} = $country_name;
    $model{version} = $VERSION;
    $model{t_end} = gettimeofday - $t_begin;

    print $cgi->header;

    $template->process(\$tpl,\%model) 
        or die "Template process failed", $template->error();
}

#===============================================================================
# End fndef. Begin Perl exec
#===============================================================================

$fleg_canvas = GD::Image->new($fleg_width, $fleg_height, 1);
# TODO: Make list of flag safe colours?? or allow trueRandom.
$c_white = $fleg_canvas->colorAllocate(255,255,255); # white

# Allocate to colour table and return index.
my @rands;
$rands[0] = get_color;
$rands[1] = get_color;
$rands[2] = get_color;

$c1 = $fleg_canvas->colorAllocate($rands[0],$rands[1],$rands[2]);
$c2 = $fleg_canvas->colorAllocate($rands[2],$rands[1],$rands[0]);
$c3 = $fleg_canvas->colorAllocate($rands[1],$rands[0],$rands[2]);

$fleg_canvas->fill(0,0,$c_white);

make_tricolour;
christen_the_land;
say $country_name unless($use_cgi);

my $ts = time;

die "Cannot find $fleg_write_dir" unless -d $fleg_write_dir;
$fleg_write_path = "$fleg_write_dir/fleg_$ts.png";
open (my $TMPFILE, ">", "$fleg_write_path") 
    or die "Cannot open $fleg_write_path to write";

binmode $TMPFILE;
print $TMPFILE $fleg_canvas->png;
close $TMPFILE;

do_cgi if ($use_cgi);

#===============================================================================
# Data section - TT skeleton
#===============================================================================

__DATA__
<!doctype HTML>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style type="text/css">
    [% stylesheet %]
    </style>

    <title>FLEGMAKER</title>
</head>
<body>
<div id="leadSection">
    <h1 id="leadTitle"><span class="big_slant">B</span>ehold</h1>
    <div id="subTitle">A new nation is born!</div>
</div>
<div id="greetLeader"></div>
<div id="flegPole"><img src="[% fleg_write_path %]"></div>
<div id="countryName">[% country_name %]</div>

<p class="footer_text">Flegmaker v[% version %], by <a href="https://soft.than.uk" target="_blank">Thransoft</a>.</p>
<p class="footer_text">Built in [% t_end %] seconds.</p>
</body>
</html>

