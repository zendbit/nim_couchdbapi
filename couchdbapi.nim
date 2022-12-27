##
##  author  : amru.rosyada@gmail.com
##  repo    : https://github.com/zendbit/nim.couchdbapi
##
##  This is opensource project, you can contribute and make changes to the source code
##
import json
import httpclient
import strutils
import strformat
import asyncdispatch
import base64
import uri
import times
import os
import asyncfile
import streams
import std/sha1

export json
export asyncdispatch
export strformat
export strutils
export os

const LineFeed = "\r\n"
const BoundaryPrefix = "--"

type
  ##
  ##  CouchDb object
  ##  hold couchdb information
  ##  for secure/https set secure to true
  ##  if jwt token exist default auth will use it
  ##  if jwt token empty will fallback into basic auth
  ##
  CouchDb* = ref object
    username*: string
    password*: string
    host*: string
    port*: int
    jwtToken*: string
    secure*: bool
    url*: string

  ##
  ##  For attachment to document
  ##  make it not heavy using multipart
  ##
  DocumentAttachment* = ref object
    fileName*: string
    fileContent*: string
    contentType*: string

proc newDocumentWithAttachments*(jsonData: JsonNode, attachments: seq[DocumentAttachment]): Future[tuple[body: string, boundary: string, length: int]] {.async.} =
  ##
  ##  create new document with given attachment
  ##  will automatic convert to multipart/related
  ##  if the attachment not valid (fileContent) file path
  ##  it will use that content as attachment filewill
  ##
  if attachments.len != 0:
    let boundaryId = $ secureHash(now().utc().format("yyyy-MM-dd HH:mm:ss:ffffff"))
    let boundary = &"{BoundaryPrefix}{boundaryId}"
    let docAttachments: JsonNode = %*{}
    var docAttachmentsContent: StringStream = newStringStream()
    for attachment in attachments:
      ##  init fileContent with attachment.fileContent
      var fileContent = attachment.fileContent

      ##  if attachment.fileContent file exist
      ##  replace content with the file content
      if attachment.fileContent.fileExists:
        let fileAsync = openAsync(attachment.fileContent, fmRead)
        fileContent = await fileAsync.readAll
        fileAsync.close
      
      docAttachments{attachment.fileName} = nil

      ##  construct attachment content
      docAttachmentsContent.write(boundary)
      docAttachmentsContent.write(LineFeed)
      docAttachmentsContent.write(&"Content-Disposition:attachment;filename:\"{attachment.fileName}\"")
      docAttachmentsContent.write(LineFeed)
      docAttachmentsContent.write(&"Content-Type:{attachment.contentType}")
      docAttachmentsContent.write(LineFeed)
      docAttachmentsContent.write(LineFeed)
      docAttachmentsContent.write(fileContent)

      ##  construct json part
      ##  add file properties to docAttachments
      docAttachments{attachment.fileName} = %*{
        "follows": true,
        "content_type": attachment.contentType,
        "length": fileContent.len
      }

    docAttachmentsContent.write(LineFeed)
    docAttachmentsContent.write(boundary)
    docAttachmentsContent.setPosition(0)

    ##  append attachments info into data
    jsonData{"_attachments"} = docAttachments

    ##  merge jsonData and document attachments content
    let body =
      boundary &
      LineFeed &
      "Content-Type: application/json" &
      LineFeed &
      LineFeed &
      $jsonData &
      LineFeed &
      LineFeed &
      docAttachmentsContent.readAll

    docAttachmentsContent.close

    result = (body, boundaryId, body.len)

proc newHttpRequest*(): AsyncHttpClient =
  ##
  ##  create httpclient object
  ##
  result = newAsyncHttpClient()

proc newResponseMsg*(): JsonNode =
  ##
  ##  create new response msg for each request
  ##  make it standard output
  ##
  result = %*{
    "status": $Http405,
    "success": false,
    "error": {},
    "data": {}
  }

proc newCouchDb*(
  username: string,
  password: string,
  host: string,
  port: int,
  jwtToken: string = "",
  secure: bool = false): CouchDb =
  ##
  ##  create new couchdb instance
  ##  jwt token is optional
  ##  if jwt toke empty will use basic auth
  ##
  ##  CouchDb object
  ##  hold couchdb information
  ##  for secure/https set secure to true
  ##  if jwt token exist default auth will use it
  ##  if jwt token empty will fallback into basic auth
  ##
  result = CouchDb(
    username: username,
    password: password,
    host: host,
    port: port,
    jwtToken: jwtToken,
    secure: secure
  )

  ##
  ##  check using secure connection or not
  ##  if secure true use https
  ##
  if result.secure:
    result.url = &"https://{host}:{port}"

  else:
    result.url = &"http://{host}:{port}"

proc prepareRequestHeaders(self: AsyncHttpClient, couchDb: CouchDb, useBasicAuth: bool = false) =
  ##
  ##  Prepare headers for request
  ##  this will check if the jwt token available or not
  ##  if not will use basic outh header
  ##
  ##  useBasicAuth = true will force using basic auth
  ##

  if useBasicAuth or couchDb.jwtToken == "":
    let basicAuthToken = encode(&"{couchDb.username}:{couchDb.password}")
    self.headers["Authorization"] = &"Basic {basicAuthToken}"

  else:
    self.headers["Authorization"] = &"Bearer {couchDb.jwtToken}"

proc prepareRequestPostJsonHeaders(self: AsyncHttpClient, couchDb: CouchDb, useBasicAuth: bool = false) =
  ##
  ##  prepare request post json header
  ##  this will call prepareRequestHeaders
  ##
  self.prepareRequestHeaders(couchDb, useBasicAuth = useBasicAuth)
  self.headers["Content-Type"] = "application/json"

proc toResponseMsg(response: AsyncResponse): Future[JsonNode] {.async.} =
  ##
  ## Response format, will return JsonNode
  ## {
  ##    status: "200 OK",
  ##    success: true,
  ##    error: {},
  ##    data: {}
  ## }
  ##
  let responseMsg = newResponseMsg()
  responseMsg{"status"} = %response.status
  let body = await response.body
  if (cast[HttpCode](response.status.split(" ")[0].parseInt)).is2xx:
    responseMsg{"success"} = %true
    try:
      responseMsg{"data"} = % body.parseJson
    except:
      responseMsg{"data"}{"msg"} = %body

  else:
    try:
      responseMsg{"error"} = % body.parseJson
    except:
      responseMsg{"error"}{"msg"} = %body

  result = responseMsg

proc serverGetInfo*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/server/common.html#get--
  ##
  let httpRequest = newHttpRequest()
  let res = await httpRequest.get(&"{self.url}")
  result = await res.toResponseMsg

proc serverGetActiveTasks*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_active_tasks
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)

  let res = await httpRequest.get(&"{self.url}/_active_tasks")
  
  result = await res.toResponseMsg

proc serverGetAllDbs*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/server/common.html#get--_all_dbs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/_all_dbs{qstring}")
  
  result = await res.toResponseMsg

proc serverGetDbsInfo*(self: CouchDb, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, limit: int = 0, skip: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/server/common.html#get--_dbs_info
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/_dbs_info{qstring}")
  
  result = await res.toResponseMsg

proc serverPostDbsInfo*(self: CouchDb, keys: seq[JsonNode]): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/server/common.html#post--_dbs_info
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_dbs_info", body = $ %*{"keys":keys})
  
  result = await res.toResponseMsg

proc serverGetClusterSetup*(self: CouchDb, ensureDbsExist: seq[string] = @["_users", "_replicator"]): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_cluster_setup
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_cluster_setup?ensure_dbs_exist={encodeUrl($ %ensureDbsExist)}")
  
  result = await res.toResponseMsg

proc serverPostClusterSetup*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#post--_cluster_setup
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_cluster_setup", $jsonData)
  
  result = await res.toResponseMsg

proc serverGetDbUpdates*(self: CouchDb, feed: string = "normal", timeout: int = 6000, heartbeat: int = 6000, since: string = "now"): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_db_updates
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_db_updates?feed={feed}&timeout={timeout}&heartbeat={heartbeat}&since={since}")
  
  result = await res.toResponseMsg

proc serverGetMembership*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_membership")
  
  result = await res.toResponseMsg

proc serverPostReplicate*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_membership
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_replicate", body = $jsonData)
  
  result = await res.toResponseMsg

proc serverGetSchedulerJobs*(self: CouchDb, limit: int, skip: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-jobs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_scheduler/jobs?limit={limit}&skip={skip}")
  
  result = await res.toResponseMsg

proc serverGetSchedulerDocs*(self: CouchDb, limit: int, skip: int = 0, replicatorDb: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var replicator = &"/{replicatorDb}"
  if replicatorDb == "": replicator = ""
  
  let res = await httpRequest.get(&"{self.url}/_scheduler/docs{replicator}?limit={limit}&skip={skip}")
  
  result = await res.toResponseMsg

proc serverGetSchedulerDocs*(self: CouchDb, replicatorDb: string, docId: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_scheduler-docs-replicator_db-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_scheduler/docs/{replicatorDb}/{docId}")
  
  result = await res.toResponseMsg

proc serverGetNode*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}")
  
  result = await res.toResponseMsg

proc serverGetNodeStats*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_stats
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}/_stats/couchdb/request_time")
  
  result = await res.toResponseMsg

proc serverGetNodePrometheus*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_prometheus
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}/_prometheus")
  
  result = await res.toResponseMsg

proc serverGetNodeSystem*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_system
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}/_system")
  
  result = await res.toResponseMsg

proc serverPostNodeRestart*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#post--_node-node-name-_restart
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_node/{nodeName}/_restart")
  
  result = await res.toResponseMsg

proc serverGetNodeVersions*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_node-node-name-_versions
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}/_versions")
  
  result = await res.toResponseMsg

proc serverPostSearchAnalyze*(self: CouchDb, field: string, text: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#post--_search_analyze
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let jsonData = %*{
    "analyzer": field,
    "text": text
  }
  let res = await httpRequest.post(&"{self.url}/_search_analyze", $jsonData)
  
  result = await res.toResponseMsg

proc serverGetUp*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_up
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_up")
  
  result = await res.toResponseMsg

proc serverGetUUIDs*(self: CouchDb, count: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_uuids
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_uuids")
  
  result = await res.toResponseMsg

proc serverGetReshard*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_reshard")
  
  result = await res.toResponseMsg

proc serverGetReshardState*(self: CouchDb): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-state
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_reshard/state")
  
  result = await res.toResponseMsg

proc serverPutReshardState*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#put--_reshard-state
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.put(&"{self.url}/_reshard/state", $jsonData)
  
  result = await res.toResponseMsg

proc serverGetReshardJobs*(self: CouchDb, jobId: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = ""
  if jobId != "": qstring = &"/{jobId}"
  
  let res = await httpRequest.get(&"{self.url}/_reshard/jobs{qstring}")
  
  result = await res.toResponseMsg

proc serverPostReshardJobs*(self: CouchDb, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#post--_reshard-jobs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_reshard/jobs", $jsonData)
  
  result = await res.toResponseMsg

proc serverDeleteReshardJobs*(self: CouchDb, jobId: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#delete--_reshard-jobs-jobid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.delete(&"{self.url}/_reshard/jobs/{jobId}")
  
  result = await res.toResponseMsg

proc serverGetReshardJobsState*(self: CouchDb, jobId: string, state: string, reason: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/_reshard/jobs/{jobId.encodeUrl}/state?state={state.encodeUrl}&state_reason={reason.encodeUrl}")
  
  result = await res.toResponseMsg

proc serverPutReshardJobsState*(self: CouchDb, jobId: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/common.html#get--_reshard-jobs-jobid-state
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.put(&"{self.url}/_reshard/jobs/{jobId}/state", $jsonData)
  
  result = await res.toResponseMsg

proc serverGetNodeConfig*(self: CouchDb, nodeName: string, section: string = "", key: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#get--_node-node-name-_config-section-key
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = ""
  if section != "": qstring &= &"/{section}"
  if key != "": qstring &= &"/{key}"
  
  let res = await httpRequest.get(&"{self.url}/_node/{nodeName}/_config{qstring}")
  
  result = await res.toResponseMsg

proc serverPutNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string, value: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#put--_node-node-name-_config-section-key
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.put(&"{self.url}/_node/{nodeName}/_config/{section}/{key}", $ %value)
  
  result = await res.toResponseMsg

proc serverDeleteNodeConfig*(self: CouchDb, nodeName: string, section: string, key: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#delete--_node-node-name-_config-section-key
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.delete(&"{self.url}/_node/{nodeName}/_config/{section}/{key}")
  
  result = await res.toResponseMsg

proc serverPostNodeConfigReload*(self: CouchDb, nodeName: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/server/configuration.html#post--_node-node-name-_config-_reload
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/_node/{nodeName}/_config/_reload")
  
  result = await res.toResponseMsg

proc databaseGetInfo*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/common.html#get--db
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}")
  result = await res.toResponseMsg

proc databasePut*(self: CouchDb, db: string, shards: int = 8, replicas: int = 3, partitioned: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/common.html#put--db
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}?q={shards}&n={replicas}&partitioned={partitioned}")
  
  result = await res.toResponseMsg


proc databaseDelete*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/common.html#delete--db
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}")
  
  result = await res.toResponseMsg

proc databasePost*(self: CouchDb, db: string, document: JsonNode, batch: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/common.html#post--db
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = ""
  if batch: qstring &= "?batch=ok"
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}", $document)
  
  result = await res.toResponseMsg

proc databaseGetAllDocs*(self: CouchDb, db: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_all_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_all_docs{qstring}")
  
  result = await res.toResponseMsg

proc databasePostAllDocs*(self: CouchDb, db: string, jsonData: JsonNode, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_all_docs{qstring}", $jsonData)
  
  result = await res.toResponseMsg

proc databaseGetDesignDocs*(self: CouchDb, db: string, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#get--db-_design_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = &"?descending={descending}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&include_docs={includeDocs}"
  qstring &= &"&inclusive_end={inclusiveEnd}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not startkeyDocId.isNil: qstring &= &"&startkey_docid={encodeUrl($startkey_docid)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if not endkeyDocId.isNil: qstring &= &"&endkey_docid={encodeUrl($endkey_docid)}"
  if not key.isNil: qstring &= &"&key={encodeUrl($key)}"
  if keys.len != 0: qstring &= &"&keys={encodeUrl($ %keys)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design_docs{qstring}")
  
  result = await res.toResponseMsg

proc databasePostDesignDocs*(self: CouchDb, db: string, jsonData: JsonNode, conflicts: bool = false, descending: bool = false, startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, includeDocs: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_design_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?descending={descending}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&include_docs={includeDocs}"
  qstring &= &"&inclusive_end={inclusiveEnd}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not startkeyDocId.isNil: qstring &= &"&startkey_docid={encodeUrl($startkey_docid)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if not endkeyDocId.isNil: qstring &= &"&endkey_docid={encodeUrl($endkey_docid)}"
  if not key.isNil: qstring &= &"&key={encodeUrl($key)}"
  if keys.len != 0: qstring &= &"&keys={encodeUrl($ %keys)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_design_docs{qstring}", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostAllDocsQueries*(self: CouchDb, db: string, queries: JsonNode): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_all_docs-queries
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_all_docs/queries", $queries)
  
  result = await res.toResponseMsg

proc databasePostBulkGet*(self: CouchDb, db: string, jsonData: JsonNode, revs: bool = true): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_get
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_bulk_get?revs={revs}", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostBulkDocs*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ## https://docs.couchdb.org/en/latest/api/database/bulk-api.html#post--db-_bulk_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_bulk_docs", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostFind*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_find
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_find", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostIndex*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_index
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_index", $jsonData)
  
  result = await res.toResponseMsg

proc databaseGetIndex*(self: CouchDb, db: string, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#get--db-_index
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = &""
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  if qstring != "": qstring = "?" & qstring[1 .. (qstring.len() - 1)]
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_index{qstring}")
  
  result = await res.toResponseMsg

proc databaseDeleteIndex*(self: CouchDb, db: string, ddoc: string, name: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#delete--db-_index-designdoc-json-name
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}/_index/{ddoc.encodeUrl}/json/{name.encodeUrl}")
  
  result = await res.toResponseMsg

proc databasePostExplain*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_explain", $jsonData)
  
  result = await res.toResponseMsg

proc databaseGetShards*(self: CouchDb, db: string, docId: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards
  ##  https://docs.couchdb.org/en/latest/api/database/shard.html#get--db-_shards-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = ""
  if docId != "":
    qstring = &"/{docId.encodeUrl}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_shards{qstring}")
  
  result = await res.toResponseMsg

proc databasePostSyncShards*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/shard.html#post--db-_sync_shards
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_sync_shards")
  
  result = await res.toResponseMsg

proc databaseGetChanges*(self: CouchDb, db: string, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/changes.html#get--db-_changes
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = "?descending={descending}"
  if docIds.len != 0: qstring &= &"&doc_ids={$ %docIds}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&feed={feed}"
  if filter != "": qstring &= &"&filter={filter}"
  qstring &= &"&heartbeat={heartbeat}"
  qstring &= &"&include_docs={includeDocs}"
  qstring &= &"&attachments={attachments}"
  qstring &= &"&att_encoding_info={attEncodingInfo}"
  if lastEventId != 0: qstring &= &"&last-event-id={lastEventId}"
  if limit != 0: qstring &= &"&limit={limit}"
  qstring &= &"&since={since}"
  qstring &= &"&style={style}"
  qstring &= &"&timeout={timeout}"
  if view != "": qstring &= &"&view={view}"
  if seqInterval != 0: qstring &= &"&seq_interval={seqInterval}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_changes{qstring}")
  
  result = await res.toResponseMsg

proc databasePostChanges*(self: CouchDb, db: string, jsonData: JsonNode, docIds: seq[string] = @[], conflicts: bool = false, descending: bool = false, feed: string = "normal", filter: string = "", heartbeat: int = 60000, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, lastEventId: int = 0, limit: int = 0, since: string = "now", style: string = "main_only", timeout: int = 60000, view: string = "", seqInterval: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/changes.html#post--db-_changes
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = "?descending={descending}"
  if docIds.len != 0: qstring &= &"&doc_ids={$ %docIds}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&feed={feed}"
  if filter != "": qstring &= &"&filter={filter}"
  qstring &= &"&heartbeat={heartbeat}"
  qstring &= &"&include_docs={includeDocs}"
  qstring &= &"&attachments={attachments}"
  qstring &= &"&att_encoding_info={attEncodingInfo}"
  if lastEventId != 0: qstring &= &"&last-event-id={lastEventId}"
  if limit != 0: qstring &= &"&limit={limit}"
  qstring &= &"&since={since}"
  qstring &= &"&style={style}"
  qstring &= &"&timeout={timeout}"
  if view != "": qstring &= &"&view={view}"
  if seqInterval != 0: qstring &= &"&seq_interval={seqInterval}"
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_changes{qstring}", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostCompact*(self: CouchDb, db: string, ddoc: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact
  ##  https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_compact-ddoc
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = ""
  if ddoc != "": qstring = &"/{ddoc}"
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_compact{qstring}")
  
  result = await res.toResponseMsg

proc databasePostViewCleanup*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/compact.html#post--db-_view_cleanup
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_view_cleanup")
  
  result = await res.toResponseMsg

proc databaseGetSecurity*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/security.html#get--db-_security
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_security")
  
  result = await res.toResponseMsg

proc databasePutSecurity*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/security.html#put--db-_security
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_security", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostPurge*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_purge
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_purge", $jsonData)
  
  result = await res.toResponseMsg

proc databaseGetPurgedInfosLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_purged_infos_limit
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_purged_infos_limit")
  
  result = await res.toResponseMsg

proc databasePutPurgedInfosLimit*(self: CouchDb, db: string, purgedInfosLimit: int): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_purged_infos_limit
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self, useBasicAuth = true)
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_purged_infos_limit", $ %purgedInfosLimit)
  
  result = await res.toResponseMsg

proc databasePostMissingRevs*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_missing_revs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_missing_revs", $jsonData)
  
  result = await res.toResponseMsg

proc databasePostRevsDiff*(self: CouchDb, db: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#post--db-_revs_diff
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_revs_diff", $jsonData)
  
  result = await res.toResponseMsg

proc databaseGetRevsLimit*(self: CouchDb, db: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#get--db-_revs_limit
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_revs_limit")
  
  result = await res.toResponseMsg

proc databasePutRevsLimit*(self: CouchDb, db: string, revsLimit: int): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/database/misc.html#put--db-_revs_limit
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_revs_limit", $ %revsLimit)
  
  result = await res.toResponseMsg

proc documentGet*(self: CouchDb, db: string, docId: string, attachments: bool = false, attEncodingInfo: bool = false, attsSince: seq[string] = @[], conflicts: bool = false, deletedConflicts: bool = false, latest: bool = false, localSeq: bool = false, meta: bool = false, openRevs: seq[string] = @[], rev: string = "", revs: bool = false, revsInfo: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/common.html#get--db-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = &"?attachments={attachments}"
  qstring &= &"&att_encoding_info={attEncodingInfo}"
  if attsSince.len != 0: qstring &= &"&atts_since={encodeUrl($ %attsSince)}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&deleted_conflicts={deletedConflicts}"
  qstring &= &"&latest={latest}"
  qstring &= &"&local_seq={localSeq}"
  qstring &= &"&meta={meta}"
  if openRevs.len != 0: qstring &= &"&open_revs={encodeUrl($ %openRevs)}"
  if rev != "": qstring &= &"&rev={rev.encodeUrl}"
  qstring &= &"&revs={revs}"
  qstring &= &"&revsInfo={revsInfo}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?new_edits={newEdits}"
  if rev != "": qstring &= "&rev={rev}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}{qstring}", $data)
  
  result = await res.toResponseMsg

proc documentPut*(self: CouchDb, db: string, docId: string, data: JsonNode, attachments: seq[DocumentAttachment], rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/common.html#creating-multiple-attachments
  ##
  let docAttachments = await newDocumentWithAttachments(data, attachments)
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  httpRequest.headers["Content-Type"] = &"multipart/related;boundary=\"{docAttachments.boundary}\""
  httpRequest.headers["Content-Length"] = $docAttachments.length
  
  var qstring = &"?new_edits={newEdits}"
  if rev != "": qstring &= &"&rev={rev}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}{qstring}", docAttachments.body)
  
  result = await res.toResponseMsg

proc documentDelete*(self: CouchDb, db: string, docId: string, rev: string, batch: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/common.html#delete--db-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?rev={rev.encodeUrl}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc documentGetAttachment*(self: CouchDb, db: string, docId: string, attachment: string, bytesRange: tuple[start: int, stop: int] = (0, 0), rev: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/attachments.html#get--db-docid-attname
  ##  support get range https://datatracker.ietf.org/doc/html/rfc2616.html#section-14.27
  ##  bytesRange = (0, 1000) -> get get from 0 to 1000 range bytes
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  if bytesRange.stop != 0 and bytesRange.stop >= bytesRange.start:
    httpRequest.headers["Range"] = &"bytes={bytesRange.start}-{bytesRange.stop}"
  
  var qstring = ""
  if rev != "": qstring = &"?rev={rev}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}/{attachment.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc documentPutAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, attachment: string, contentType: string, rev: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  httpRequest.headers["Content-Type"] = contentType
  
  var qstring = ""
  if rev != "": qstring = &"?rev={rev}"

  var fileContent = attachment
  if attachment.fileExists:
    let fileAsync = openAsync(attachment, fmRead)
    fileContent = await fileAsync.readAll
    fileAsync.close
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}/{attachmentName.encodeUrl}{qstring}", fileContent)
  
  result = await res.toResponseMsg

proc documentDeleteAttachment*(self: CouchDb, db: string, docId: string, attachmentName: string, rev: string, batch: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/attachments.html#put--db-docid-attname
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?rev={rev}"
  if batch: qstring = "&batch=ok"
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}/{docId.encodeUrl}/{attachmentName.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentGetView*(self: CouchDb, db: string, ddoc: string, view: string, conflicts: bool = false, descending: bool = false, endkey: JsonNode = nil, endkeyDocId: JsonNode = nil, group: bool = false, groupLevel: int = 0, includeDocs: bool = false, attachments: bool = false, attEncodingInfo: bool = false, inclusiveEnd: bool = true, key: JsonNode = nil, keys: seq[JsonNode] = @[], limit: int = 0, reduce: bool = true, skip: int = 0, sorted: bool = true, stable: bool = false, stale: string = "", startkey: JsonNode = nil, startkeyDocId: JsonNode = nil, update: string = "true", updateSeq: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)

  var qstring = &"?conflicts={conflicts}"
  qstring &= &"&descending={descending}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if not endkeyDocId.isNil: qstring &= &"&endkey_docid={encodeUrl($endkeyDocId)}"
  qstring &= &"&group={group}"
  if groupLevel != 0: qstring &= &"&group_level={groupLevel}"
  qstring &= &"&include_docs={includeDocs}"
  qstring &= &"&attachments={attachments}"
  qstring &= &"&att_encoding_info={attEncodingInfo}"
  qstring &= &"&inclusive_end={inclusiveEnd}"
  if not key.isNil: qstring &= &"&key={encodeUrl($key)}"
  if keys.len != 0: qstring &= &"&keys={encodeUrl($ %keys)}"
  if limit != 0: qstring &= &"&limit={limit}"
  qstring &= &"&reduce={reduce}"
  if skip != 0: qstring &= &"&skip={skip}"
  qstring &= &"&sorted={sorted}"
  qstring &= &"&stable={stable}"
  if stale != "": qstring &= &"&stale={stale}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not startkeyDocId.isNil: qstring &= &"&startkey_docid={encodeUrl($startkeyDocId)}"
  qstring &= &"&update={update}"
  qstring &= &"&update_seq={updateSeq}"

  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_view/{view.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentPostView*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)

  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_view/{view.encodeUrl}", $jsonData)

  result = await res.toResponseMsg

proc designDocumentPostViewQueries*(self: CouchDb, db: string, ddoc: string, view:string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/views.html#post--db-_design-ddoc-_view-view-queries
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)

  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_view/{view.encodeUrl}/queries", $jsonData)

  result = await res.toResponseMsg

proc designDocumentGetSearch*(self: CouchDb, db: string, ddoc: string, index: string, bookmark: string = "", counts: JsonNode = nil, drilldown: JsonNode = nil, groupField: string = "", groupSort: JsonNode = nil, highlightFields: JsonNode = nil, highlightPreTag: string = "", highlightPostTag: string = "", highlightNumber: int = 0, highlightSize: int = 0, includeDocs: bool = false, includeFields: JsonNode = nil, limit: int = 0, query: string = "", ranges: JsonNode = nil, sort: JsonNode = nil, stale: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search-index
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)

  var qstring = &"?include_docs={includeDocs}"
  if bookmark != "": qstring &= &"&bookmark={bookmark.encodeUrl}"
  if not counts.isNil: qstring &= &"&counts={encodeUrl($counts)}"
  if not drilldown.isNil: qstring &= &"&drilldown={encodeUrl($drilldown)}"
  if groupField != "": qstring &= &"&group_field={groupField.encodeUrl}"
  if not groupSort.isNil: qstring &= &"&group_sort={encodeUrl($groupSort)}"
  if not highlightFields.isNil: qstring &= &"&highlight_fields={encodeUrl($highlightFields)}"
  if highlightPreTag != "": qstring &= &"&highlight_pre_tag={highlightPreTag.encodeUrl}"
  if highlightPostTag != "": qstring &= &"&highlight_post_tag={highlightPostTag.encodeUrl}"
  if highlightSize != 0: qstring &= &"&highlight_size={highlightSize}"
  if not includeFields.isNil: qstring &= &"&include_fields={encodeUrl($includeFields)}"
  if limit != 0: qstring &= &"&limit={limit}"
  if query != "": qstring &= &"&query={query.encodeUrl}"
  if not ranges.isNil: qstring &= &"&ranges={encodeUrl($ranges)}"
  if not sort.isNil: qstring &= &"&sort={encodeUrl($sort)}"
  if stale != "": qstring &= &"&stale={stale.encodeUrl}"

  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_search/{index.encodeUrl}{qstring}")

  result = await res.toResponseMsg

proc designDocumentGetSearchInfo*(self: CouchDb, db: string, ddoc: string, index: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/search.html#get--db-_design-ddoc-_search_info-index
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)

  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_search_info/{index.encodeUrl}")

  result = await res.toResponseMsg

proc designDocumentPostUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, jsonData: JsonNode = nil): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/render.html#post--db-_design-ddoc-_update-func
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)

  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_update/{function.encodeUrl}", $jsonData)

  result = await res.toResponseMsg

proc designDocumentPutUpdateFunc*(self: CouchDb, db: string, ddoc: string, function: string, docId: string, jsonData: JsonNode = nil): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/render.html#put--db-_design-ddoc-_update-func-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)

  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/_update/{function.encodeUrl}/{docId.encodeUrl}", $jsonData)

  result = await res.toResponseMsg

proc partitionDatabaseGet*(self: CouchDb, db: string, partition: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)

  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_partition/{partition.encodeUrl}")

  result = await res.toResponseMsg

proc partitionDatabaseGetAllDocs*(self: CouchDb, db: string, partition: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_all_docs
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_partition/{partition.encodeUrl}/_all_docs{qstring}")
  
  result = await res.toResponseMsg

proc partitionDatabaseGetDesignView*(self: CouchDb, db: string, partition: string, ddoc: string, view: string, descending: bool = false, startkey: JsonNode = nil, endkey: JsonNode = nil, skip: int = 0, limit: int = 0): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#get--db-_partition-partition-_design-ddoc-_view-view
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self, useBasicAuth = true)
  
  var qstring = &"?descending={descending}"
  if not startkey.isNil: qstring &= &"&startkey={encodeUrl($startkey)}"
  if not endkey.isNil: qstring &= &"&endkey={encodeUrl($endkey)}"
  if skip != 0: qstring &= &"&skip={skip}"
  if limit != 0: qstring &= &"&limit={limit}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_partition/{partition.encodeUrl}/_design/{ddoc.encodeUrl}/_view/{view.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc partitionDatabasePostFind*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_find
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_partition/{partition.encodeUrl}/_find", $jsonData)
  
  result = await res.toResponseMsg

proc partitionDatabasePostExplain*(self: CouchDb, db: string, partition: string, jsonData: JsonNode): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/partitioned-dbs.html#post--db-_partition-partition_id-_explain
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  ##  https://docs.couchdb.org/en/latest/api/database/find.html#post--db-_explain
  let res = await httpRequest.post(&"{self.url}/{db.encodeUrl}/_partition/{partition.encodeUrl}/_explain", $jsonData)
  
  result = await res.toResponseMsg

proc designDocumentGet*(self: CouchDb, db: string, ddoc: string, attachments: bool = false, attEncodingInfo: bool = false, attsSince: seq[string] = @[], conflicts: bool = false, deletedConflicts: bool = false, latest: bool = false, localSeq: bool = false, meta: bool = false, openRevs: seq[string] = @[], rev: string = "", revs: bool = false, revsInfo: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#get--db-_design-ddoc
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  
  var qstring = &"?attachments={attachments}"
  qstring &= &"&att_encoding_info={attEncodingInfo}"
  if attsSince.len != 0: qstring &= &"&atts_since={encodeUrl($ %attsSince)}"
  qstring &= &"&conflicts={conflicts}"
  qstring &= &"&deleted_conflicts={deletedConflicts}"
  qstring &= &"&latest={latest}"
  qstring &= &"&local_seq={localSeq}"
  qstring &= &"&meta={meta}"
  if openRevs.len != 0: qstring &= &"&open_revs={encodeUrl($ %openRevs)}"
  if rev != "": qstring &= &"&rev={rev.encodeUrl}"
  qstring &= &"&revs={revs}"
  qstring &= &"&revsInfo={revsInfo}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentPut*(self: CouchDb, db: string, ddoc: string, data: JsonNode, rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/document/common.html#put--db-docid
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?new_edits={newEdits}"
  if rev != "": qstring &= "&rev={rev}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}{qstring}", $data)
  
  result = await res.toResponseMsg

proc designDocumentPut*(self: CouchDb, db: string, ddoc: string, data: JsonNode, attachments: seq[DocumentAttachment], rev: string = "", batch: bool = false, newEdits: bool = true): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc
  ##
  let docAttachments = await newDocumentWithAttachments(data, attachments)
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  httpRequest.headers["Content-Type"] = &"multipart/related;boundary=\"{docAttachments.boundary}\""
  httpRequest.headers["Content-Length"] = $docAttachments.length
  
  var qstring = &"?new_edits={newEdits}"
  if rev != "": qstring &= &"&rev={rev}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}{qstring}", docAttachments.body)
  
  result = await res.toResponseMsg

proc designDocumentDelete*(self: CouchDb, db: string, ddoc: string, rev: string, batch: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#delete--db-_design-ddoc
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?rev={rev.encodeUrl}"
  if batch: qstring &= &"&batch=ok"
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentGetAttachment*(self: CouchDb, db: string, ddoc: string, attachment: string, bytesRange: tuple[start: int, stop: int] = (0, 0), rev: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#get--db-_design-ddoc-attname
  ##  support get range https://datatracker.ietf.org/doc/html/rfc2616.html#section-14.27
  ##  bytesRange = (0, 1000) -> get get from 0 to 1000 range bytes
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)
  if bytesRange.stop != 0 and bytesRange.stop >= bytesRange.start:
    httpRequest.headers["Range"] = &"bytes={bytesRange.start}-{bytesRange.stop}"
  
  var qstring = ""
  if rev != "": qstring = &"?rev={rev}"
  
  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/{attachment.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentPutAttachment*(self: CouchDb, db: string, ddoc: string, attachmentName: string, attachment: string, contentType: string, rev: string = ""): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#put--db-_design-ddoc-attname
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  httpRequest.headers["Content-Type"] = contentType
  
  var qstring = ""
  if rev != "": qstring = &"?rev={rev}"

  var fileContent = attachment
  if attachment.fileExists:
    let fileAsync = openAsync(attachment, fmRead)
    fileContent = await fileAsync.readAll
    fileAsync.close
  
  let res = await httpRequest.put(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/{attachmentName.encodeUrl}{qstring}", fileContent)
  
  result = await res.toResponseMsg

proc designDocumentDeleteAttachment*(self: CouchDb, db: string, ddoc: string, attachmentName: string, rev: string, batch: bool = false): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#delete--db-_design-ddoc-attname
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestPostJsonHeaders(self)
  
  var qstring = &"?rev={rev}"
  if batch: qstring = "&batch=ok"
  
  let res = await httpRequest.delete(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}/{attachmentName.encodeUrl}{qstring}")
  
  result = await res.toResponseMsg

proc designDocumentGetInfo*(self: CouchDb, db: string, ddoc: string): Future[JsonNode] {.async.} =
  ##
  ##  https://docs.couchdb.org/en/latest/api/ddoc/common.html#get--db-_design-ddoc-_info
  ##
  let httpRequest = newHttpRequest()
  httpRequest.prepareRequestHeaders(self)

  let res = await httpRequest.get(&"{self.url}/{db.encodeUrl}/_design/{ddoc.encodeUrl}")
  
  result = await res.toResponseMsg
