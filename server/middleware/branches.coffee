errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
Branch = require '../models/Branch'

module.exports =

  post: wrap (req, res) ->
    branch = database.initDoc(req, Branch)
    database.assignBody(req, branch)
    branch.set('updated', new Date().toISOString())
    branch.set('updatedBy', req.user._id)
    database.validateDoc(branch)
    branch = yield branch.save()
    res.status(201).send(branch.toObject({req}))
    
  put: wrap (req, res) ->
    branch = yield database.getDocFromHandle(req, Branch)
    if not branch
      throw new errors.NotFound('Document not found.')
    database.assignBody(req, branch)
    branch.set('updated', new Date().toISOString())
    branch.set('updatedBy', req.user._id)
    database.validateDoc(branch)
    branch = yield branch.save()
    res.status(200).send(branch.toObject())
