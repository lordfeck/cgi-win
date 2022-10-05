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
use MIME::Base64;

use GD;
use CGI;
use Template;

my $VERSION = "0.1";

#===============================================================================
# Begin Globals and Conf
#===============================================================================

my ($fleg_width, $fleg_height) = (700, 460);
my $use_cgi = 1;                    # Set to 0, will just generate flag and exit
my $allow_adjust = 1;               # Allow minor tweaks to flag dimensions
my $use_embedded = 1;               # Use embedded images rather than filesystem
my $fleg_write_dir = "./img";

my $fleg_canvas;            # Global, written by all make_$FLAGTYPE functions
my ($c_white, $c1, $c2, $c3);       # Predeclare colours
my ($t_begin, $t_end) = ("" , "");  # Predeclare time for stats
my $fleg_write_path = "";           # Final full path where fleg is written
my $fleg_img_src = "";              # Embed img src, either path or b64 png
my $country_name = "";              # A fine nation worthy of the ages.
my $b64_png;                        # Dump the base64 PNG here if use_embed=on

my $template = Template->new();     # Instantiate Template Toolkit
my $tpl    = join "\n", <DATA>;     # Read __DATA__ and store as tpl
my %model;                          # Model kvs used for template
my %fleg_dispatch;                  # Dispatch table used to call a fleg fn

$t_begin = gettimeofday;

#===============================================================================
# End globals, begin phrasemaker
#===============================================================================

my @epithet = qw(People's Princely Grand Holy Stately Great Ancient Old 
Democratic Theocratic Free High Noble Liberal Serene Socialist Anarchic Nordic
Eternal Soviet Blessed Absolutist Bourbon Martial Almighty Presidential
Teutonic Mercantile Maritime Provisional Metropolitan Unified Greater Papal
Dreaded Pacifist Worker's Lower Lesser);

push @epithet, ("", "", "");        # Small chance epithet is omitted

my @state_type = qw(Republic Kingdom Duchy Despotate Empire Nation Caliphate
Lordship Earldom States Junta Reich Commonwealth Confederation Bailiwick
Order Archipelago League Collective Protectorate Union Province Fiefdom
Emirate Principality Imperium Sheikhdom);

my @land_prefix = qw(Shi Leo Lea Orm Mos Amer Brit Zimbab Allo Les Clay Poll
Cross Bomb Ethel Amer Flow Gurg Kor Shef Bess Long Lank Arme Nin Nam Ever Mar
Hol Fran Shlo Pel Bran Fle Nor Presby West Allay Val Affer Tir Lul Ers Thu
Flog Flug Glog Noh Sumer Low Lough Blo Mor Gon Rho);

my @land_suffix = qw(topia land ville field shire istan ca iffi ton ina rie via
ica net ria ova aty ava ah rina aq terra tonia one dor dill dell ster);

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

div#reloadPlaceholder {
    margin-bottom 30px;
    font-size: 1.5em;
}

span.big_slant {
    font-size: 2em;
    font-style: italic;
}

img#fleg {
    max-width: 100%;
    display: block;
    margin-left: auto;
    margin-right: auto;
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

sub make_dutchie {
    my $third = $fleg_height/3;

    $fleg_canvas->filledRectangle(0, $fleg_height, $fleg_width, 2*$third, $c1);
    $fleg_canvas->filledRectangle(0, 2*$third, $fleg_width, $third, $c2);
    $fleg_canvas->filledRectangle(0, $third, $fleg_width, 0, $c3);
}

sub make_eurocross {
    # Stretch it. TODO: Need to remake GD object, currently truncated
    #    $fleg_width += 2* sqrt($fleg_width) if ($allow_adjust);

    my $fifth_h = $fleg_height/5;
    my $fifth_w = ($fleg_width/5) - sqrt($fleg_height);

    my $midpoint_x = $fleg_width/2;
    my $midpoint_y = $fleg_height/2;

    my $tenth_w = $fifth_w/2;
    my $tenth_h = $fifth_h/2;

    $fleg_canvas->fill(0, 0, $c2);
    $fleg_canvas->filledRectangle($midpoint_x - $tenth_w, 0, $midpoint_x + $tenth_w, $fleg_height, $c1);
    $fleg_canvas->filledRectangle(0, $midpoint_y -$tenth_h, $fleg_width, $midpoint_y + $tenth_h, $c1);
}

sub make_flag {
    my @keys = keys %fleg_dispatch;
    my $maxIdx = scalar @keys;
    # Run a random fn inside fleg_dispatch
    &{$fleg_dispatch{$keys[int rand($maxIdx)]}};
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

sub make_image_write {
    my $ts = time;
    die "Cannot find $fleg_write_dir" unless -d $fleg_write_dir;
    $fleg_write_path = "$fleg_write_dir/fleg_$ts.png";
    open (my $TMPFILE, ">", "$fleg_write_path") 
        or die "Cannot open $fleg_write_path to write";

    binmode $TMPFILE;
    print $TMPFILE $fleg_canvas->png;
    close $TMPFILE;
    $fleg_img_src = $fleg_write_path;
}

sub make_image_embedded {
    $b64_png = encode_base64($fleg_canvas->png, "");
    $fleg_img_src = "data:image/png;base64,$b64_png";
}

sub make_image {
    if ($use_embedded) {
        make_image_embedded;
    } else {
        make_image_write;
    }
}

sub do_cgi {
    my $cgi = CGI->new();

    $model{stylesheet} = $STYLESHEET;
    $model{fleg_img_src} = $fleg_img_src;
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
my $chance_of_white = 1 + int rand(5);      # 1 in 5 chance of white for c2

$c1 = $fleg_canvas->colorAllocate(get_color,get_color,get_color);
$c2 = $chance_of_white == 5 ? $c_white :
    $fleg_canvas->colorAllocate(get_color,get_color,get_color);
$c3 = $fleg_canvas->colorAllocate(get_color,get_color,get_color);

$fleg_canvas->fill(0,0,$c_white);

%fleg_dispatch = (
    dutchie => \&make_dutchie,
    tricolour => \&make_tricolour,
    eurocross => \&make_eurocross
);

make_flag;
christen_the_land;

say $country_name unless($use_cgi);

make_image;

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

    <title>FLEGGER</title>
</head>
<body>
<div id="leadSection">
    <h1 id="leadTitle"><span class="big_slant">B</span>ehold</h1>
    <div id="subTitle">A new nation is born!</div>
</div>
<div id="greetLeader"></div>
<div id="flegPole"><img id="fleg" alt="Fleg missing or your browser does not support base64 embedded images" src="[% fleg_img_src %]"></div>
<div id="countryName">[% country_name %]</div>
<div id="reloadPlaceholder">
    <button type="button" title="this displeaseth his majesty?" onClick="window.location.reload()">Renew</button>
</div>

<p class="footer_text">Flegmaker v[% version %], by <a href="https://soft.thran.uk" target="_blank">Thransoft</a>. <a href="https://github.com/lordfeck/cgi-win" target="_blank">Source</a>.</p>
<p class="footer_text" title="Will it last?">Established in [% t_end %] seconds.</p>
</body>
</html>

