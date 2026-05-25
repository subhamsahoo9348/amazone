# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start CAP server (auto-seeds from /db/data CSV files)
npm start

# Dev mode with live reload — opens in browser
npm run watch-customer   # customer app
npm run watch-drivers    # drivers app
```

There are no lint or test scripts at the root. UI5 apps have ESLint configs (`app/customer/eslint.config.mjs`, `app/drivers/eslint.config.mjs`) and QUnit/OPA5 test suites under `app/*/webapp/test/`.

## Architecture

This is a **SAP CAP (Cloud Application Programming)** backend with two **SAP UI5 Fiori** frontends, implementing an e-commerce delivery management system.

### Domain Model (`db/model.cds`)

Core entities: `WareHouse`, `Product`, `WarehouseInventory`, `Customer`, `Order`, `OrderItems`, `Shipment`, `Vehicle`, `Driver`, `DeliveryAssignment`.

Seed data lives in `db/data/` as CSV files (named `DeliveryAssignment-<Entity>.csv`). `Shipment` and `DeliveryAssignment` CSVs are intentionally empty — they are created at runtime by service logic.

### Services (`srv/model_srv.cds`, `srv/model_srv.js`)

Three OData services, all projecting from the same underlying entities:

| Service | Consumers | Access |
|---|---|---|
| `adminService` | Internal/admin | Full read/write on all entities |
| `customerService` | Customer app | `getOrder`, `getOrderItems`, `getCustomer`, `getProduct` — role: `customer` |
| `driversService` | Drivers app | `getDeliveryAssignment`, `getVehicle`, `getDriver`, `getWareHouse`, `getShipment` — role: `driver` |

`driversService` applies row-level filters: drivers only see their own assignments (`driver.name = $user.id`) and their own vehicle.

### Order → Delivery Flow (`srv/model_srv.js`)

When a customer submits an order (`customerService.getOrder` AFTER CREATE):
1. The handler calls `assignDelivery(order)`.
2. It uses the Haversine formula to find the nearest warehouse with all ordered items in stock.
3. Creates a `Shipment` record.
4. Assigns an available `Vehicle` and `Driver` from that warehouse.
5. Inserts a `DeliveryAssignment` linking all of the above.

### Frontend Apps (`app/`)

Both apps are **Fiori List-Report** pattern apps (no custom controller logic — driven entirely by annotations):

- `app/customer/` — Order placement and tracking. Annotations in `app/customer/annotations.cds`.
- `app/drivers/` — Delivery assignment view for drivers. Annotations in `app/drivers/annotations.cds`.
- `app/services.cds` — Top-level file that imports both annotation files; referenced by the CAP server.

UI5 app-to-service wiring is in `app/*/webapp/manifest.json` (`dataSources` section).

### Auth (Dev Mode)

Custom middleware in `srv/server.js` reads `_user` query param or a cookie to set the current user, enabling role switching without real auth. Mock users defined in `package.json` under `cds.requires.auth.users`:

| User | Role |
|---|---|
| `a` | `admin` |
| `cust` | `customer` |
| `driv` | `driver` |

Switch user in the browser via `?_user=cust` (or `driv`, `a`). The middleware persists the choice in a cookie for the session.
