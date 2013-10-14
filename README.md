# Rumble Bootstrap

Rumble Bootstrap is an attempt to reduce the amount of time spent in DevOps
during Rails Rumble to allow developers to focus more on building a kickass app.
Consisting of a small `bootstrap.sh` and a few configuration files, it is meant
to be forked, tweaked, and run on a fresh Linode.

tl;dr Less sysadminning, moar coding!

![Automate all the things!](http://www.kitchensoap.com/wp-content/uploads/2012/07/automate_all_the_things.jpeg)

## What It Does

This bootstrap is meant to be run on a fresh Linode. When run, it will handle:

* Updating your `/etc/apt/sources.list`
* Upgrading already installed packages
* Setting the timezone to `Etc/UTC`
* Setting the hostname and adding it to `/etc/hosts`
* Setting and generating locales for `en_US.utf8`
* Configuring deploy keys for everyone in `config/deploy_keys.txt`
* Adding Rails Rumble's key to the `root` user (they sorta require that)
* Adding some fancy informational messages from `config/motd.tail` and `config/issue.net`
* Installing Dokku to allow Heroku-style deployments
* Configures Dokku to link deployed apps to `/home/git/apps/<app name>`

### Doku

The real magic is the use of Dokku which uses Docker to allow git deployments in
a manner very similar to Heroku. It even supports Heroku's own
[buildpacks](https://devcenter.heroku.com/articles/buildpacks) so you'll feel at
right at home if you're already accustomed to pushing and forgetting.

Management is handled over SSH:

    $ ssh root@example.com dokku <command>

## Installation

* Fork this repository.
* Clone, edit files within `config/`, commit, and push.
* Bootstrap your server with:

  ```
  $ export BOOTSTRAP_REPO="https://github.com/<your GitHub user>/rumble-bootstrap.git" \
    export HOSTNAME="example.com" \
    wget -qO- https://raw.github.com/<your GitHub user>/rumble-bootstrap/master/bootstrap.sh | sudo bash
  ```

## Configuration

You'll notice a few files within `config/`:

* `deploy_keys.txt` - These are the SSH keys of the teamates (you trust). They are specified as `<public key> <identifier>` and separated by a newline.
* `dokku-plugins.txt` - These are the [Dokku plugins](https://github.com/progrium/dokku/wiki/Plugins) that will be installed. They are specified as `<repository URL> <plugin name>` and separated by a newline.
* `issue.net` - This is a message that will be displayed to anyone attempting to access the server over SSH.
* `motd.tail` - This is a message that will be displayed to anyone after signing into the server over SSH.
* `resolv.conf` - This is copied to `/etc/resolv.conf` on the server. By default, `8.8.8.8`, and `8.8.4.4` are used (the addresses for [Google Public DNS](https://developers.google.com/speed/public-dns/)).

## Deployment

* Add a new git remote pointing to your server:

  ```
  $ git remote add production git@example.com:appname
  ```

* Push it!

  ```
  $ git push production master
  Counting objects: 93, done.
  Delta compression using up to 8 threads.
  Compressing objects: 100% (80/80), done.
  Writing objects: 100% (93/93), 16.47 KiB, done.
  Total 93 (delta 18), reused 0 (delta 0)
  -----> Building appname ...
         Ruby/Rails app detected
  -----> Using Ruby version: ruby-2.0.0
  -----> Installing dependencies using Bundler version 1.3.2
         Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin --deployment
         Fetching gem metadata from https://rubygems.org/..........
         Fetching gem metadata from https://rubygems.org/..
         Installing rake (10.1.0)
         Installing i18n (0.6.5)
         Installing minitest (4.7.5)
         Installing multi_json (1.8.1)
         Installing atomic (1.1.14)
         Installing thread_safe (0.1.3)
         Installing tzinfo (0.3.38)
         Installing activesupport (4.0.0)
         Installing builder (3.1.4)
         Installing erubis (2.7.0)
         Installing rack (1.5.2)
         Installing rack-test (0.6.2)
         Installing actionpack (4.0.0)
         Installing mime-types (1.25)
         Installing polyglot (0.3.3)
         Installing treetop (1.4.15)
         Installing mail (2.5.4)
         Installing actionmailer (4.0.0)
         Installing activemodel (4.0.0)
         Installing activerecord-deprecated_finders (1.0.3)
         Installing arel (4.0.0)
         Installing activerecord (4.0.0)
         Installing coffee-script-source (1.6.3)
         Installing execjs (2.0.2)
         Installing coffee-script (2.2.0)
         Installing thor (0.18.1)
         Installing railties (4.0.0)
         Installing coffee-rails (4.0.0)
         Installing hike (1.2.3)
         Installing jbuilder (1.5.2)
         Installing jquery-rails (3.0.4)
         Installing json (1.8.0)
         Installing puma (2.6.0)
         Using bundler (1.3.2)
         Installing tilt (1.4.1)
         Installing sprockets (2.10.0)
         Installing sprockets-rails (2.0.0)
         Installing rails (4.0.0)
         Installing rails_serve_static_assets (0.0.1)
         Installing rails_stdout_logging (0.0.2)
         Installing rails_12factor (0.0.2)
         Installing rdoc (3.12.2)
         Installing sass (3.2.12)
         Installing sass-rails (4.0.0)
         Installing sdoc (0.3.20)
         Installing turbolinks (1.3.0)
         Installing uglifier (2.2.1)
         Your bundle is complete! It was installed into ./vendor/bundle
         Post-install message from rdoc:
         Depending on your version of ruby, you may need to install ruby rdoc/ri data:
         <= 1.8.6 : unsupported
         = 1.8.7 : gem install rdoc-data; rdoc-data --install
         = 1.9.1 : gem install rdoc-data; rdoc-data --install
         >= 1.9.2 : nothing to do! Yay!
         Cleaning up the bundler cache.
  -----> Writing config/database.yml to read from DATABASE_URL
  -----> Preparing app for Rails asset pipeline
         Running: rake assets:precompile
         I, [2013-10-14T06:50:10.692054 #315]  INFO -- : Writing /build/app/public/assets/application-4cff4cfa900c9ab69642fd37ecc042c3.js
         I, [2013-10-14T06:50:10.715501 #315]  INFO -- : Writing /build/app/public/assets/application-fcaf00575f22248c2a6c65b51c007040.css
         Asset precompilation completed (3.88s)
         Cleaning assets
  -----> Discovering process types
         Procfile declares types -> web
         Default process types for Ruby/Rails -> rake, console, web, worker
  -----> Build complete!
  -----> Releasing appname ...
  -----> Release complete!
  -----> Deploying appname ...
  -----> Deploy complete!
  -----> Cleaning up ...
  -----> Cleanup complete!
  =====> Application deployed:
         http://appname.example.com

  To git@example.com:appname
   * [new branch]      master -> master
  ```
