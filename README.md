THRANSOFT CGI-WIN
=========================
Fun CGI scripts for the modern web.

# CONTENTS
What's inside?

## Fleg.pl
Flag generator. Bonus: Will also attempt to generate a country name.

# SETUP - All
We assume that:
* You have Perl installed
* CPAN or cpanm bootstrapped.
* Some Unix sysadmin knowhow.

Firstly you ought to install Perl modules to process CGI and templates:

`cpan install CGI Template::Toolkit`

Then you must enable FastCGI on your web server. I use Nginx so that's all I will detail. Apache instructions are available everywhere.

```
# apt install nginx fcgiwrap
```

## Setup - Fleg.pl
To enable graphics support on Perl, it is necessary to install dependent packages in your environment. (This is not necessary on Strawberry Perl for Windows). For Debian Linux, do the following:

Open a command window and run the following as root/sudo:
```
# apt install build-essential libgd-dev
```

Then install GD using CPAN:

```
$ cpan install GD
```

GD may already be installed if you are using shared hosting.

# Why CGI?
You're right to ask this, I'd recommend all serious Perl webdev use a serious framework like Mojolicious.

In our case, these are simple scripts that you bung on a server. A full web framework is overkill. They just do their thing and be done. This is a throwback to simpler times where you just throw your scripts onto a server and worry no more.

Besides, with CGI, it is possible to run more than one script easily. It isn't so easy to run more than one web framework unless you really enjoy the intricacies (and the costs) of server admin.
