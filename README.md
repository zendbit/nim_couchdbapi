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
```
proc databasePut*(self: CouchDb, db: string, shards: int = 8, replicas: int = 3, partitioned: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#put--db
	##

proc databaseDelete*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#delete--db
	##

proc databasePost*(self: CouchDb, db: string, document: JsonNode, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html#post--db
	##

proc databaseGetAllDocs*(self: CouchDb, db: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_all_docs
	##

proc databasePostAllDocs*(self: CouchDb, db: string, jsonData: JsonNode, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs
	##

proc databaseGetDesignDocs*(self: CouchDb, db: string, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_design_docs
	##

proc databasePostDesignDocs*(self: CouchDb, db: string, jsonData: JsonNode, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_design_docs
	##

proc databasePostAllDocsQueries*(self: CouchDb, db: string, queries: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs-queries
	##

proc databasePostBulkGet*(self: CouchDb, db: string, jsonData: JsonNode, revs: bool = true): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_get
	##

proc databasePostBulkDocs*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_docs
	##

proc databasePostFind*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_find
	##

proc databasePostIndex*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_index
	##

proc databaseGetIndex*(self: CouchDb, db: string, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#get--db-_index
	##

proc databaseDeleteIndex*(self: CouchDb, db: string, ddoc: string, name: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#delete--db-_index-designdoc-json-name
	##

proc databasePostExplain*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
	##

proc databaseGetShards*(self: CouchDb, db: string, docId: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards
	##

proc databasePostSyncShards*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#post--db-_sync_shards
	##

proc databaseGetChanges*(self: CouchDb, db: string, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#get--db-_changes
	##

proc databasePostChanges*(self: CouchDb, db: string, jsonData: JsonNode, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#post--db-_changes
	##

proc databasePostCompact*(self: CouchDb, db: string, ddoc: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
	##

proc databasePostEnsureFullCommit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
	##

proc databasePostViewCleanup*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_view_cleanup
	##

proc databaseGetSecurity*(self: CouchDb, db:string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#get--db-_security
	##

proc databasePutSecurity*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#put--db-_security
	##

proc databasePostPurge*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_purge
	##

proc databaseGetPurgedInfosLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_purged_infos_limit
	##

proc databasePutPurgedInfosLimit*(self: CouchDb, db:string, purgedInfosLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_purged_infos_limit
	##

proc databasePostMissingRevs*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_missing_revs
	##

proc databasePostRevsDiff*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_revs_diff
	##

proc databaseGetRevsLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_revs_limit
	##

proc databasePutRevsLimit*(self: CouchDb, db:string, revsLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_revs_limit
	##

proc documentGet*(self: CouchDb, db: string, docId: string, attachments: bool = false, attEncodingInfo: bool = false, attsSince: seq[string] = @[], conflicts: bool = false, deletedConflicts: bool = false, latest: bool = false, localSeq: bool = false, meta: bool = false, openRevs: seq[string] = @[], rev: string = "", revs: bool = false, revsInfo: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#get--db-docid
	##

proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
	##

proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, attachments: seq[DocumentAttachment], rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#creating-multiple-attachments
	##

proc documentDelete*(self: CouchDb, db: string, docId: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
	##

proc documentGetAttachment*(self: CouchDb, db: string, docId: string, attachment: string, bytesRange: tuple[start: int, stop: int] = (0, 0), rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#get--db-docid-attname
	##	support get range https://datatracker.ietf.org/doc/html/rfc2616.html#section-14.27
	##	bytesRange = (0, 1000) -> get get from 0 to 1000 range bytes
	##

proc documentPutAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, attachment: string, contentType: string, rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##

proc documentDeleteAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##

proc designDocumentGetView*(self: CouchDb, db: string, ddoc: string, view: string, conflicts: bool = false, descending: bool = false, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, group: bool = false, groupLevel: int = 0, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], limit: int = 0, reduce: bool = true, skip: int = 0, sorted: bool = true, stable: bool = false, stale: string = "", startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, update: string = "true", updateSeq: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
	##

proc designDocumentPostView*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view
	##

proc designDocumentPostViewQueries*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view-queries
	##

proc designDocumentGetSearch*(self: CouchDb, db: string, ddoc: string, index: string, bookmark: string = "", counts: JsonNode = nil, drilldown: JsonNode = nil, groupField: string = "", groupSort: JsonNode = nil, highlightFields: JsonNode = nil, highlightPreTag: string = "", highlightPostTag: string = "", highlightNumber: int = 0, highlightSize: int = 0, includeDocs: bool = false, includeFields: JsonNode = nil, limit: int = 0, query: string = "", ranges: JsonNode = nil, sort: JsonNode = nil, stale: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search-index
	##

proc designDocumentGetSearchInfo*(self: CouchDb, db: string, ddoc: string, index: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search_info-index
	##

proc designDocumentPostUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, docId: string = "", jsonData: JsonNode = nil): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/render.html#post--db-_design-ddoc-_update-func
	##

proc partitionedDatabaseGet*(self: CouchDb, db: string, partition: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition
	##

proc partitionedDatabaseGetAllDocs*(self: CouchDb, db: string, partition: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_all_docs
	##

proc partitionedDatabaseGetDesignView*(self: CouchDb, db: string, partition: string, ddoc: string, view: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_design-ddoc-_view-view
	##

proc partitionDatabasePostFind*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_find
	##

proc partitionDatabasePostExplain*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_explain
	##
```
