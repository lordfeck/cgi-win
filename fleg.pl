#!/usr/bin/perl
#===============================================================================
# Flegmaker v0.2
#===============================================================================
# (C) Thransoft, 2022
# GPL v3.
# soft.thran.uk
# Authored: 03/10/2022 - 09/11/2024
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# "The new drunk drivers have hoisted the flag" R. Pollard.
#
# Generate a flag from random numbers. Use CGI or dump to fs.
#
#===============================================================================

use v5.16;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);
use MIME::Base64;
use Scalar::Util qw(looks_like_number);

use GD;
use Template;

my $VERSION = "0.2.2";

#===============================================================================
# Begin Configuration
#===============================================================================

my ($fleg_width, $fleg_height) = (700, 460);
my $use_cgi = 1;                    # Set to 0, will just generate flag and exit
my $allow_adjust = 1;               # Allow minor tweaks to flag dimensions
my $use_embedded = 1;               # Use embedded images rather than filesystem
my $use_count = 1;                  # Enable or disable hit counter
my $FLEG_WRITE_DIR = "./img";       # When embedded is disabled, write flags here
my $COUNT_FILE = "../count.txt";    # Hit counter storage

#===============================================================================
# Begin global variables. Used internally by flegger, do not touch!
#===============================================================================

my $fleg_canvas;            # Global, written by all make_$FLAGTYPE functions
my ($c_white, $c1, $c2, $c3);       # Predeclare colours
my ($t_begin, $t_end) = ("" , "");  # Predeclare time for stats
my $fleg_write_path = "";           # Final full path where fleg is written
my $fleg_img_src = "";              # Embed img src, either path or b64 png
my $country_name = "";              # A fine nation worthy of the ages.
my $chosen_flag_style;              # Store the flag style key here.
my $hits = "??";                    # Store the hits read from count.txt

my $template = Template->new();     # Instantiate Template Toolkit
my $tpl    = join "\n", <DATA>;     # Read __DATA__ and store as tpl
my %model;                          # Model kvs used for template
my %fleg_dispatch;                  # Dispatch table used to call a fleg fn

my $CGI_HEADER = "Content-type: text/html\n\n"; # So browsers know what to do.

$t_begin = gettimeofday;

#===============================================================================
# End globals, begin phrasemaker
#===============================================================================

my @epithet = qw(People's Princely Grand Holy Stately Great Ancient Old 
Democratic Theocratic Free High Noble Liberal Serene Socialist Anarchic Nordic
Eternal Soviet Blessed Absolutist Bourbon Martial Almighty Presidential
Teutonic Mercantile Maritime Provisional Metropolitan Unified Greater Papal
Dreaded Pacifist Worker's Lower Lesser Liberated Restored Renewed True New
Hapsburg Northern Southern Eastern Western United);

my @state_type = qw(Republic Kingdom Duchy Despotate Empire Nation Caliphate
Lordship Earldom States Junta Reich Commonwealth Confederation Bailiwick
Order Archipelago League Collective Protectorate Union Province Fiefdom
Emirate Principality Imperium Sheikhdom Mandate County State Dominion
Margraviate Tanistry Commune Tsardom Khanate);

my @land_prefix = qw(Shi Leo Lea Orm Mos Amer Brit Zim Allo Les Clay Poll
Cross Bom Ethel Amer Flo Gurg Kor Shef Bess Long Lank Arme Nin Nam Ever Mar
Hol Fran Shlo Pel Bran Fle Nor Presby West Allay Val Affer Tir Lul Ers Thu
Flog Flug Glog Noh Sumer Low Lough Blo Mor Gon Rho Apolly Hyp Magh Bally
Ut Up Ovl Ner Nes Gran Lop Ess Par Pan Ov Neo);

my @land_suffix = qw(topia land ville field shire istan ca iffi ton ina rie via
ica net ria ova aty ava ah rina aq terra tonia one dor dill dell ster bora lia
donia dom don mor tannia as ce tire idad dina ama);

#===============================================================================
# End Phrasemaker, Begin CSS
#===============================================================================

my $STYLESHEET = << 'EOF';

body {
    text-align: center;
    background-color: #f9f9c7;
    margin: 0;
}


div#countryName {
    font-family: serif;
    font-style: italic;

    display: inline-block;
    background-color: #fdffaa;

    font-family: Palatino, Georgia, serif;
    font-size: 2em;

    padding: 10px;
    margin-top: 10px;

    border-radius: 15px;
    border-style: ridge;
}

p.footer_text {
    font-family: Verdana, Arial, sans-serif;
    font-size: 0.8em;
}

span.hits {
    color: #019701;
    text-shadow: 0px 1px 1px #9d9d9d;
}

h1#leadTitle {
    margin-top: 0px;
    margin-bottom: 2px;
    text-shadow: 2px 2px black;
}

div#subTitle { }

div#leadSection {
    font-family: Palatino, Georgia, serif;
    margin: 0px 0px 20px 0px;
    padding: 20px 0 20px 0;
    background-color: #311717;
    border-bottom: 2px solid black;
    color: #dfc0c0;
}

div#reloadPlaceholder {
    padding: 10px;
    margin-bottom 30px;
}

#reloadPlaceholder button {
    padding: 5px 15px 5px 15px;
    font-size: 1.2em;
}

span.big_slant {
    font-size: 2em;
    font-style: italic;
}

div#flegPole { 
    min-height: 500px;
    max-width: 100%; 
    margin: auto;
}

@media only screen and (max-width: 700px) {
    div#flegPole { 
        min-height: 250px;
        max-width: 90%; 
    }

    div#countryName {
        font-size: 1.5em;
        padding: 8px;
    }
}

img#fleg {
    max-width: 100%;
    display: block;
    margin-left: auto;
    margin-right: auto;
    border: 1px solid black;
}

EOF

#===============================================================================
# End CSS. Begin fndef
#===============================================================================

sub adjust_dimensions {
    if ($chosen_flag_style eq "nordicross") {
        # Swedish Flag is 5:8 ratio
        $fleg_height = 5/8 * $fleg_width;
    } elsif ($chosen_flag_style eq "eurocross") {
        $fleg_width += 2* sqrt($fleg_width);
    }
}

sub get_color {
    # Limit range so we're neither too bright nor too dim
    return 20 + int rand(210); 
}

sub build_fleg_canvas {
    $fleg_canvas = GD::Image->newTrueColor($fleg_width, $fleg_height, 1);
    $c_white = $fleg_canvas->colorAllocate(255,255,255); # white

    my $chance_of_white = 1 + int rand(6);      # 1 in ~5 chance of white for c2

    # Allocate to colour table and return index.
    $c1 = $fleg_canvas->colorAllocate(get_color,get_color,get_color);
    $c2 = $chance_of_white >= 5 ? $c_white :
        $fleg_canvas->colorAllocate(get_color,get_color,get_color);
    $c3 = $fleg_canvas->colorAllocate(get_color,get_color,get_color);

    $fleg_canvas->fill(0,0,$c_white);
}


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
    my $fifth_h = $fleg_height/5;
    my $fifth_w = ($fleg_width/5) - sqrt($fleg_height);

    my $midpoint_x = $fleg_width/2;
    my $midpoint_y = $fleg_height/2;

    my $tenth_w = $fifth_w/2;
    my $tenth_h = $fifth_h/2;

    $fleg_canvas->fill(0, 0, $c2);
    $fleg_canvas->filledRectangle($midpoint_x - $tenth_w, 0, $midpoint_x + $tenth_w, $fleg_height, $c1);
    $fleg_canvas->filledRectangle(0, $midpoint_y - $tenth_h, $fleg_width, $midpoint_y + $tenth_h, $c1);
}

sub make_nordicross {
    my $fifth_h = $fleg_height/5;
    my $fifth_w = ($fleg_width/5) - 2* sqrt($fleg_height);

    my $midpoint_y = $fleg_height/2;

    my $tenth_w = $fifth_w/2;
    my $tenth_h = $fifth_h/2;

    $fleg_canvas->fill(0, 0, $c2);
    $fleg_canvas->filledRectangle($tenth_w*3, 0, $tenth_w*5, $fleg_height, $c1);
    $fleg_canvas->filledRectangle(0, $midpoint_y - $tenth_h, $fleg_width, $midpoint_y + $tenth_h, $c1);
}

sub make_saltire {
    my @origin = (0,0);
    my @target = ($fleg_width, $fleg_height);

    my $tenth_w = int ($fleg_width/10);

    $fleg_canvas->fill(0, 0, $c2); # chance that c2 may be white or other colour.

    $fleg_canvas->setAntiAliased($c1); 
    $fleg_canvas->setThickness($tenth_w);
    $fleg_canvas->line(@origin, @target, $c1);

    @origin = (0, $fleg_height);
    @target = ($fleg_width, 0);
    
    $fleg_canvas->line(@origin, @target, $c1);
}

sub decide_flag {
    my @keys = keys %fleg_dispatch;
    my $maxIdx = scalar @keys;
    # Run a random fn inside fleg_dispatch
    $chosen_flag_style = $keys[int rand($maxIdx)];
}

sub christen_the_land {
    my $chance_of_epithet = int rand(10);
   $country_name .= $chance_of_epithet >= 5 ?"$epithet[int rand(scalar(@epithet))] " : ""; 
   $country_name .= "$state_type[int rand(scalar(@state_type))] of "; 
   $country_name .= $land_prefix[int rand(scalar(@land_prefix))]; 
   $country_name .= $land_suffix[int rand(scalar(@land_suffix))]; 
}

sub make_image_write {
    my $ts = time;
    die "Cannot find $FLEG_WRITE_DIR" unless -d $FLEG_WRITE_DIR;
    $fleg_write_path = "$FLEG_WRITE_DIR/fleg_$ts.png";
    open (my $TMPFILE, ">", "$fleg_write_path") 
        or die "Cannot open $fleg_write_path to write";

    binmode $TMPFILE;
    print $TMPFILE $fleg_canvas->png;
    close $TMPFILE;
    $fleg_img_src = $fleg_write_path;
}

sub make_image_embedded {
    my $b64_png = encode_base64($fleg_canvas->png);
    $fleg_img_src = "data:image/png;base64,$b64_png";
}

sub make_image {
    if ($use_embedded) {
        make_image_embedded;
    } else {
        make_image_write;
    }
}

sub do_hit_counter {
    # If reading of count succeeds, keep use_count enabled
    $use_count = eval {
        if (-f $COUNT_FILE and -s $COUNT_FILE) {
            open my $fh, '<', $COUNT_FILE;
            $hits = <$fh>;
            close $fh;
        }

        if (looks_like_number($hits)) {
            $hits++;
        } else {
            $hits = 1;
        }

        open my $fh, '>', $COUNT_FILE;
        print $fh $hits;

        close $fh;
        1;
    };
    warn "Problem reading from or writing to $COUNT_FILE" unless $use_count;
}

sub do_cgi {
    $model{stylesheet} = $STYLESHEET;
    $model{fleg_img_src} = $fleg_img_src;
    $model{country_name} = $country_name;
    $model{version} = $VERSION;
    $model{hits} = $hits if $use_count;
    $model{t_end} = sprintf("%.4f", gettimeofday - $t_begin);

    print $CGI_HEADER;

    $template->process(\$tpl,\%model) 
        or die "Template process failed", $template->error();
}


#===============================================================================
# End fndef. Begin Perl exec
#===============================================================================

# Enforce write to dir if CGI disabled
$use_embedded = 0 unless($use_cgi);

# Store refrences to each flag function in the dispatch hash
%fleg_dispatch = (
    dutchie => \&make_dutchie,
    tricolour => \&make_tricolour,
    eurocross => \&make_eurocross,
    nordicross => \&make_nordicross,
    saltire => \&make_saltire
);

# Decide the fleg style using those keys and store it in $chosen_flag_style.
decide_flag;
adjust_dimensions if ($allow_adjust);
build_fleg_canvas;

# Run the function for the chosen flag style.
&{$fleg_dispatch{$chosen_flag_style}};
christen_the_land;

say "Making a $chosen_flag_style for the $country_name" unless($use_cgi);

make_image;
do_hit_counter if $use_count;
do_cgi if $use_cgi;

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
    <h1 id="leadTitle"><span class="big_slant">B</span>ehold,</h1><div id="subTitle">A new nation is born!</div>
</div>
<div id="greetLeader"></div>
<div id="flegPole"><img id="fleg" alt="Fleg stolen or your browser does not support base64 embedded images" src="[% fleg_img_src %]"></div>
<div id="countryName">[% country_name %]</div>
<div id="reloadPlaceholder">
    <button type="button" title="this displeaseth his majesty?" onClick="window.location.reload()">Renew</button>
</div>

<p class="footer_text" title="Will it last?">Established in [% t_end %] seconds.</p>
[% IF hits -%]
<p class="footer_text" title="We've been busy.">Proudly gifting the world <span class="hits">[% hits %]</span> flegs.</p>
[% END -%]
<p class="footer_text">Flegmaker v[% version %] by <a href="https://soft.thran.uk" target="_blank">Thransoft</a>. <a href="https://github.com/lordfeck/cgi-win" target="_blank">Source</a>.</p>
</body>
</html>

