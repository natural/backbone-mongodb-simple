assert = require 'assert'
fixtures = require './fixtures'

Person = fixtures.Person
House = fixtures.House
addr = ['123 Main Street', 'Anytown, USA', 12345]


make = (key, url)->

  # This block tests the static properties 'con' and 'col' on models.
  #
  describe "Model static props (#{key} db)", ->
    it 'should include a null "con" property', (done)->
      assert House.con != undefined
      assert.equal House.con, null
      done()

    it 'should include a null "col" property', (done)->
      assert House.col != undefined
      assert.equal House.col, null
      done()


  # This block tests the static methods 'find' and 'findOne' on models.
  #
  describe "Model static methods (#{key} db)", ->
    walt = new Person name: 'Walt', address: addr
    hank = new Person name: 'Hank', address: addr

    before (done)->
      Person.connect url, (err, con)->
        assert not err
        assert.equal Person.con.state, 'connected'
        Person.col = 'people'
        walt.save {}, success: ->
          assert walt.id
          hank.save {}, success: ->
            assert hank.id
            done()

    it 'should allow static find', (done)->
      assert.equal typeof Person.find, 'function'
      Person.find (err, models)->
        assert models.length == 2
        ids = (obj.id for obj in models)
        assert walt.id in ids
        assert hank.id in ids
        done()

    it 'should allow static findOne', (done)->
      assert.equal typeof Person.findOne, 'function'
      Person.findOne {_id:walt.id}, {},
        success: (model)->
          assert model.id == walt.id
          done()

    it 'should allow collection drop', (done)->
      Person.withCollection (err, collection)->
        assert not err
        collection.drop (err, result)->
          assert not err
          assert result
          done()

    it 'should disconnect when called', (done)->
      Person.disconnect force:true, (err, result)->
        assert not err
        assert Person.con == null
        done()

  # This block tests availability of static properties and methods on model
  # instances, i.e., that model objects can use static attributes.
  #
  describe "Model instance methods from static attributes (#{key} db)", ->
    jessie = new Person name: 'Jessie', address: addr

    before (done)->
      Person.connect url, (err, con)->
        assert.equal Person.con.state, 'connected'
        Person.col = 'people'
        jessie.save {}, success: ->
          assert jessie.id
          done()

    it 'should allow instance find via static', (done)->
      assert.equal typeof jessie.find, 'function'
      jessie.find (err, models)->
        assert models.length == 1
        assert jessie.id in (obj.id for obj in models)
        done()

    it 'should allow instance findOne via static', (done)->
      assert.equal typeof Person.findOne, 'function'
      jessie.findOne {_id:jessie.id}, {},
        success: (model)->
          assert model.id == jessie.id
          done()

    it 'should allow collection drop', (done)->
      jessie.withCollection (err, collection)->
        assert not err
        collection.drop (err, result)->
          assert not err
          assert result
          done()

    it 'should disconnect when called', (done)->
      Person.disconnect force:true, (err, result)->
        assert not err
        assert Person.con == null
        done()

  # This block tests availability of model properties and methods on model
  # instances, i.e., that model objects can use their own attributes.
  #
  describe "Model instance methods from model attributes (#{key})", ->
    skyler = new Person name: 'Skyler', address: addr

    before (done)->
      skyler.connect url, (err, con)->
        assert.equal skyler.con?.state, 'connected'
        skyler.col = 'people'
        skyler.save {}, success: ->
          assert skyler.id
          done()

    it 'should allow instance find', (done)->
      assert.equal typeof skyler.find, 'function'
      skyler.find (err, models)->
        assert models.length == 1
        assert skyler.id in (obj.id for obj in models)
        done()

    it 'should allow instance findOne', (done)->
      assert.equal typeof skyler.findOne, 'function'
      skyler.findOne {_id:skyler.id}, {},
        success: (model)->
          assert model.id == skyler.id
          done()

    it 'should allow collection drop', (done)->
      skyler.withCollection (err, collection)->
        assert not err
        collection.drop (err, result)->
          assert not err
          assert result
          done()

    it 'should disconnect when called', (done)->
      skyler.disconnect force:true, (err, result)->
        assert not err
        assert Person.con == null
        assert skyler.con == null
        done()


  describe "#{key} connection", ->
    home = new House address: addr
    visiting = new House address: addr

    before (done)->
      home.connect url, (err, con)->
        assert home.con
        visiting.con = home.con
        home.col = visiting.col = 'houses'
        done()

    after (done)->
      home.con.dropDatabase (err, result)->
        assert not err
        assert result
        done()

      home.con.close true, (err, result)->
        assert not err
        done()

    it 'should have a good status when connected', (done)->
      assert.equal home.con?.state, 'connected'
      assert home.con?.openCalled
      done()

    it 'should allow insert of new document', (done)->
      home.save {}, success: ->
        done()

    it 'should allow fetch of an existing document', (done)->
      visiting.set '_id', home.id
      visiting.fetch success: ->
        visiting.get('address').map (val, idx)->
          assert.equal val, home.get('address')[idx]
        done()

    it 'should allow updates to an existing document', (done)->
      visiting.set 'address', ['456', 'Oak Lane', 'Othertown, USA', 45678]
      visiting.save {},
        error: -> assert 0
        success: ->
          visiting.fetch
            error: -> assert 0
            success: ->
              assert.equal visiting.get('address')[0], '456'
              done()

    it 'should allow delete of an existing document', (done)->
      home.destroy
        success: ->
          visiting.destroy
            success: ->
              done()


make 'local', fixtures.localurl
make('remote', fixtures.remoteurl) if fixtures.remoteurl
