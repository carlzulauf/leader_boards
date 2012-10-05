# Attempt to Build Super Fast Leaders Server

Created cloud server

* Rackspace Cloud Server, 512MB Instance
* Ubuntu 12.04
* Public IP: 198.61.167.68 / 2001:4801:7817:0072:beba:ef27:ff10:2420
* Private IP: 10.177.13.208
* Root Password: Gtb34KXKwSj3

## Install Log

First, logged in as root and created user `carl`. By adding `carl` to `sudo` group we don't have to `visudo` and touch the sudoer's config. `sudo` group gets `sudo` access by default.

    $ adduser carl
    $ usermod -a -G sudo carl
    $ groups carl
    => carl : carl sudo
    $ exit

SSH as `carl` to IP address. Works. Make `.ssh` directory.

    $ mkdir .ssh

SCP authorized keys.

    $ scp .ssh/authorized_keys carl@198.61.167.68:.ssh/authorized_keys

Log into Zonomi and point `leaders.linkleaf.com` to IP address. Works immediately.

Test SSH to `carl@leaders.linkleaf.com`. Works.

Update all currently installed packages.

    $ sudo apt-get update
    $ sudo apt-get upgrade

Reboot system now for good measure. Ensures kernel updates work right, I think.

Looked at output from `apt-get install ruby1.9.3`. X components? Really?!

The `ruby1.9.1` package seems to have more reasonable dependencies. Lets start with that plus the minimums to install my dotfiles and the rvm function, plus the always-required-for-anything-I-want-to-compile, `build-essential`.

    $ sudo apt-get install git curl ruby1.9.1 build-essential openssl tmux

Attempt to clone dotfiles repository. Realize its on my local network and I can't SSH to it from the new server. Time to move it to the prgmr.com server.

### Changing Location of `dotfiles` Repository

SSH to `exanotes.com` and make sure a reasonable bare clone of dotfiles is available at `~/git/dotfiles`. Looks like it's there. Old though. Have `projects/dotfiles` on that server point to it and push some newer commits.

    $ cd projects/dotfiles
    $ git remote -v
    => origin carl@carl.linkleaf.com:git/dotfiles...
    $ git remote set-url origin ~/git/dotfiles
    $ git fetch
    $ git push
    => ... master -> master

Make sure any commits from local machine or **xig** are pushed. Repeat the process to change the remote origin url, except use `carl@exanotes.com:git/dotfiles`.

Need to copy ssh key to new server. This is ran from local machine:

    $ scp .ssh/id_* carl@leaders.linkleaf.com:.ssh

### Getting Back to Server Setup

Now we can clone dotfiles on new server.

    $ mkdir projects
    $ cd projects
    $ git clone carl@exanotes.com:git/dotfiles

Install dotfiles

    $ sudo gem install rake
    $ cd ~/projects/dotfiles
    $ rake install

No reason to keep backups around.

    $ rm -rf ~/.backup-dotfiles

Use the this line obtained from rvm.io to install rvm:

    $ \curl -L https://get.rvm.io | bash -s stable --ruby
    $ exit
    local$ ssh carl@leaders.linkleaf.com
    $ rvm requirements

Looks like rvm is installed, but it looks like I also need to install some more packages.

    $ sudo apt-get install libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libncurses5-dev automake libtool bison subversion pkg-config

Not sure I need *all* of those, but I install anyways.

Fix up awful things rvm does to my dot files.

    $ cat .bash_profile >> .bashrc
    $ rm .bash_profile
    $ rm .bash_logout
    $ exit
    local$ ssh carl@leaders.linkleaf.com

Cut my first Ruby of the night

    $ rvm install 1.9.3

Error caused mounting of remote ruby to fail. Haven't seen this before. Appears to be a new alternative to compiling? Anyways, wants readline5, which seems odd. Automatically and immediately moves on to compiling. No additional errors. 1.9.3 appears to be successfully installed.

### Clone Leader Board App

We need an app to run. Using a public github repo of mine, `carlzulauf/leader_boards`.

    $ cd ~/projects
    $ git clone git@github.com:carlzulauf/leader_boards

### Install Required Gems and Redis

App uses Redis for storage and bundler to manage gems. Should be simple. Will go with repo version of Redis for now.

    $ sudo apt-get install redis-server
    $ cd leader_boards
    $ bundle install

## Server Setup/Config Log

First, we are going to try thin. Gemfile points to github for `redis-native_hash` so we'll need to install that since we want to use thin outside of bundler for now.

    $ gem install redis-native_hash
    $ gem install thin
    $ thin start

Works fine on non-standard ports, but won't listen on port 80. Hmm.

After searching, determined linux doesn't allow listening on ports below 1024 without root privileges. This cannot be impossible, so I keep digging. Jesus, this is a bit insane. Found solution though.

    $ sudo apt-get install libcap2-bin
    $ sudo setcap cap_net_bind_service=ep `which ruby`
    $ thin start -p 80

### Thin Performance

Initial blitz.io time. Lets see what thin performance looks like.

Need to prove we own the domain first.

    $ cd public
    $ echo '42' > mu-2f016297-18aa81b2-d5707d7e-2feeb879.txt

Go to blitz.io and start the rush

    --pattern 1-250:60 --timeout 10000 http://leaders.linkleaf.com/

Pretty linear scaling until ~80 requests/second. Seems to hit a wall there.

Only 3 scores in redis. Lets try to flood the system with values using blitz.io variables. This will also test write performance.

    --pattern 1-250:60 --timeout 10000 -v:score number[95,999] -v:name [Chad,Paul,Tony,Malinda,Brian,Peter,Heather,Samantha,Calvin,Zen,Pluto] http://leaders.linkleaf.com/submit?name=#{name}&score=#{score}

Holy shit. Writes don't slow down until 180 requests/second, and then still keep inching up. More than twice as fast as showing the leader board. Guessing blitz stops at the redirect, so this measures pure ruby-to-redis performance with no template (haml) rendering.

