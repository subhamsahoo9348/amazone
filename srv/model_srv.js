const cds = require("@sap/cds");
const { SELECT, INSERT, UPDATE } = require("@sap/cds/lib/ql/cds-ql");

module.exports = class adminService extends cds.ApplicationService {
  init() {
    const {
      getOrder: adminGetOrder,
      getCustomer,
      getWarehouseInventory,
      getWareHouse,
      getShipment,
      getProduct,
      getVehicle,
      getDriver,
      getDeliveryAssignment,
    } = cds.entities("adminService");
    const { getOrder: custGetOrder } = cds.entities("customerService");

    this.before("CREATE", custGetOrder, (req) => {
      if (!req.data.orderDate) {
        req.data.orderDate = new Date().toISOString().slice(0, 10);
      }
    });

    this.after(["CREATE", "UPDATE"], custGetOrder, async (res, req) => {
      setImmediate(() => createShipment(res, req.user));
    });

    async function createShipment(results, user) {
      try {
        const customer = await SELECT.one(getCustomer).where({ name: user.id });

        const productWarehouses = await Promise.all(
          results.items.map(async (item) => {
            const availableWarehouses = await SELECT.from(getWarehouseInventory)
              .where({ product_ID: item.product_ID })
              .and("quantityAvailable >", item.quantity);

            const warehouseDistances = await Promise.all(
              availableWarehouses.map(async (wareHouse) => {
                const warehouse = await SELECT.one(getWareHouse).where({
                  ID: wareHouse.warehouse_ID,
                });

                const userLocation = {
                  latitude: customer.address_latitude,
                  longitude: customer.address_longitude,
                };
                const wareHouseLocation = {
                  latitude: warehouse.address_latitude,
                  longitude: warehouse.address_longitude,
                };

                const distance = getDistanceInKm(
                  userLocation,
                  wareHouseLocation,
                );

                return { warehouse_ID: wareHouse.warehouse_ID, distance };
              }),
            );
            const nearestWarehouseId = warehouseDistances.sort(
              (a, b) => a.distance - b.distance,
            )[0]?.warehouse_ID;

            const product = await SELECT.one(getProduct).where({
              ID: item.product_ID,
            });

            return { product: product, nearestWarehouseId: nearestWarehouseId };
          }),
        );

        productWarehouses.forEach(async ({ product, nearestWarehouseId }) => {
          const shipmentId = cds.utils.uuid();
          await INSERT.into(getShipment).entries({
            ID: shipmentId,
            sourceWarehouse_ID: nearestWarehouseId,
            product_ID: product.ID,
            weight: product.weight,
            destinationAddress_street: customer.address_street,
            destinationAddress_city: customer.address_city,
            destinationAddress_state: customer.address_state,
            destinationAddress_zipCode: customer.address_zipCode,
            destinationAddress_latitude: customer.address_latitude,
            destinationAddress_longitude: customer.address_longitude,
          });
          await assignDelivery(shipmentId, nearestWarehouseId, product);
        });
      } catch (error) {
        debugger;
        console.error(error);
      }
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
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      return R * c;
    }

    async function assignDelivery(shipmentId, warehouseId, product) {
      const vehicle = await SELECT.one(getVehicle)
        .where({ assignWareHouse_ID: warehouseId })
        .and("maxLoadCapacity >", product.weight)
        .and({ "driver.status": "A" });

      if (!vehicle) {
        console.warn(
          `assignDelivery: no eligible vehicle at warehouse ${warehouseId} for weight ${product.weight}kg — shipment ${shipmentId} stays Pending`,
        );
        return;
      }

      const driver = await SELECT.one(getDriver).where({
        assignedVehicle_ID: vehicle.ID,
        status: "A",
      });

      if (!driver) {
        console.warn(
          `assignDelivery: vehicle ${vehicle.ID} has no available driver — shipment ${shipmentId} stays Pending`,
        );
        return;
      }

      await INSERT.into(getDeliveryAssignment).entries({
        shipment_ID: shipmentId,
        driver_ID: driver.ID,
        vehicle_ID: vehicle.ID,
        assignedDate: new Date().toISOString().slice(0, 10),
        deliveryStatus: "Assigned",
      });

      await UPDATE(getDriver).set({ status: "B" }).where({ ID: driver.ID });
      await UPDATE(getShipment).set({ status: "A" }).where({ ID: shipmentId });
    }

    return super.init();
  }
};
