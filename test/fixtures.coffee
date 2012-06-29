Backbone = require 'backbone'
exports.mongosync = require '../lib'
exports.mongosync.install Backbone


BackboneRelational = require 'backbone-relational'



exports.localurl = 'mongodb://localhost:27017/backbone-sync-test'
exports.remoteurl = process.env.REMOTE_MONGO_URI


exports.User = User = Backbone.RelationalModel.extend {}
exports.PersonCollection = Backbone.Collection.extend {}


exports.Person = Backbone.RelationalModel.extend
  relations: [
    {
      type: Backbone.HasOne
      key: 'user'
      relatedModel: User
      reverseRelation:
        type: Backbone.HasOne
        key: 'person'
    }
  ]


exports.House = Backbone.RelationalModel.extend
  relations: [
    {
      type: Backbone.HasMany #// Use the type, or the string 'HasOne' or 'HasMany'.
      key: 'occupants'
      relatedModel: exports.Person
      includeInJSON: Backbone.Model.prototype.idAttribute
      collectionType: exports.PersonCollection
      reverseRelation:
        key: 'livesIn'
    }
  ]

