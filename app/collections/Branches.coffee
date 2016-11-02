CocoCollection = require 'collections/CocoCollection'
Branch = require 'models/Branch'

module.exports = class Branches extends CocoCollection
  url: '/db/branches'
  model: Branch
