# nim.couchdbapi
CouchDb rest api driver for nim programming language

### Create document with attachment
```
proc newDocumentWithAttachments*(jsonData: JsonNode, attachments: seq[DocumentAttachment]): Future[tuple[body: string, boundary: string, length: int]] {.async.}
	##
	##	create new document with given attachment
	##	will automatic convert to multipart/related
	##	if the attachment not valid (fileContent) file path
	##	it will use that content as attachment filewill
	##
```

### Standard output result for all api request
```
proc newResponseMsg*(): JsonNode =
	##
	##	create new response msg for each request
	##	make it standard output
	##
```

### Create new couchdb object
```
proc newCouchDb*(
	username: string,
	password: string,
	database: string,
	host: string,
	port: int,
	jwtToken: string = "",
	secure: bool = false): CouchDb =
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
- See https://docs.couchdb.org/en/latest/api/server/common.html
```
proc serverGetInfo*(self: CouchDb): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html
	##
```

### Get server active tasks
- see https://docs.couchdb.org/en/latest/api/server/common.html#active-tasks
```
proc serverGetActiveTasks*(self: CouchDb): Future[JsonNode] {.async.} =
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#active-tasks
	##
```

### Get all databases from the server
- see https://docs.couchdb.org/en/latest/api/server/common.html#all-dbs
```
proc serverGetAllDbs*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#all-dbs
	##
```

### Get databases information from server
- see https://docs.couchdb.org/en/latest/api/server/common.html#dbs-info
```
proc serverGetDbsInfo*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, limit: int = 0, skip: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#dbs-info
	##
```

### Post to get database server information
- see https://docs.couchdb.org/en/latest/api/server/common.html#dbs-inf
```
proc serverPostDbsInfo*(self: CouchDb, keys: seq[JsonNode]): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/server/common.html#dbs-info
	##
```
```
proc serverGetClusterSetup*(self: CouchDb, ensureDbsExist: seq[string] = @["_users", "_replicator"]): Future[JsonNode] {.async.}
	##
	##
	##
```
```
proc serverGetDbUpdates*(self: CouchDb, feed: string = "normal", timeout: int = 6000, heartbeat: int = 6000, since: string = "now"): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#db-updates
	##
```
```
proc serverGetMembership*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#membership
	##
```
```
proc serverPostReplicate*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#replicate
	##
```
```
proc serverGetSchedulerJobs*(self: CouchDb, limit: int, skip: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#scheduler-jobs
	##
```
```
proc serverGetSchedulerDocs*(self: CouchDb, limit: int, skip: int = 0, replicatorDb: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#scheduler-docs
	##
```
```
proc serverGetSchedulerDocs*(self: CouchDb, replicatorDb: string, docId: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#scheduler-docs
	##
```
```
proc serverGetNode*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name
	##
```
```
proc serverGetNodeStats*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name-stats
	##
```
```
proc serverGetNodePrometheus*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name-prometheus
	##
```
```
proc serverGetNodeSystem*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name-system
	##
```
```
proc serverPostNodeRestart*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name-restart
	##
```
```
proc serverGetNodeVersions*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#node-node-name-versions
	##
```
```
proc serverPostSearchAnalyze*(self: CouchDb, field: string, text: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#search-analize
	##
```
```
proc serverGetUp*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#up
	##
```
```
proc serverGetUUIDs*(self: CouchDb, count: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#uuids
	##
```
```
proc serverGetReshard*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverGetReshardState*(self: CouchDb): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverPutReshardState*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverGetReshardJobs*(self: CouchDb, jobId: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverPostReshardJobs*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverDeleteReshardJobs*(self: CouchDb, jobId: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverPutReshardJobsState*(self: CouchDb, jobId: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/common.html#reshard
	##
```
```
proc serverGetNodeConfig*(self: CouchDb, nodeName: string, section: string = "", key: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html
	##
```
```
proc serverPutNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string, value: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html
	##
```
```
proc serverDeleteNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html
	##
```
```
proc serverPostNodeConfigReload*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/server/configuration.html
	##
```
```
proc databaseGetInfo*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html
	##
```
```
proc databasePut*(self: CouchDb, db: string, shards: int = 8, replicas: int = 3, partitioned: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html
	##
```
```
proc databaseDelete*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html
	##
```
```
proc databasePost*(self: CouchDb, db: string, document: JsonNode, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/common.html
	##
```
```
proc databaseGetAllDocs*(self: CouchDb, db: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html
	##
```
```
proc databasePostAllDocs*(self: CouchDb, db: string, jsonData: JsonNode, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html
	##
```
proc databaseGetDesignDocs*(self: CouchDb, db: string, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#db-design-docs
	##
```
```
proc databasePostDesignDocs*(self: CouchDb, db: string, jsonData: JsonNode, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#db-design-docs
	##
```
```
proc databasePostAllDocsQueries*(self: CouchDb, db: string, queries: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs-queries
	##
```
```
proc databasePostBulkGet*(self: CouchDb, db: string, jsonData: JsonNode, revs: bool = true): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_get
	##
```
```
proc databasePostBulkDocs*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_docs
	##
```
```
proc databasePostFind*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_find
	##
```
```
proc databasePostIndex*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_index
	##
```
```
proc databaseGetIndex*(self: CouchDb, db: string, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#get--db-_index
	##
```
```
proc databaseDeleteIndex*(self: CouchDb, db: string, ddoc: string, name: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#delete--db-_index-designdoc-json-name
	##
```
```
proc databasePostExplain*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
	##
```
```
proc databaseGetShards*(self: CouchDb, db: string, docId: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards
	##
```
```
proc databasePostSyncShards*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/shard.html#post--db-_sync_shards
	##
```
```
proc databaseGetChanges*(self: CouchDb, db: string, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#get--db-_changes
	##
```
```
proc databasePostChanges*(self: CouchDb, db: string, jsonData: JsonNode, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/changes.html#post--db-_changes
	##
```
```
proc databasePostCompact*(self: CouchDb, db: string, ddoc: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
	##
```
```
proc databasePostEnsureFullCommit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
	##
```
```
proc databasePostViewCleanup*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_view_cleanup
	##
```
```
proc databaseGetSecurity*(self: CouchDb, db:string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#get--db-_security
	##
```
```
proc databasePutSecurity*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/security.html#put--db-_security
	##
```
```
proc databasePostPurge*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_purge
	##
```
```
proc databaseGetPurgedInfosLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_purged_infos_limit
	##
```
```
proc databasePutPurgedInfosLimit*(self: CouchDb, db:string, purgedInfosLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_purged_infos_limit
	##
```
```
proc databasePostMissingRevs*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_missing_revs
	##
```
```
proc databasePostRevsDiff*(self: CouchDb, db:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_revs_diff
	##
```
```
proc databaseGetRevsLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_revs_limit
	##
```
```
proc databasePutRevsLimit*(self: CouchDb, db:string, revsLimit: int): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_revs_limit
	##
```
```
proc documentGet*(self: CouchDb, db: string, docId: string, attachments: bool = false, attEncodingInfo: bool = false, attsSince: seq[string] = @[], conflicts: bool = false, deletedConflicts: bool = false, latest: bool = false, localSeq: bool = false, meta: bool = false, openRevs: seq[string] = @[], rev: string = "", revs: bool = false, revsInfo: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#get--db-docid
	##
```
```
proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
	##
```
```
proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, attachments: seq[DocumentAttachment], rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#creating-multiple-attachments
	##
```
```
proc documentDelete*(self: CouchDb, db: string, docId: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
	##
```
```
proc documentGetAttachment*(self: CouchDb, db: string, docId: string, attachment: string, bytesRange: tuple[start: int, stop: int] = (0, 0), rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#get--db-docid-attname
	##	support get range https://datatracker.ietf.org/doc/html/rfc2616.html#section-14.27
	##	bytesRange = (0, 1000) -> get get from 0 to 1000 range bytes
	##
```
```
proc documentPutAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, attachment: string, contentType: string, rev: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##
```
```
proc documentDeleteAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, rev: string, batch: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
	##
```
```
proc designDocumentGetView*(self: CouchDb, db: string, ddoc: string, view: string, conflicts: bool = false, descending: bool = false, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, group: bool = false, groupLevel: int = 0, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], limit: int = 0, reduce: bool = true, skip: int = 0, sorted: bool = true, stable: bool = false, stale: string = "", startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, update: string = "true", updateSeq: bool = false): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
	##
```
```
proc designDocumentPostView*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view
	##
```
```
proc designDocumentPostViewQueries*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view-queries
	##
```
```
proc designDocumentGetSearch*(self: CouchDb, db: string, ddoc: string, index: string, bookmark: string = "", counts: JsonNode = nil, drilldown: JsonNode = nil, groupField: string = "", groupSort: JsonNode = nil, highlightFields: JsonNode = nil, highlightPreTag: string = "", highlightPostTag: string = "", highlightNumber: int = 0, highlightSize: int = 0, includeDocs: bool = false, includeFields: JsonNode = nil, limit: int = 0, query: string = "", ranges: JsonNode = nil, sort: JsonNode = nil, stale: string = ""): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search-index
	##
```
```
proc designDocumentGetSearchInfo*(self: CouchDb, db: string, ddoc: string, index: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search_info-index
	##
```
```
proc designDocumentPostUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, docId: string = "", jsonData: JsonNode = nil): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/ddoc/render.html#post--db-_design-ddoc-_update-func
	##
```
```
proc partitionedDatabaseGet*(self: CouchDb, db: string, partition: string): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition
	##
```
```
proc partitionedDatabaseGetAllDocs*(self: CouchDb, db: string, partition: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_all_docs
	##
```
```
proc partitionedDatabaseGetDesignView*(self: CouchDb, db: string, partition: string, ddoc: string, view: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_design-ddoc-_view-view
	##
```
```
proc partitionDatabasePostFind*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_find
	##
```
```
proc partitionDatabasePostExplain*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.}
	##
	##	https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_explain
	##
```
