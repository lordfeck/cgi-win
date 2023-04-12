THRANSOFT CGI-WIN
=========================
Fun CGI scripts for the modern web.

# CONTENTS
What's inside?

### Fleg.pl
A flag generator. Currently does the following:
- Generate a random flag from these styles: French Triband, Dutch Triband, British Cross, Nordic Cross
- Generate a 'suitable' country name
- Basic hit counter recording the number of flags generated

# SETUP 
We assume that you have:
* Perl installed.
* CPAN or cpanm bootstrapped.
* Some Unix sysadmin knowhow.

Required CPAN modules: `GD Template::Toolkit`. There are two ways to install these:

Firstly you ought to install Perl modules to process graphics and templates (**On your own server these must be available globally for your fcgiwrap to access them. Install as root/sudo to make them global?**):

```
$ cpan install Template::Toolkit
```

To enable graphics support on Perl, it is necessary to install dependent packages in your environment. The `build-essential` and `libgd-dev` packages are used to build the GD library which is used for graphics processing. (This step is not necessary on Strawberry Perl for Windows). For Debian Linux, do the following:

```
# apt install build-essential libgd-dev
$ cpan install GD
```

GD may already be installed if you are using shared hosting. You can also install it using your system package manager (apt, yum, pacman, etc).

## Alterntaive (easier) route: Avoid cpan and use the distro packager
If you don't fancy building Perl modules from source using CPAN, I don't blame you for thinking that way. You could just install the needed Perl modules from your Linux distro's package manager:

```
# apt install libgd-perl libtemplate-perl 
```

Then you must enable FastCGI on your web server. It should be straightforward enough to find a guide somewhere. Or, it is likely already enabled if you use shared hosting. Flegger should 'just work' if placed under the cgi-bin directory and given permissions of `chmod 755`.

Also make sure that flegger has the executable bit set:

```
$ chmod +x flegger.pl
```

*Note:* If you have filesystem images enabled you will want to run regular cleanup on `./img`. Flegger uses embedded images by default so this shouldn't be a problem, unless you want the rendered flags to be persisted.

## Hit counter setup
By default the count is stored in a file at `../count.txt`, i.e. one directory above your cgi-bin, or wherever you have placed `fleg.pl`. This file must be writable by the process running `fleg.pl` or the hit counter will not work. 

If you want to change the filename or path of count.txt, simply edit the value of `$COUNT_FILE` in `fleg.pl`.

# Why CGI?
You're right to ask this, most folks recommend all serious Perl webdev use a serious framework like Mojolicious.

In our case, these are simple scripts that you bung on a server. A full web framework is overkill. They just do their thing and be done. This is a throwback to simpler times where you just throw your scripts onto a server and worry no more.

Besides, with CGI, it is possible to run more than one script easily. It isn't so easy to run more than one web framework unless you really enjoy the intricacies (and the headaches) of vhost configuration.
