c = require './../schemas'

BranchSchema = {
  type: 'object'
  properties: {
    patches: {
      type: 'array'
      items: {
        type: 'object'
        # TODO: Link to Patch schema
      }
    }
  }
}

c.extendBasicProperties(BranchSchema, 'branches')
c.extendNamedProperties(BranchSchema)

module.exports = BranchSchema
