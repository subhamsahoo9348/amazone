const cds = require('@sap/cds');

module.exports = class adminService extends cds.ApplicationService {
  init() {

    const { getOrder: adminGetOrder, getCustomer, getWarehouseInventory, getWareHouse } = cds.entities('adminService')
    const { getOrder: custGetOrder } = cds.entities('customerService')

    this.after(['CREATE', 'UPDATE'], custGetOrder, async (res, req) => {
      setImmediate(() => createShipment(res, req.user));
    });

    async function createShipment(results, user) {

      const customer = await SELECT.one(getCustomer).where({ name: user.id });

      const wareHouseMap = new Map();



      await Promise.all(results.items.map(async item => {
        const availbleWareHosue = await SELECT.from(getWarehouseInventory)
          .where({ product_ID: item.product_ID }).and('quantityAvailable >', item.quantity);
        
        // availbleWareHosue.sort((a, b) => {

        // })

        // debugger  find the nearest warshouse


        availbleWareHosue.forEach(w => {
          const id = w.warehouse_ID;
          let warehouseProd = wareHouseMap.get(id);
          if (!warehouseProd) {
            warehouseProd = new Set();
            wareHouseMap.set(id, warehouseProd);
          }

          warehouseProd.add(item.product_ID);


        });
      }))

      debugger


    }

    function nearDistance(a, b) {
      debugger
    }

    function getDistanceInKm(userLocation, targetLocation) {
      const toRad = (value) => (value * Math.PI) / 180;

      const R = 6371; // Earth's radius in km

      const { latitude: lat1, longitude: lon1 } = userLocation;
      const { latitude: lat2, longitude: lon2 } = targetLocation;

      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);

      const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;

      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      return R * c;
    }

    return super.init()
  }
}
