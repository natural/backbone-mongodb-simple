_ = require 'underscore'
mongodb = require 'mongodb'


exports.connect = (url, options, callback)->
  if typeof options == 'function'
    callback = options
    options = {}
  mongodb.Db.connect url, options, (err, con)->
    callback err, con


toStrings = (obj, convert=['_id'])->
  convert.map (key)->
    obj[key] = obj[key].toString()
  obj


toObjectIds = (obj, convert=['_id'])->
  convert.map (key)->
    if obj[key] and not obj[key].toHexString
      obj[key] = new mongodb.ObjectID(obj[key])
  obj


# converts the given model to a JSON doc and removes the indicated keys.
#
toDoc = (model, remove=['_id'])->
  obj = model.toJSON()
  remove.map (key)->
    delete obj[key]
  obj


create = (model, callback)->
  model.withCollection (err, collection)->
    if err
      callback err
    else
      collection.insert toDoc(model), (err, docs)->
        if err
          callback err
        else
          callback null, toStrings(docs[0])


read = (model, callback)->
  if model?.id?
    model.withCollection (err, collection)->
      if err
        callback err
      else
        collection.findOne {_id: model.oid()}, {}, (err, doc)->
          if err
            callback err
          else if not doc
            msg = "Could not find #{collection.name}:#{model.id}"
            callback new Error(msg)
          else
            callback null, toStrings(doc)
  else
    model.withCollection (err, collection)->
      if err
        callback err
      else
        collection.find().toArray (err, results)->
          if err
            callback err
          else
            results = _.map results, (result)->
              toStrings(result)
            callback null, results


update = (model, callback)->
  model.withCollection (err, collection)->
    if err
      callback err
    else
      sel = _id: model.oid()
      doc = $set: toDoc(model)
      opt = safe: true, upsert:false
      collection.update sel, doc, opt, (err)->
        if err
          callback err
        else
          callback null, model.toJSON()


destroy = (model, callback)->
  model.withCollection (err, collection)->
    if err
      callback err
    else
      collection.remove {_id: model.oid()}, callback


find = (callback)->
  model = if @cid? then @constructor else @
  @withCollection (err, collection)->
    if err
      callback err
    else
      collection.find().toArray (err, results)->
        if err
          callback err
        else
          results = _.map results, (result)->
            new model(toStrings(result))
          callback null, results


findOne = (query, qoptions, options)->
  error = options?.error or ->
  model = if @cid? then @constructor else @

  @withCollection (err, collection)->
    if err
      return error err
    collection.findOne toObjectIds(query), qoptions, (err, data)->
      if err
        error err
      else if not data
        name = getProp model, 'col'
        msg = "Could not find #{name}:#{JSON.stringify(query)}"
        error new Error(msg)
      else
        data._id = data._id.toString()
        (options?.success or ->) new model(data)


getProp = (obj, name)->
  if obj[name]
    obj[name]
  else
    obj.constructor?[name]


withCollection = (callback)->
  con = getProp @, 'con'
  if not con
    throw new Error('no connection')
  col = getProp @, 'col'
  if not col
    throw new Error('no collection')
  con.collection col, (err, collection)->
    callback err, collection


methods =
  create: create
  read: read
  update: update
  'delete': destroy


install = exports.install = (Backbone)->
  Backbone.sync = (method, model, options)->
    error = options?.error or ->

    if not model.con
      error new Error('sync without connection')
    if not model.col
      error new Error('sync without collection')

    call = methods[method]
    if call
      call model, (err, results)->
        if err
          error err
        else
          (options?.success or ->) results
    else
      error new Error("Unknown sync method #{method}")


  sharedprops =
    con: null # mongodb connection
    col: null # collection name

    find: find
    findOne: findOne
    withCollection: withCollection

    connect: (url, options, callback)->
      self = @
      if typeof options == 'function'
        callback = options
        options = {}
      exports.connect url, options, (err, con)->
        if not err
          self.con = con
        callback err, con

    disconnect: (options, callback)->
      self = @
      self.con.close options?.force or false, (err, result)->
        self.con = null
        callback err, result

  staticprops = _.extend {}, sharedprops, {}

  objprops = _.extend {}, sharedprops,
    idAttribute: '_id'
    oid: ->
      if @id?.toHexString?
        @id
      else if @id?
        new mongodb.ObjectID @id

  extend = _.extend
  extend Backbone.Collection.prototype, objprops
  extend Backbone.Model.prototype, objprops
  extend Backbone.Collection, staticprops
  extend Backbone.Model, staticprops


