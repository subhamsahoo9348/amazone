# `model_srv.js` — File Map & Notes

Location: `srv/model_srv.js`
Service class: `adminService` (extends `cds.ApplicationService`)

---

## High-level purpose

When a customer places (or updates) an order in `customerService`, this admin
service automatically:

1. Picks the **nearest warehouse** that has stock for each ordered item.
2. Creates a **Shipment** record per item, sourced from that warehouse, addressed
   to the customer.
3. Tries to **assign a delivery vehicle** (with an active driver) for that
   shipment.

---

## Entity references

Pulled from `cds.entities(...)` at `init()` time:

| Local name              | Service           | Notes                                  |
| ----------------------- | ----------------- | -------------------------------------- |
| `adminGetOrder`         | adminService      | Aliased but currently unused           |
| `getCustomer`           | adminService      | Lookup customer by `name = user.id`    |
| `getWarehouseInventory` | adminService      | Stock per (warehouse, product)         |
| `getWareHouse`          | adminService      | Warehouse master (has lat/long)        |
| `getShipment`           | adminService      | Target of `INSERT` after order created |
| `getProduct`            | adminService      | Read product weight for shipment       |
| `getVehicle`            | adminService      | Capacity + assigned warehouse + driver |
| `custGetOrder`          | customerService   | The trigger entity (after CREATE/UPDATE) |

---

## Event hook

```
this.after(["CREATE", "UPDATE"], custGetOrder, ...)
  └─ setImmediate(() => createShipment(res, req.user))
```

- Fires after the customer-side `Order` is created/updated.
- Uses `setImmediate` so the response to the customer isn't blocked by
  shipment creation.

---

## Flow diagram

```
Customer creates/updates Order
        │
        ▼
this.after("CREATE"|"UPDATE", custGetOrder)
        │
        ▼
createShipment(results, user)
   │
   ├─ SELECT customer by user.id   ── customer (with address + lat/long)
   │
   ├─ For each item in results.items:                ┐
   │     │                                            │
   │     ├─ SELECT WarehouseInventory rows where      │  builds
   │     │     product_ID = item.product_ID           │  productWarehouses[]:
   │     │     AND quantityAvailable > item.quantity  │   { product,
   │     │                                            │     nearestWarehouseId }
   │     ├─ For each candidate warehouse:             │
   │     │     ├─ SELECT WareHouse by ID              │
   │     │     ├─ getDistanceInKm(customer, wh)       │
   │     │     └─ return { warehouse_ID, distance }   │
   │     │                                            │
   │     ├─ sort by distance asc → pick [0]           │
   │     │     → nearestWarehouseId                   │
   │     │                                            │
   │     └─ SELECT product by item.product_ID         ┘
   │
   └─ For each { product, nearestWarehouseId }:
         ├─ INSERT Shipment(sourceWarehouse, product, weight, dest address)
         └─ assignDelivery(nearestWarehouseId, product, destAddress)  ← WIP
```

---

## Helpers

### `getDistanceInKm(userLocation, targetLocation)`

- Standard **Haversine formula** (R = 6371 km).
- Inputs: `{ latitude, longitude }` objects.
- Returns: great-circle distance in km.
- Used to rank candidate warehouses by proximity to the customer.

### `assignDelivery(warehouseId, product, targetLocation)` ⚠️ **incomplete**

Currently only does the vehicle lookup:

```js
SELECT.from(getVehicle)
  .where({ assignWareHouse_ID: warehouseId })
  .and("maxLoadCapacity >", product.weight)
  .and({ "driver.status": "A" })           // driver Active
```

**Open ends (per the TS diagnostics on this file):**

- `vehicle` is fetched but never used → no record is written.
- `targetLocation` parameter is accepted but never used.
- There is a `debugger;` left in the function body.

**Likely next steps when you pick this up again:**

1. Pick one vehicle from the result (probably the first / least loaded).
2. INSERT a `DeliveryAssignment` row linking
   `vehicle` ↔ `shipment` (and probably the destination address from
   `targetLocation`).
3. Handle the empty-result case (no vehicle/driver available).
4. Remove the `debugger;`.

---

## Known smells / things to revisit

- **Customer lookup uses `name`**: `SELECT.one(getCustomer).where({ name: user.id })`.
  Confirm this is intentional — usually you'd key by an ID/email field.
- **`forEach` with `async` callback** (line 66): the outer `createShipment`
  does not `await` the inner shipments/deliveries. Errors thrown inside the
  callback won't reach the surrounding `try/catch`.
- **`results.items` is assumed truthy**: no guard if the order has no items.
- **`nearestWarehouseId` may be `undefined`** if no warehouse has stock — the
  shipment still gets INSERTed with `sourceWarehouse_ID: undefined`.
- **Destination address object is duplicated** between the Shipment INSERT
  and the `assignDelivery` call.
- **`adminGetOrder` alias is imported but never used.**
- **Two `debugger;` statements** still in the file (catch block + `assignDelivery`).

---

## Where to resume

Open `srv/model_srv.js` at line **113** (`assignDelivery`). That is the
unfinished piece — wire the fetched `vehicle` into an actual
DeliveryAssignment INSERT, using `targetLocation` for the drop-off address.
