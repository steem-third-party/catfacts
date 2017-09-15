catfacts
==========

[Cat Facts](https://github.com/steem-third-party/catfacts) is a fork for [Freakazoid](https://github.com/inertia186/freakazoid) that uses [Cat Facts API](https://catfact.ninja) responses to STEEM as bot replies.  Unlike Freakazoid, this bot works without having to register for an API key.

<center>
  <img src="https://i.imgur.com/Iaz1jZi.jpg" />
</center>

---

This bot will automatically reply to posts and comments that reply to and mention the bot.  The replies are provided by the Cat Facts API.

The main reference implementation of Cat Facts is @catfacts.  For example:

<center>
  <img src="https://i.imgur.com/KUvEKoU.png" />
</center>

---

#### Install

To use this [Radiator](https://steemit.com/steem/@inertia/radiator-steem-ruby-api-client) bot:

##### Linux

```bash
$ sudo apt-get update
$ sudo apt-get install ruby-full git openssl libssl1.0.0 libssl-dev
$ sudo apt-get upgrade
$ gem install bundler
```

##### macOS

```bash
$ gem install bundler
```

I've tested it on various versions of ruby.  The oldest one I got it to work was:

`ruby 2.0.0p645 (2015-04-13 revision 50299) [x86_64-darwin14.4.0]`

You can try the system version of `ruby`, but if you have issues with that, use this [how-to](https://steemit.com/ruby/@inertia/how-to-configure-your-mac-to-do-ruby-on-rails-development), and come back to this installation at Step 4:

##### Setup

First, clone this git and install the dependencies:

```bash
$ git clone https://github.com/steem-third-party/catfacts.git
$ cd catfacts
$ bundle install
```

##### Configure

Edit the `config.yml` file.

```yaml
:catfacts:
  :block_mode: irreversible
  :account_name: <your STEEM bot name>
  :posting_wif: <your STEEM bot posting key>

:chain_options:
  :chain: steem
  :url: https://steemd.steemit.com
```

Edit the `support/reply.md` template (optional).

##### Run Mode

Then run it:

```bash
$ rake run
```

Cat Facts will now do it's thing.  Check here to see an updated version of this bot:

https://github.com/steem-third-party/catfacts

---

#### Upgrade

Typically, you can upgrade to the latest version by this command, from the original directory you cloned into:

```bash
$ git pull
```

Usually, this works fine as long as you haven't modified anything.  If you get an error, try this:

```
$ git stash
$ git pull
$ git stash pop
$ bundle install
```

If you're still having problems, I suggest starting a new clone.

---

#### Troubleshooting

##### Problem: Everything looks ok, but every time Cat Facts tries to reply, I get this error:

```
Unable to reply with <account>.  Invalid version
```

##### Solution: You're trying to reply with an invalid key.

Make sure the `.yml` file contains the correct voting key and account name (`social` is just for testing).

##### Problem: The node I'm using is down.

Is there a list of nodes?

##### Solution: Yes, special thanks to @ripplerm.

https://ripplerm.github.io/steem-servers/

---

## Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://github.com/inertia186/catfacts.git`
* Navigate into the new folder
  * `cd catfacts`
* Basic tests can be invoked as follows:
  * `rake`
* To run tests with parallelization and local code coverage:
  * `HELL_ENABLED=true rake`

## Get in touch!

If you're using Cat Facts, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on STEEM and Discord.
  
## License

I don't believe in intellectual "property".  If you do, consider Cat Facts as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
