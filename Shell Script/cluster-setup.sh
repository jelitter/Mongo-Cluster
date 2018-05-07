#  ---------------------------------------------------------------------------------------
#          Main Function
#  ---------------------------------------------------------------------------------------
function main() {
    pkill mongod
    pkill mongos
    sudo service mongod stop

    local hostname="localhost"
    local structure=`clusterStructure`
    local directory=`get_rtrn $structure 1`
    local shards?dir=`get_rtrn $structure 2`
    local config_dir=`get_rtrn $structure 3`

    setup_cluster $directory $shards_dir $config_dir $hostname
    config_cluster $shards_dir $hostname
    importDatabase
    shardCollection $hostname
    clean_cluster
    pkill mongod
    pkill mongos
}


#  ---------------------------------------------------------------------------------------
#          setup_cluster function: to set up all components in a cluster
#  ---------------------------------------------------------------------------------------
function setup_cluster() {
    cd $1
    createShards $2 $4
    cd ..
    createConfigServers $3 $4
    createInterfaces $3 $4
}


#  ---------------------------------------------------------------------------------------
#          helper function to extract the multiple return variables
#  ---------------------------------------------------------------------------------------
function get_rtrn() {
    echo `echo $1|cut --delimiter=, -f $2`
}


#  ---------------------------------------------------------------------------------------
#          clusterStructure Function: organize the components of a cluster
#  ---------------------------------------------------------------------------------------
function clusterStructure() {
    local directory ="cluster"
    local shards_dir ="shards"
    local config_dir ="configServers"

    rm -r $directory
    mkdir $directory
    cd $directory
    mkdir $shards_dir
    mkdir $config_dir

    echo "$directory,$shards_dir,$config_dir"
}


#  ---------------------------------------------------------------------------------------
#          createShards Function: create shards for a cluster
#  ---------------------------------------------------------------------------------------
function createShards() {
    createShardDirs $1
    local num_shards = $?

    allocatePorts $num_shards
    triggerServers $1
    createReplicaSet $1 $2
}


#  ---------------------------------------------------------------------------------------
#          createShardDirs Function: create a directory for each shard
#  ---------------------------------------------------------------------------------------
function createShardDirs() {
    cd $1
    
    read -p "How many shards do ou want in your cluster?" num_shards
    while (( $num_shards <= 0 ))
    do
        read -p "How many shards do ou want in your cluster?" num_shards
    done

    for (( ishard=1; ishard <= $num_shards; ishard++ ))
    do
        mkdir $1$ishard
        createShardNodes $1$ishard
        numNodes+=($?)
        cd ..
    done

    return ${num_shards}
}



#  ---------------------------------------------------------------------------------------
#          createShardNodes Function: create nodes for each shard
#  ---------------------------------------------------------------------------------------
function createShardNodes() {
    cd $1
    local node_dir = "node"

    getNumNodes
    local num_nodes = $?

    for (( inode=1; inode <= $num_nodes; inode++ ))
    do
        $node_dir$inode
    done

    return ${num_nodes}
}



#  ---------------------------------------------------------------------------------------
#          getNumNodes Function: get the number of nodes for each shard
#  ---------------------------------------------------------------------------------------
function getNumNodes() {
    read -p "How many nodes do you need for one shard?" num_nodes
    while (( $num_nodes > 51) || ( $num_nodes < 3))
    do
        read -p "How many nodes do you need for one shard?" num_nodes
    done

    return ${num_nodes}
}


#  ---------------------------------------------------------------------------------------
#          allocatePorts Function: store the first port numbers for each shard
#          into an array
#  ---------------------------------------------------------------------------------------
function allocatePorts() {
    for (( ishard = 1; ishard <= $1; ishard++))
    do

        read -p "What is your port number for the first node in a shard?" port
        while (( ($port == $MONGOD_PORT) || ($port == $MONGOD_SHARD_PORT) || ($port == $MONGOD_CONFIG_PORT) ))
        do
            read -p "What is your port number for the first node in a shard?" port
        done

        # To check if the port number is in the array
        local exists = false
        for num in ${ports[@]}
        do
        if [ $num == $port ]
            then
                exists = true
                break;
            else
                exists = false
            fi
        done

        while $exists
        do 
            read -p "What is your port number for the first node in a shard?" port
            for num in ${ports[@]}
            do
                if [ $num == $port ]
                then
                    exists = true
                    break;
                else
                    exists = false
                fi
            done
        done

        ports += ($port)
    done
}














