const cds = require('@sap/cds')

module.exports = class adminService extends cds.ApplicationService {
  init() {

    const { getOrder } = cds.entities('adminService')

    this.after(['CREATE', 'UPDATE'], getOrder, async (req) => {
      debugger
      console.log('Before CREATE/UPDATE getOrder', req.data)
    })



    return super.init()
  }
}
