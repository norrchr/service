# eggdrop service script: service.tcl
service modular-git BETA version, use at your own risk, script may contain bugs which may crash your bot, or totally bork your irc channel.

# Requirements:

tcllib - required for the inifile package to read the config and commands file

# Installation:

cd to your eggdrop's scripts directory, and type: git clone https://github.com/r0t3n/service.git

cd service

cp -f service.conf.example service.conf


edit service.conf, changing the homechan/adminchan/helpchan variables. This is the minimal setup, you may go through and change the default kickmsg values, but generally dont touch anything else, especially the chanflags array.

Edit your eggdrops config file, and add 'source scripts/service/service.tcl' to the end of it. If the bot is loaded, rehash it, otherwise start your bot.

# Upgrade:

cd to scripts/service/ and type: git pull

this will download all the latest script updates, then rehash your eggdrop.

# Errors:

Please post a bug report, including as much information at possible to the issue tracker. errorInfo output will be helpful. 

# Help:

Contact r0t3n via quakenet.org channel #r0t3n

Webchat: http://webchat.quakenet.org/?channels=#r0t3n

# Feature requests

Contact via IRC or add a feature request to the issue tracker
