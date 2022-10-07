THRANSOFT CGI-WIN
=========================
Fun CGI scripts for the modern web.

# CONTENTS
What's inside?

### Fleg.pl
Flag generator. Bonus: Will also generate a country name.

# SETUP - All
We assume that:
* You have Perl installed
* CPAN or cpanm bootstrapped.
* Some Unix sysadmin knowhow.

Firstly you ought to install Perl modules to process CGI and templates (**On your own server these must be available globally for your fcgiwrap to access them. Install as root/sudo to make them global?**):

```
$ cpan install CGI Template::Toolkit
```

Or on Debian simply run:

```
# apt install libgd-perl libtemplate-perl libcgi-pm-perl
```

Then you must enable FastCGI on your web server. I use Nginx so that's all I will detail. Apache instructions are available everywhere.

```
# apt install nginx fcgiwrap
```

Howto [enable FastCGI on NGinx](https://sleeplessbeastie.eu/2017/09/18/how-to-execute-cgi-scripts-using-fcgiwrap/).

## Setup - Fleg.pl
To enable graphics support on Perl, it is necessary to install dependent packages in your environment. (This step is not necessary on Strawberry Perl for Windows). For Debian Linux, do the following:

Open a command window and run the following as root/sudo:
```
# apt install build-essential libgd-dev
```

Then install GD using CPAN. This is required for all hosts:

```
$ cpan install GD
```

GD may already be installed if you are using shared hosting. You can also install it using your system package manager (apt, yum, pacman, etc).

*Note:* You will want to run regular cleanup on `/img` until we use embedded images.

# Why CGI?
You're right to ask this, I'd recommend all serious Perl webdev use a serious framework like Mojolicious.

In our case, these are simple scripts that you bung on a server. A full web framework is overkill. They just do their thing and be done. This is a throwback to simpler times where you just throw your scripts onto a server and worry no more.

Besides, with CGI, it is possible to run more than one script easily. It isn't so easy to run more than one web framework unless you really enjoy the intricacies (and the costs) of server admin.
