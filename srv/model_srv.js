const cds = require('@sap/cds');
const { SELECT, INSERT } = require('@sap/cds/lib/ql/cds-ql');

module.exports = class adminService extends cds.ApplicationService {
  init() {

    const { getOrder: adminGetOrder, getCustomer, getWarehouseInventory, getWareHouse, getShipment, getProduct } = cds.entities('adminService')
    const { getOrder: custGetOrder } = cds.entities('customerService')

    this.after(['CREATE', 'UPDATE'], custGetOrder, async (res, req) => {
      setImmediate(() => createShipment(res, req.user));
    });

    async function createShipment(results, user) {

      const customer = await SELECT.one(getCustomer).where({ name: user.id });

      const productWareHosue = await Promise.all(results.items.map(async item => {
        const availbleWareHosue = await SELECT.from(getWarehouseInventory)
          .where({ product_ID: item.product_ID }).and('quantityAvailable >', item.quantity);



        const WareHosueDistances = await Promise.all(availbleWareHosue.map(async wareHouse => {

          const wareHosue = await SELECT.one(getWareHouse).where({ ID: wareHouse.warehouse_ID });

          const userLocation = { latitude: customer.address_latitude, longitude: customer.address_latitude };
          const wareHouseLocation = { latitude: wareHosue.address_latitude, longitude: wareHosue.address_latitude };

          const distnace = getDistanceInKm(userLocation, wareHouseLocation);

          return { warehouse_ID: wareHouse.warehouse_ID, distnace }


        }));
        const nearWareHosue = WareHosueDistances.sort((a, b) => a.distnace - b.distnace)[0].warehouse_ID;

        const product = await SELECT.one(getProduct).where({ ID: item.product_ID })

        return { product: product, nearWareHosue: nearWareHosue }


      }))

      

      // productWareHosue.forEach(async ({ product, nearWareHosue }) => {
      //   INSERT.into(getShipment).entries({
      //     sourceWarehouse_ID: nearWareHosue,
      //     product_ID: product.ID,
      //     weight: product.weight,
      //     destinationAddress_street: customer.address_stree,
      //     destinationAddress_city: customer.address_city,
      //     destinationAddress_state: customer.address_state,
      //     destinationAddress_zipCode: customer.address_zipCode,
      //     destinationAddress_latitude: customer.address_latitude,
      //     destinationAddress_longitude: customer.address_longitude
      //   });
      // })


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
