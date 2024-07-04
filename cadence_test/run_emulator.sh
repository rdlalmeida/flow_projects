#!/bin/bash

# Database Setup
# export $DB_PATH=./flowdb
DB_PATH=./flowdb

# Create the database directory if it does not exist yet
if [ ! -d "$DB_PATH" ];
then
	mkdir $DB_PATH
	echo "Created a new database directory at '${DB_PATH}'"
fi

# NOTE: The following variables were defined as environment variables instead via ~/.mongoshrc.js
MONGO_INITDB_DATABASE=cadence_test_emulator_database
MONGO_INITDB_USERNAME=cadence_test_emulator
MONGO_INITDB_PASSWORD=cadencetestemulatorpassword

# Inits Mongo database and inserts the user if needed
mongosh -- "${MONGO_INITDB_DATABASE}" <<EOF
	// Set the credentials to use
	var rootUser = '${MONGO_INITDB_USERNAME}';
	var rootPassword = '${MONGO_INITDB_PASSWORD}';
	var emulatorDatabase = '${MONGO_INITDB_DATABASE}';
	
	// Set the success response (JSON object) to a dedicated variable for later comparisson
	var successResponse = { ok:1 };	

	// Try to authenticate into the provided database with the credentials provided, saving the returned response into a variable
	let response = db.auth(rootUser, rootPassword);

	db = db.getSiblingDB(emulatorDatabase);

	// Check if a success response was returned when attempted to login into the database. If so, inform the user, otherwise proceed to create the user and password and login into them
	
	if (JSON.stringify(response) == JSON.stringify(successResponse)) {
		// User login successful. Nothing more to do. Log the operation and move on
		console.log("Login successful with user '".concat("${MONGO_INITDB_USERNAME}").concat("' into database '").concat("${MONGO_INITDB_DATABASE}").concat("'"));	
	} else {
		// The user doesn't exist yet. Create it
		db.createUser({ user: rootUser,
				pwd: rootPassword,
				roles:[ { role: "readWrite",
				db: emulatorDatabase 
		} ],
		mechanisms: [ "SCRAM-SHA-1" ]
		});

		// And login into the newly created credential pair
		let response = db.auth(rootUser, rootPassword)
		
		// Inform the user
		console.log("User '".concat(${MONGO_INITDB_USERNAME}).concat(" in database '").concat(${MONGO_INITDB_DATABASE}).concat("'"));
		
		// All good. Exit the command line
		quit;
	}
EOF


# export $FLOW_JSON=./flow.json
FLOW_JSON=./flow.json

if [ ! -f "$FLOW_JSON" ];
then
	# export $INIT=true
	INIT=true
else
	# export $INIT=false
	INIT=false
fi

# export $PORT=3569
PORT=3569

# export $ADMIN_PORT=8080
ADMIN_PORT=8080

# export $REST_PORT=8888
REST_PORT=8888

# export $VERBOSE=true
VERBOSE=true

# export $LOG_FORMAT=text
LOG_FORMAT=text

# export $BLOCK_TIME=0ms # (Valid time units: ns, us, ms, s, m or h)
BLOCK_TIME=0ms

# export $CONTRACTS=false
CONTRACTS=false

# export $SERVICE_PRIV_KEY=680fa28962650ef346a7edf23d63967b0fcf44958488d0d48f8539ece6e92eba
SERVICE_PRIV_KEY=680fa28962650ef346a7edf23d63967b0fcf44958488d0d48f8539ece6e92eba

# export $SERVICE_PUB_KEY=5a6a7bdb81838e40fc615d4c0eed3d4caacfc7f47a89d319caa370aac6196113573738ba57e09ea5a27a192d48457ee5c0e32011bc10ef93383aabad24a9ce2a
SERVICE_PUB_KEY=5a6a7bdb81838e40fc615d4c0eed3d4caacfc7f47a89d319caa370aac6196113573738ba57e09ea5a27a192d48457ee5c0e32011bc10ef93383aabad24a9ce2a

# export $SERVICE_SIG_ALGO=ECDSA_P256
SERVICE_SIG_ALGO=ECDSA_P256

# export $SERVICE_HASH_ALGO=SHA3_256
SERVICE_HASH_ALGO=SHA3_256

# export $REST_DEBUG=false
REST_DEBUG=false

# export $GRPC_DEBUG=false
GRPC_DEBUG=false

# export $PERSIST=true
PERSIST=true

# export $SIMPLE_ADDRESSES=false
SIMPLE_ADDRESSES=false

# export $TOKEN_SUPPLY=1000000000.0
TOKEN_SUPPLY=1000000000.0

# export $TRANSACTION_EXPIRY=10
TRANSACTION_EXPIRY=10

# export $STORAGE_LIMIT=true
STORAGE_LIMIT=true

# export $STORAGE_PER_FLOW=1
# STORAGE_PER_FLOW=1

# export $MIN_ACCOUNT_BALANCE=100000
# MIN_ACCOUNT_BALANCE=100000

# export $TRANSACTION_FEES=false
TRANSACTION_FEES=false

# export $TRASACTION_MAX_GAS_LIMIT=9999
TRANSACTION_MAX_GAS_LIMIT=9999

# export $SCRIPT_GAS_LIMIT=100000
SCRIPT_GAS_LIMIT=100000

command_string="flow emulator start --port=${PORT} --rest-port=${REST_PORT} --admin-port=${ADMIN_PORT} --verbose=${VERBOSE} --log-format=${LOG_FORMAT} --block-time=${BLOCK_TIME} --contracts=${CONTRACTS} --service-priv-key=${SERVICE_PRIV_KEY} --service-pub-key=${SERVICE_PUB_KEY} --service-sig-algo=${SERVICE_SIG_ALGO} --service-hash-algo=${SERVICE_HASH_ALGO} --init=${INIT} --rest-debug=${REST_DEBUG} --grpc-debug=${GRPC_DEBUG} --persist=${PERSIST} --dbpath=${DB_PATH} --simple-addresses=${SIMPLE_ADDRESSES} --token-supply=${TOKEN_SUPPLY} --transaction-expiry=${TRANSACTION_EXPIRY} --storage-limit=${STORAGE_LIMIT}"

if [ -n "$STORAGE_PER_FLOW" ];
then
	command_string="${command_string} --storage-per-flow=${STORAGE_PER_FLOW}"
fi

if [ -n "$MIN_ACCOUNT_BALANCE" ];
then
	command_string="${command_string} --min-account-balance=${MIN_ACCOUNT_BALANCE}"
fi

command_string="${command_string} --transaction-fees=${TRANSACTION_FEES} --transaction-max-gas-limit=${TRANSACTION_MAX_GAS_LIMIT} --script-gas-limit=${SCRIPT_GAS_LIMIT}"

# Command composed. Run it
echo "Running FLOW emulator with '${command_string}'...\n"
eval $command_string
