#!/bin/sh

cd /pb
cat << "EOD"
                                         ___  ___                           _
                                         |  \/  |                          | |
                                         | .  . | __ _ _ __ _ __ ___   ___ | |_
                                         | |\/| |/ _  | '__| '_   _ \ / _ \| __|
                                         | |  | | (_| | |  | | | | | | (_) | |_
                                         \_|  |_/\__,_|_|  |_| |_| |_|\___/ \__|

This data is sample database from http://2016.padjo.org/files/data/starterpack/ssa-babynames/ssa-babynames-nationwide-since-1980.sqlite
             (Marmot doesn't support schema changes replication, so make sure it boots with same DB state everywhere)
                                    Database was prepared and imported into local PocketBase
EOD
tar vxzf ./pb_data.tar.gz


/pb/pocketbase serve --http=0.0.0.0:8080 &
PB_ID=$!

# Generate Node ID
NODE_ID=$(echo -n "$FLY_MACHINE_ID" | md5sum | cut -d' ' -f1 | rev | cut -c1-8 | tr -d '\n' | od -A n -vt u8)


MARMOT_CONFIG=$(cat << EOM
db_path="/pb/pb_data/data.db"
node_id=${NODE_ID}

[snapshot]
enabled=false

[replication_log]
shards=1
replicas=2
max_entries=1024
compress=true

[logging]
format="console"
EOM
)

echo "$MARMOT_CONFIG" > ./marmot-config.toml

# Start marmot in a loop
while true; do
    sleep 1

    # Launch!
    echo "Launching marmot with -config ./marmot-config.toml -cluster-addr [${FLY_PRIVATE_IP}]:4222 -cluster-peers dns://global.${FLY_APP_NAME}.internal:4222/"
    /pb/marmot -config ./marmot-config.toml -cluster-addr "[${FLY_PRIVATE_IP}]:4222" -cluster-peers "dns://global.${FLY_APP_NAME}.internal:4222/" &
    MARMOT_ID=$!

    # Wait for marmot to exit
    wait $MARMOT_ID

    # Restart Marmot
    echo "Marmot needs to be running all the time, restarting..."
    sleep 1
done


# Define a cleanup function
cleanup() {
    echo "Caught signal, stopping."
    kill $PB_ID $MARMOT_ID
}

# Set the trap
trap cleanup TERM INT KILL

wait $PB_ID $MARMOT_ID
