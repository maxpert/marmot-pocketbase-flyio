# Combining Marmot + PocketBase + Fly.io 

## What is Marmot?

[Marmot](https://github.com/maxpert/marmot) is an distributed SQLite replicator that runs as a side-car to you service, and replicates data across cluster using NATS. 

## What is PocketBase?
[PocketBase](https://github.com/pocketbase/pocketbase) is an open source backend consisting of embedded database (SQLite) with realtime subscriptions, built-in auth management, convenient dashboard UI and simple REST-ish API.

## What is Fly.io?
Fly is a platform for running full stack apps and databases close to your users. Compute jobs at Fly.io are virtualized using Firecracker, the virtualization engine developed at AWS as the engine for Lambda and Fargate. 

## Why should I care?
This demo effectively shows how PocketBase can be pushed closer to the edge. After developer has done local development, and finalized schema, a literal copy of the DB can be deployed in production. These nodes scale up or down based on traffic, and write from everywhere. This can horizontally scales your PocketBases close to the user. With NATS embedded into Marmot, a sharded RAFT is used to capture changes, and replay them across the fly nodes (multi-primary replicas). 

## Important Notes:
 - **Cluster instances have to start with same DB snapshot** - Since Marmot doesn't support schema level change propagation, 
    tables, indexes you will be creating, deleting won't be picked up. Marmot only transports data right now! This
    repo ships with sample data snapshot that was created using local PocketBase instance, so it should give you
    good starting point. You only need schema of tables + indexes in order to see replication working. This should 
    not be a no big deal because one can easily write a script to apply migrations (recommended way), use the 
    backup to import old data, and deploy it as part of Docker image. 
 - **Change propagation is dependent on PocketBase committing to disk** - Marmot can only propagate changes that are written
    to disk! Marmot does not use any hooks or anything into PocketBase process. As a matter of fact Marmot doesn't
    even care whats running along side with it.
 - **This example doesn't use persistent volume** - Base snapshot and logs in Marmot nodes should be enough to get you
   up and running every-time. You can configure Marmot with S3/Minio snapshots for higher reliability. 

## Install Flyctl

 - Follow the installation instructions from https://fly.io/docs/hands-on/install-flyctl/.
 - Run `fly auth signup` to create a Fly.io account (email or GitHub).
 - Run `fly auth login` to login.

## Deploy and Scale

 - Create Fly app using `fly app create`, fill in the information on prompts.
 - Deploy on app using `fly deploy -a <application-name>`, here `application-name` will be the name of app you created
 - Scale the app to multiple pods you `fly scale count 3 -a <application-name>`. At least have 2 pods for Marmot to 
   start a cluster (in current configuration), otherwise Marmot would keep waiting for more nodes to come up.

## Create Admin

Once cluster is started go to `http://<application-name>.fly.dev/_/` to launch admin panel, it will prompt you to create an
admin account. Choose your email and password. Once you hit create, it will create your admin account. 

  > PocketBase might show you an error saying invalid token. If that happens just wait for a second or so to let 
  > changes propagate. Try reloading `http://<application-name>.fly.dev/_/` until you see login form. If issue 
  > persists try creating account again.

## Use the APIs

Now you can play with your app's API using `http://<application-name>.fly.dev/api/`. Checkout 
[PocketBase Docs](https://pocketbase.io/docs/) for deep dive.