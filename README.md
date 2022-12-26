### About
https://github.com/zendbit/nim.couchdbapi is connection driver (REST API) to Apache CouchDb. This helper implements all functionality except the deprecated and authentication api.

### Installation
```
nimble install couchdbapi
```

### Usage
- Create couchdb object, the jwtToken is optional, if you want to use secure connection set secure to true (default false)
```nim
import couchdbapi


proc Test() {.async.} =
  let couchDb = newCouchDb(
    username = "administrator",
    password = "administrator",
    databasePrefix = "zendblock",
    host = "127.0.0.1",
    port = 5984,
    jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbmlzdHJhdG9yIiwia2lkIjoiYWRtaW5pc3RyYXRvciIsInJvbGVzIjpbIl9hZG1pbiJdfQ.NWQiPIV_yO937Uzg9YHZvFxRR8_osvLaK-lrjhOhxnM")

  ## create database zendblock/users
  echo await couchDb.databasePut("users")
  
  ## create database zendblock/users-snapshot for snapshot/replication
  echo await couchDb.databasePut("users-snapshot")
  
  ## replicate database from zendblock/users to zendblock/users-snapshot
  echo await couchDb.serverPostReplicate(%*{
    "source": "users",
    "target": "users-snapshot"
  })
  
  ## Get database info
  echo await couchDb.serverPostDbsInfo(@["_users", "_replicator", "zendblock/users", "zendblock/users-snapshot"])
  
if isMainModule:
  waitFor Test()
```

### Create new document with attachment
```
proc newDocumentWithAttachments*(jsonData: JsonNode, attachments: seq[DocumentAttachment]): Future[tuple[body: string, boundary: string, length: int]] {.async.}
	##
	##	create new document with given attachment
	##	will automatic convert to multipart/related
	##	if the attachment not valid (fileContent) file path
	##	it will use that content as attachment filewill
	##
```

### Create new CouchDb object
```
proc newCouchDb*(
	username: string,
	password: string,
	database: string,
	host: string,
	port: int,
	jwtToken: string = "",
	secure: bool = false): CouchDb
	##
	##	create new couchdb instance
	##	jwt token is optional
	##	if jwt toke empty will use basic auth
	##
	##	CouchDb object
	##	hold couchdb information
	##	for secure/https set secure to true
	##	if jwt token exist default auth will use it
	##	if jwt token empty will fallback into basic auth
	##
```

### Get server information
Accessing the root of a CouchDB instance returns meta information about the instance. The response is a JSON structure containing information about the server, including a welcome message and the version of the server.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--
```
proc serverGetInfo*(self: CouchDb): Future[JsonNode] {.async.} =
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#get--
	##
```

### Get active tasks
List of running tasks, including the task type, name, status and process ID. The result is a JSON array of the currently running tasks, with each task being described with a single object. Depending on operation type set of response object fields might be different.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_active_tasks
```
proc serverGetActiveTasks*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_active_tasks
	##
```

### Get all databases in server
Returns a list of all the databases in the CouchDB instance.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_all_dbs
```
proc serverGetAllDbs*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#get--_all_dbs
	##
```

### Get database info
Returns a list of all the databases information in the CouchDB instance.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_dbs_info
```
proc serverGetDbsInfo*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, limit: int = 0, skip: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#get--_dbs_info
	##
```

### Post to get database info
Returns information of a list of the specified databases in the CouchDB instance. This enables you to request information about multiple databases in a single request, in place of multiple GET /{db} requests.

- see https://docs.couchdb.org/en/latest/api/server/common.html#post--_dbs_info
```
proc serverPostDbsInfo*(self: CouchDb, keys: seq[JsonNode]): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#post--_dbs_info
	##
```

### Get server cluster setup
Returns the status of the node or cluster, per the cluster setup wizard.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_cluster_setup
```
proc serverGetClusterSetup*(self: CouchDb, ensureDbsExist: seq[string] = @["_users", "_replicator"]): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_cluster_setup
	##
```

### Post to configure cluster, setup as node cluster
Configure a node as a single (standalone) node, as part of a cluster, or finalise a cluster.

- see https://docs.couchdb.org/en/latest/api/server/common.html#post--_cluster_setup
```
proc serverPostClusterSetup*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#post--_cluster_setup
	##
```

### Get database updates
Returns a list of all database events in the CouchDB instance. The existence of the _global_changes database is required to use this endpoint.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_db_updates
```
proc serverGetDbUpdates*(self: CouchDb, feed: string = "normal", timeout: int = 6000, heartbeat: int = 6000, since: string = "now"): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_db_updates
	##
```

### Get nodes in cluster
Displays the nodes that are part of the cluster as cluster_nodes. The field all_nodes displays all nodes this node knows about, including the ones that are part of the cluster. The endpoint is useful when setting up a cluster.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
```
proc serverGetMembership*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
	##
```

### Replicate database between node or local server
Request, configure, or stop, a replication operation.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
```
proc serverPostReplicate*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
	##
```

### Get scheduler jobs
List of replication jobs. Includes replications created via /_replicate endpoint as well as those created from replication documents. Does not include replications which have completed or have failed to start because replication documents were malformed. Each job description will include source and target information, replication id, a history of recent event, and a few other things.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-jobs
```
proc serverGetSchedulerJobs*(self: CouchDb, limit: int, skip: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-jobs
	##
```

### Get scheduler docs
List of replication document states. Includes information about all the documents, even in completed and failed states. For each document it returns the document ID, the database, the replication ID, source and target, and other information.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs
- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db
```
proc serverGetSchedulerDocs*(self: CouchDb, limit: int, skip: int = 0, replicatorDb: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db
	##
```

### Get scheduler docs
Get information about replication documents from a replicator database. The default replicator database is _replicator but other replicator databases can exist if their name ends with the suffix /_replicator.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db-docid
```
proc serverGetSchedulerDocs*(self: CouchDb, replicatorDb: string, docId: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db-docid
	##
```

### Get node
The /_node/{node-name} endpoint can be used to confirm the Erlang node name of the server that processes the request. This is most useful when accessing /_node/_local to retrieve this information. Repeatedly retrieving this information for a CouchDB endpoint can be useful to determine if a CouchDB cluster is correctly proxied through a reverse load balancer.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name
```
proc serverGetNode*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name
	##
```

### Get node state
The _stats resource returns a JSON object containing the statistics for the running server. The object is structured with top-level sections collating the statistics for a range of entries, with each individual statistic being easily identified, and the content of each statistic is self-describing.

Statistics are sampled internally on a configurable interval. When monitoring the _stats endpoint, you need to use a polling frequency of at least twice this to observe accurate results. For example, if the interval is 10 seconds, poll _stats at least every 5 seconds.

The literal string _local serves as an alias for the local node name, so for all stats URLs, {node-name} may be replaced with _local, to interact with the local node’s statistics.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_stats
```
proc serverGetNodeStats*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_stats
	##
```

### Get node in prometheus format
The _prometheus resource returns a text/plain response that consolidates our /_node/{node-name}/_stats, and /_node/{node-name}/_system endpoints. The format is determined by Prometheus. The format version is 2.0.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_prometheus
```
proc serverGetNodePrometheus*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_prometheus
	##
```

### Get node system
The _system resource returns a JSON object containing various system-level statistics for the running server. The object is structured with top-level sections collating the statistics for a range of entries, with each individual statistic being easily identified, and the content of each statistic is self-describing.

The literal string _local serves as an alias for the local node name, so for all stats URLs, {node-name} may be replaced with _local, to interact with the local node’s statistics.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_system
```
proc serverGetNodeSystem*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_system
	##
```

### Post to restart node
This API is to facilitate integration testing only it is not meant to be used in production.

- see https://docs.couchdb.org/en/latest/api/server/common.html#post--_node-node-name-_restart
```
proc serverPostNodeRestart*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#post--_node-node-name-_restart
	##
```

### Get node versions
The _versions resource returns a JSON object containing various system-level informations for the running server.

The literal string _local serves as an alias for the local node name, so for all stats URLs, {node-name} may be replaced with _local, to interact with the local node’s informations.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_versions
```
proc serverGetNodeVersions*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_versions
	##
```

### Post test lucene analyzer
Tests the results of Lucene analyzer tokenization on sample text.

- see https://docs.couchdb.org/en/latest/api/server/common.html#post--_search_analyze
```
proc serverPostSearchAnalyze*(self: CouchDb, field: string, text: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#post--_search_analyze
	##
```

### Get if server up
Confirms that the server is up, running, and ready to respond to requests. If maintenance_mode is true or nolb, the endpoint will return a 404 response.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_up
```
proc serverGetUp*(self: CouchDb): Future[JsonNode] {.async.} =
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_up
	##
```

### Get uuids
Requests one or more Universally Unique Identifiers (UUIDs) from the CouchDB instance. The response is a JSON object providing a list of UUIDs.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_uuids
```
proc serverGetUUIDs*(self: CouchDb, count: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_uuids
	##
```

### Get count of completed resharding
Returns a count of completed, failed, running, stopped, and total jobs along with the state of resharding on the cluster.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard
```
proc serverGetReshard*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard
	##
```

### Get resharding state
Returns the resharding state and optional information about the state.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-state
```
proc serverGetReshardState*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-state
	##
```

### Put reshard state
Change the resharding state on the cluster. The states are stopped or running. This starts and stops global resharding on all the nodes of the cluster. If there are any running jobs, they will be stopped when the state changes to stopped. When the state changes back to running those job will continue running.

- see https://docs.couchdb.org/en/latest/api/server/common.html#put--_reshard-state
```
proc serverPutReshardState*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#put--_reshard-state
	##
```

### Get reshard jobs
The shape of the response and the total_rows and offset field in particular are meant to be consistent with the _scheduler/jobs endpoint.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs
- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid
```
proc serverGetReshardJobs*(self: CouchDb, jobId: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid
	##
```

### Post reshard jobs
Depending on what fields are specified in the request, one or more resharding jobs will be created. The response is a json array of results. Each result object represents a single resharding job for a particular node and range. Some of the responses could be successful and some could fail. Successful results will have the "ok": true key and and value, and failed jobs will have the "error": "{error_message}" key and value.

- see https://docs.couchdb.org/en/latest/api/server/common.html#post--_reshard-jobs
```
proc serverPostReshardJobs*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#post--_reshard-jobs
	##
```

### Delete reshard jobs
If the job is running, stop the job and then remove it.

- see https://docs.couchdb.org/en/latest/api/server/common.html#delete--_reshard-jobs-jobid
```
proc serverDeleteReshardJobs*(self: CouchDb, jobId: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#delete--_reshard-jobs-jobid
	##
```

### Get reshard jobs state
Returns the running state of a resharding job identified by jobid.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
```
proc serverGetReshardJobsState*(self: CouchDb, jobId: string, state: string, reason: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
	##
```

### Put reshard jobs state
Change the state of a particular resharding job identified by jobid. The state can be changed from stopped to running or from running to stopped. If an individual job is stopped via this API it will stay stopped even after the global resharding state is toggled from stopped to running. If the job is already completed its state will stay completed.

- see https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
```
proc serverPutReshardJobsState*(self: CouchDb, jobId: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
	##
```

### Get node config
Returns the entire CouchDB server configuration as a JSON structure. The structure is organized by different configuration sections, with individual values.

- see https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config
- see https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section
- see https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section-key
```
proc serverGetNodeConfig*(self: CouchDb, nodeName: string, section: string = "", key: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section-key
	##
```

### Put node config
Updates a configuration value. The new value should be supplied in the request body in the corresponding JSON format. If you are setting a string value, you must supply a valid JSON string. In response CouchDB sends old value for target section key.

- see https://docs.couchdb.org/en/latest/api/server/configuration.html#put--_node-node-name-_config-section-key
```
proc serverPutNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string, value: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#put--_node-node-name-_config-section-key
	##
```

### Delete node config
Deletes a configuration value. The returned JSON will be the value of the configuration parameter before it was deleted.

- see https://docs.couchdb.org/en/latest/api/server/configuration.html#delete--_node-node-name-_config-section-key
```
proc serverDeleteNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#delete--_node-node-name-_config-section-key
	##
```

### Post reload node config
Reloads the configuration from disk. This has a side effect of flushing any in-memory configuration changes that have not been committed to disk.

- see https://docs.couchdb.org/en/latest/api/server/configuration.html#post--_node-node-name-_config-_reload
```
proc serverPostNodeConfigReload*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html#post--_node-node-name-_config-_reload
	##
```

### Get database info
Gets information about the specified database.

- see https://docs.couchdb.org/en/latest/api/database/common.html#get--db
```
proc databaseGetInfo*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#get--db
	##
```

### Put database
Creates a new database. The database name {db} must be composed by following next rules:

- Name must begin with a lowercase letter (a-z)
- Lowercase characters (a-z)
- Digits (0-9)
- Any of the characters _, $, (, ), +, -, and /.

If you’re familiar with Regular Expressions, the rules above could be written as ^[a-z][a-z0-9_$()+/-]*$.

- see https://docs.couchdb.org/en/latest/api/database/common.html#put--db
```
proc databasePut*(self: CouchDb, db: string, shards: int = 8, replicas: int = 3, partitioned: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#put--db
	##
```

### Delete database
Deletes the specified database, and all the documents and attachments contained within it.

- see https://docs.couchdb.org/en/latest/api/database/common.html#delete--db
```
proc databaseDelete*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#delete--db
	##
```

### Post database create new document
Creates a new document in the specified database, using the supplied JSON document structure.

If the JSON structure includes the _id field, then the document will be created with the specified document ID.

If the _id field is not specified, a new unique ID will be generated, following whatever UUID algorithm is configured for that server.

- see https://docs.couchdb.org/en/latest/api/database/common.html#post--db
```
proc databasePost*(self: CouchDb, db: string, document: JsonNode, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#post--db
	##
```

### Get all docs
Executes the built-in _all_docs view, returning all of the documents in the database. With the exception of the URL parameters (described below), this endpoint works identically to any other view. Refer to the view endpoint documentation for a complete description of the available query parameters and the format of the returned data.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_all_docs
```
proc databaseGetAllDocs*(self: CouchDb, db: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_all_docs
	##
```

### Post all docs
POST _all_docs functionality supports identical parameters and behavior as specified in the GET /{db}/_all_docs API but allows for the query string parameters to be supplied as keys in a JSON object in the body of the POST request.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs
```
proc databasePostAllDocs*(self: CouchDb, db: string, jsonData: JsonNode, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs
	##
```

### Get design docs
Returns a JSON structure of all of the design documents in a given database. The information is returned as a JSON structure containing meta information about the return structure, including a list of all design documents and basic contents, consisting the ID, revision and key. The key is the design document’s _id.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_design_docs
```
proc databaseGetDesignDocs*(self: CouchDb, db: string, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_design_docs
	##
```

### Post design docs
POST _design_docs functionality supports identical parameters and behavior as specified in the GET /{db}/_design_docs API but allows for the query string parameters to be supplied as keys in a JSON object in the body of the POST request.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_design_docs
```
proc databasePostDesignDocs*(self: CouchDb, db: string, jsonData: JsonNode, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_design_docs
	##
```

### Post queries all docs
Executes multiple specified built-in view queries of all documents in this database. This enables you to request multiple queries in a single request, in place of multiple POST /{db}/_all_docs requests.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs-queries
```
proc databasePostAllDocsQueries*(self: CouchDb, db: string, queries: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs-queries
	##
```

### Post bulk operation fetch several docs
This method can be called to query several documents in bulk. It is well suited for fetching a specific revision of documents, as replicators do for example, or for getting revision history.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_get
```
proc databasePostBulkGet*(self: CouchDb, db: string, jsonData: JsonNode, revs: bool = true): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_get
	##
```

### Post bulk operation for update several docs
The bulk document API allows you to create and update multiple documents at the same time within a single request. The basic operation is similar to creating or updating a single document, except that you batch the document structure and information.

When creating new documents the document ID (_id) is optional.

For updating existing documents, you must provide the document ID, revision information (_rev), and new document values.

In case of batch deleting documents all fields as document ID, revision information and deletion status (_deleted) are required.

- see https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_docs
```
proc databasePostBulkDocs*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_docs
	##
```

### Post find docs
Find documents using a declarative JSON querying syntax. Queries will use custom indexes, specified using the _index endpoint, if available. Otherwise, they use the built-in _all_docs index, which can be arbitrarily slow.

- see https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_find
```
proc databasePostFind*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_find
	##
```

### Post create index on database
Mango is a declarative JSON querying language for CouchDB databases. Mango wraps several index types, starting with the Primary Index out-of-the-box. Mango indexes, with index type json, are built using MapReduce Views.

Create a new index on a database.

- see https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_index
```
proc databasePostIndex*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_index
	##
```

### Get index from database
When you make a GET request to /db/_index, you get a list of all indexes in the database. In addition to the information available through this API, indexes are also stored in design documents <index-functions>. Design documents are regular documents that have an ID starting with _design/. Design documents can be retrieved and modified in the same way as any other document, although this is not necessary when using Mango.

- see https://docs.couchdb.org/en/latest/api/database/find.html#get--db-_index
```
proc databaseGetIndex*(self: CouchDb, db: string, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#get--db-_index
	##
```

### Delete index from database
- see https://docs.couchdb.org/en/latest/api/database/find.html#delete--db-_index-designdoc-json-name
```
proc databaseDeleteIndex*(self: CouchDb, db: string, ddoc: string, name: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#delete--db-_index-designdoc-json-name
	##
```

### Post explain index
Shows which index is being used by the query. Parameters are the same as _find.

- see https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
```
proc databasePostExplain*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
	##
```

### Get database shards
The response will contain a list of database shards. Each shard will have its internal database range, and the nodes on which replicas of those shards are stored.
Returns information about the specific shard into which a given document has been stored, along with information about the nodes on which that shard has a replica.
	
- see https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards
- see https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards-docid
```
proc databaseGetShards*(self: CouchDb, db: string, docId: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards
	##
```

### Post to sync shards to all replicas
For the given database, force-starts internal shard synchronization for all replicas of all database shards.
This is typically only used when performing cluster maintenance, such as moving a shard.

- see https://docs.couchdb.org/en/latest/api/database/shard.html#post--db-_sync_shards
```
proc databasePostSyncShards*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#post--db-_sync_shards
	##
```

### Get sorted list changes document
Returns a sorted list of changes made to documents in the database, in time order of application, can be obtained from the database’s _changes resource. Only the most recent change for a given document is guaranteed to be provided, for example if a document has had fields added, and then deleted, an API client checking for changes will not necessarily receive the intermediate state of added documents.

This can be used to listen for update and modifications to the database for post processing or synchronization, and for practical purposes, a continuously connected _changes feed is a reasonable approach for generating a real-time log for most applications.
	
- see https://docs.couchdb.org/en/latest/api/database/changes.html#get--db-_changes
```
proc databaseGetChanges*(self: CouchDb, db: string, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#get--db-_changes
	##
```
	
### Post to get sorted list canges document with larger list
Requests the database changes feed in the same way as GET /{db}/_changes does, but is widely used with ?filter=_doc_ids query parameter and allows one to pass a larger list of document IDs to filter.

- see https://docs.couchdb.org/en/latest/api/database/changes.html#post--db-_changes
```
proc databasePostChanges*(self: CouchDb, db: string, jsonData: JsonNode, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#post--db-_changes
	##
```

### Post to compact/compress database
Request compaction of the specified database. Compaction compresses the disk database file by performing the following operations:

Writes a new, optimised, version of the database file, removing any unused sections from the new version during write. Because a new file is temporarily created for this purpose, you may require up to twice the current storage space of the specified database in order for the compaction routine to complete.

Removes the bodies of any non-leaf revisions of documents from the database.

Removes old revision history beyond the limit specified by the _revs_limit database parameter.

Compaction can only be requested on an individual database; you cannot compact all the databases for a CouchDB instance. The compaction process runs as a background process.

You can determine if the compaction process is operating on a database by obtaining the database meta information, the compact_running value of the returned database structure will be set to true. See GET /{db}.

You can also obtain a list of running processes to determine whether compaction is currently running. See /_active_tasks.

Compacts the view indexes associated with the specified design document. It may be that compacting a large view can return more storage than compacting the actual db. Thus, you can use this in place of the full database compaction if you know a specific set of view indexes have been affected by a recent database change.

- see https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
- see https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact-ddoc
```
proc databasePostCompact*(self: CouchDb, db: string, ddoc: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact-ddoc
	##
```

### Post view  cleanup to remove unused view
Removes view index files that are no longer required by CouchDB as a result of changed views within design documents. As the view filename is based on a hash of the view functions, over time old views will remain, consuming storage. This call cleans up the cached view output on disk for a given view.

- https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_view_cleanup
```
proc databasePostViewCleanup*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_view_cleanup
	##
```

### Get security option from database
Returns the current security object from the specified database.

The security object consists of two compulsory elements, admins and members, which are used to specify the list of users and/or roles that have admin and members rights to the database respectively:

members: they can read all types of documents from the DB, and they can write (and edit) documents to the DB except for design documents.

admins: they have all the privileges of members plus the privileges: write (and edit) design documents, add/remove database admins and members and set the database revisions limit. They can not create a database nor delete a database.

Both members and admins objects contain two array-typed fields:

names: List of CouchDB user names

roles: List of users roles

Any additional fields in the security object are optional. The entire security object is made available to validation and other internal functions so that the database can control and limit functionality.

If both the names and roles fields of either the admins or members properties are empty arrays, or are not existent, it means the database has no admins or members.

Having no admins, only server admins (with the reserved _admin role) are able to update design documents and make other admin level changes.

Having no members or roles, any user can write regular documents (any non-design document) and read documents from the database.

Since CouchDB 3.x newly created databases have by default the _admin role to prevent unintentional access.

If there are any member names or roles defined for a database, then only authenticated users having a matching name or role are allowed to read documents from the database (or do a GET /{db} call).

- see https://docs.couchdb.org/en/latest/api/database/security.html#get--db-_security
```
proc databaseGetSecurity*(self: CouchDb, db:string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#get--db-_security
	##
```

### Put security
Sets the security object for the given database.
	
- https://docs.couchdb.org/en/latest/api/database/security.html#put--db-_security
```
proc databasePutSecurity*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#put--db-_security
	##
```

### Post purge to remove references
A database purge permanently removes the references to documents in the database. Normal deletion of a document within CouchDB does not remove the document from the database, instead, the document is marked as _deleted=true (and a new revision is created). This is to ensure that deleted documents can be replicated to other databases as having been deleted. This also means that you can check the status of a document and identify that the document has been deleted by its absence.

The purge request must include the document IDs, and for each document ID, one or more revisions that must be purged. Documents can be previously deleted, but it is not necessary. Revisions must be leaf revisions.

The response will contain a list of the document IDs and revisions successfully purged.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_purge
```
proc databasePostPurge*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_purge
	##
```
	
### Get purged infos limit from database
Gets the current purged_infos_limit (purged documents limit) setting, the maximum number of historical purges (purged document Ids with their revisions) that can be stored in the database.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_purged_infos_limit
```
proc databaseGetPurgedInfosLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_purged_infos_limit
	##
```

### Put purge infos limit to database
Sets the maximum number of purges (requested purged Ids with their revisions) that will be tracked in the database, even after compaction has occurred. You can set the purged documents limit on a database with a scalar integer of the limit that you want to set as the request body.

The default value of historical stored purges is 1000. This means up to 1000 purges can be synchronized between replicas of the same databases in case of one of the replicas was down when purges occurred.

This request sets the soft limit for stored purges. During the compaction CouchDB will try to keep only _purged_infos_limit of purges in the database, but occasionally the number of stored purges can exceed this value. If a database has not completed purge synchronization with active indexes or active internal replications, it may temporarily store a higher number of historical purges.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_purged_infos_limit
```
proc databasePutPurgedInfosLimit*(self: CouchDb, db:string, purgedInfosLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_purged_infos_limit
	##
```

### Post missing revs
With given a list of document revisions, returns the document revisions that do not exist in the database.
	
- see https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_missing_revs
```
proc databasePostMissingRevs*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_missing_revs
	##
```

### Post revs diff
Given a set of document/revision IDs, returns the subset of those that do not correspond to revisions stored in the database.

Its primary use is by the replicator, as an important optimization: after receiving a set of new revision IDs from the source database, the replicator sends this set to the destination database’s _revs_diff to find out which of them already exist there. It can then avoid fetching and sending already-known document bodies.

Both the request and response bodies are JSON objects whose keys are document IDs; but the values are structured differently:

- In the request, a value is an array of revision IDs for that document.
- In the response, a value is an object with a missing: key, whose value is a list of revision IDs for that document (the ones that are not stored in the database) and optionally a possible_ancestors key, whose value is an array of revision IDs that are known that might be ancestors of the missing revisions.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_revs_diff
```
proc databasePostRevsDiff*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_revs_diff
	##
```

### Get revs limit from database
Gets the current revs_limit (revision limit) setting.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_revs_limit
```
proc databaseGetRevsLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_revs_limit
	##
```

### Put revs limit to database
Sets the maximum number of document revisions that will be tracked by CouchDB, even after compaction has occurred. You can set the revision limit on a database with a scalar integer of the limit that you want to set as the request body.

- see https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_revs_limit
```
proc databasePutRevsLimit*(self: CouchDb, db:string, revsLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_revs_limit
	##
```

### Get document
Returns document by the specified docid from the specified db. Unless you request a specific revision, the latest revision of the document will always be returned.
	
- see https://docs.couchdb.org/en/latest/api/document/common.html#get--db-docid
```
proc documentGet*(self: CouchDb, db: string, docId: string, attachments: bool = false, attEncodingInfo: bool = false, attsSince: seq[string] = @[], conflicts: bool = false, deletedConflicts: bool = false, latest: bool = false, localSeq: bool = false, meta: bool = false, openRevs: seq[string] = @[], rev: string = "", revs: bool = false, revsInfo: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#get--db-docid
	##
```

### Put docuement
The PUT method creates a new named document, or creates a new revision of the existing document. Unlike the POST /{db}, you must specify the document ID in the request URL.

When updating an existing document, the current document revision must be included in the document (i.e. the request body), as the rev query parameter, or in the If-Match request header.

- see https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
```
proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
	##
```

### Put Document with attachment
To create a document with multiple attachments with single request you need just inline base64 encoded attachments data into the document body.
Alternatively, you can upload a document with attachments more efficiently in multipart/related format. This avoids having to Base64-encode the attachments, saving CPU and bandwidth. To do this, set the Content-Type header of the PUT /{db}/{docid} request to multipart/related.

The first MIME body is the document itself, which should have its own Content-Type of application/json". It also should include an _attachments metadata object in which each attachment object has a key follows with value true.

The subsequent MIME bodies are the attachments.

- see https://docs.couchdb.org/en/latest/api/document/common.html#creating-multiple-attachments
```
proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, attachments: seq[DocumentAttachment], rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#creating-multiple-attachments
	##
```
	
### Delete document
Marks the specified document as deleted by adding a field _deleted with the value true. Documents with this field will not be returned within requests anymore, but stay in the database. You must supply the current (latest) revision, either by using the rev parameter or by using the If-Match header to specify the revision.
	
- see https://docs.couchdb.org/en/latest/api/document/common.html#delete--db-docid
```
proc documentDelete*(self: CouchDb, db: string, docId: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#delete--db-docid
	##
```

### Get document attachment
Returns the file attachment associated with the document. The raw data of the associated attachment is returned (just as if you were accessing a static file. The returned Content-Type will be the same as the content type set when the document attachment was submitted into the database.

- see https://docs.couchdb.org/en/latest/api/document/attachments.html#get--db-docid-attname
```
proc documentGetAttachment*(self: CouchDb, db: string, docId: string, attachment: string, bytesRange: tuple[start: int, stop: int] = (0, 0), rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#get--db-docid-attname
	##	support get range https://datatracker.ietf.org/doc/html/rfc2616.html#section-14.27
	##	bytesRange = (0, 1000) -> get get from 0 to 1000 range bytes
	##
```

### Put document attachment
Uploads the supplied content as an attachment to the specified document. The attachment name provided must be a URL encoded string. You must supply the Content-Type header, and for an existing document you must also supply either the rev query argument or the If-Match HTTP header. If the revision is omitted, a new, otherwise empty document will be created with the provided attachment, or a conflict will occur.

If case when uploading an attachment using an existing attachment name, CouchDB will update the corresponding stored content of the database. Since you must supply the revision information to add an attachment to the document, this serves as validation to update the existing attachment.
	
- see https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
```
proc documentPutAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, attachment: string, contentType: string, rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##
```

### Delete document attachment
Deletes the attachment with filename {attname} of the specified doc. You must supply the rev query parameter or If-Match with the current revision to delete the attachment.
	
- see https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
```
proc documentDeleteAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##
```

### Get design document view
Executes the specified view function from the specified design document.

- see https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
```
proc designDocumentGetView*(self: CouchDb, db: string, ddoc: string, view: string, conflicts: bool = false, descending: bool = false, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, group: bool = false, groupLevel: int = 0, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], limit: int = 0, reduce: bool = true, skip: int = 0, sorted: bool = true, stable: bool = false, stale: string = "", startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, update: string = "true", updateSeq: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
	##
```
	
### Post design document view
Executes the specified view function from the specified design document. POST view functionality supports identical parameters and behavior as specified in the GET /{db}/_design/{ddoc}/_view/{view} API but allows for the query string parameters to be supplied as keys in a JSON object in the body of the POST request.

- see https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view
```
proc designDocumentPostView*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view
	##
```

### Post design document view queries
Executes the specified view function from the specified design document. POST view functionality supports identical parameters and behavior as specified in the GET /{db}/_design/{ddoc}/_view/{view} API but allows for the query string parameters to be supplied as keys in a JSON object in the body of the POST request.

- see https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view-queries
```
proc designDocumentPostViewQueries*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view-queries
	##
```

### Get design document search
Executes a search request against the named index in the specified design document.

- see https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search-index
```
proc designDocumentGetSearch*(self: CouchDb, db: string, ddoc: string, index: string, bookmark: string = "", counts: JsonNode = nil, drilldown: JsonNode = nil, groupField: string = "", groupSort: JsonNode = nil, highlightFields: JsonNode = nil, highlightPreTag: string = "", highlightPostTag: string = "", highlightNumber: int = 0, highlightSize: int = 0, includeDocs: bool = false, includeFields: JsonNode = nil, limit: int = 0, query: string = "", ranges: JsonNode = nil, sort: JsonNode = nil, stale: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search-index
	##
```

### Get design document search info
- see https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search_info-index
```
proc designDocumentGetSearchInfo*(self: CouchDb, db: string, ddoc: string, index: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search_info-index
	##
```

### Post design document update func
Executes update function on server side for null document.

- see https://docs.couchdb.org/en/latest/api/ddoc/render.html#post--db-_design-ddoc-_update-func
```
proc designDocumentPostUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, docId: string = "", jsonData: JsonNode = nil): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/render.html#post--db-_design-ddoc-_update-func
	##
```

### Put design document update func
Executes update function on server side for the specified document.

- see https://docs.couchdb.org/en/latest/api/ddoc/render.html#put--db-_design-ddoc-_update-func-docid
```
proc designDocumentPostUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, docId: string = "", jsonData: JsonNode = nil): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/render.html#put--db-_design-ddoc-_update-func-docid
	##
```

### Get partition database
This endpoint returns information describing the provided partition. It includes document and deleted document counts along with external and active data sizes.

- see https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition
```
proc partitionDatabaseGet*(self: CouchDb, db: string, partition: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition
	##
```

### Get partition database all docs
- see https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_all_docs
```
proc partitionDatabaseGetAllDocs*(self: CouchDb, db: string, partition: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_all_docs
	##
```

### Get partition database design view
- see https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_design-ddoc-_view-view
```
proc partitionDatabaseGetDesignView*(self: CouchDb, db: string, partition: string, ddoc: string, view: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_design-ddoc-_view-view
	##
```

### Post partition database find
- see https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_find
```
proc partitionDatabasePostFind*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_find
	##
```
	
### Post partition database explain
- see https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_explain
```
proc partitionDatabasePostExplain*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_explain
	##
```
