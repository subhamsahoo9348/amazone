const cds = require('@sap/cds')

module.exports = class adminService extends cds.ApplicationService {
  init() {

    const { getOrder: adminGetOrder } = cds.entities('adminService')
    const { getOrder: custGetOrder } = cds.entities('customerService')

    this.after(['CREATE', 'UPDATE'], custGetOrder, async (req) => {
      debugger
      console.log('Before CREATE/UPDATE getOrder', req.data)
    })

    


    return super.init()
  }
}
