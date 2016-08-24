# OwnThat

This is a web app with REST API interface to help lock resources between
independent executor processes.

e.g. you have a number of executors doing some tasks on random machines.
They can use this app to reserve resources to avoid duplicate work.

Please look at `master` branch for generic info. This branch is to help run
the app inside OpenShift v2. Note that OpenShift v2 is now superceded by
OpenShift v3 which works with standard docker images. This branch is to be used
until v3 online service becomes available.

So how to deploy in OpenShift v2:
```
rhc create-app ownthatauto diy \
  MYSQL_HOST=mysql_server \
  MYSQL_DB=mydatabase \
  MYSQL_USER=username \
  MYSQL_PASSWORD='pswd' \
  AUTHZ_DB='{"admin":{"master":"masteruser_pswd"},"user":{"user":"user_pswd"}}' \
  SECRET_KEY_BASE=`bin/rails secret` \
  -n aosqe --from-code "https://github.com/akostadinov/ownthat.git#OSOv2"
```

Please note that you could also use a mysql OpenShift cartridge but since I
wanted to use an external server, I hardcode it. To make work with mysql
cartridge you'd have to set the above variables inside `start` hook based on
the `MYSQL_*` variables created by the mysql cart. Also you'd have to run
database migrations in the `deploy` hook.

For any changes to the default app to make work with OpenShift v2 DIY cart,
please see [last commit](https://github.com/akostadinov/ownthat/commit/OSOv2) in this branch. Basically it has:
* start/stop/deploy scripts
* enable `therubyracer` gem as that's the simplest way to make execjs happy in this environment

Note:

In my test environment I had an issue that app creation failed with error thatserver didn't respond in time. I didn't have time to investigate, perhaps too long time to install gems. End result being app is removed so one can only try again without opportunity to debug.

So I fugured I can create a DIY app without code and then import app code. Then during `git push` you can see what is going on with the hooks as well it now was able to start/stop the app.
```
git remote add upstream ...
git fetch upstream
git reset --hard upstream/OSOv2
git push origin +HEAD
```

HTH
