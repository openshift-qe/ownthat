# OwnThat

This is a web app with REST API interface to help lock resources between
independent executor processes.

e.g. you have a number of executors doing some tasks on random machines.
They can use this app to reserve resources to avoid duplicate work.

Or one can have pools of resources and allow executor processes reserve from
them. There is some more info in the app index page.

TODO: document the following:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Deploying on OpenShift 2.x

Note that OpenShift v2 is now superceded by
OpenShift v3 which works with standard docker images. These instructions are
useful until a public v3 service is readily available.

So how to deploy in OpenShift v2:
```
rhc create-app <app name> diy \
  MYSQL_HOST=mysql_server \
  MYSQL_DB=mydatabase \
  MYSQL_USER=username \
  MYSQL_PASSWORD='pswd' \
  AUTHZ_DB='{"admin":{"master":"masteruser_pswd"},"user":{"user":"user_pswd"}}' \
  SECRET_KEY_BASE=`bin/rails secret` \
  -n my_namespace

cd <app name>
git remote add upstream https://github.com/openshift-qe/ownthat.git
git fetch upstream
git reset --hard upstream/master
git push origin +HEAD
```

Please note that you could also use a mysql OpenShift cartridge but since I
wanted to use an external server, I hardcode it. To make work with mysql
cartridge you'd have to set the above variables inside `start` hook based on
the `MYSQL_*` variables created by the mysql cart.

Note:

Usually one can use the `--from-code "https://github.com/akostadinov/ownthat.git"` option when creating the app. The problem is that rvm/ruby installation and the gems take too long. So the command fails. Command times out and app is removed without ability to debug what went wrong.

So I fugured I can create a DIY app without code and then import app code.
In that way during `git push` you can see what is going on with the hooks as
well it now allows more time for the operations to complete.

FYI the only needed change to run under OpenShift was creation of the action hooks under the `openshift` directory.
