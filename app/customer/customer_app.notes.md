# Customer App — File Map & Notes

Location: `app/customer/`
Type: **SAP Fiori Elements** (List Report + Object Page template, OData V4).
Backend: `customerService` defined in `srv/model_srv.cds`.

---

## High-level purpose

A draft-enabled UI for the **customer-facing order workflow**. A logged-in
customer (mock user `cust`) can:

1. See a list of their orders.
2. Create a new order (header + line items, with product picker).
3. Save the order — which triggers `model_srv.js` → `createShipment`
   → `assignDelivery` on the backend.

The UI is **fully generated** from CDS UI annotations — there are no
hand-written views or controllers in this app.

---

## File tree

```
app/
├── services.cds                            ── pulls in customer annotations
└── customer/
    ├── package.json                         ── UI5 tooling devDeps (not runtime)
    ├── ui5.yaml                             ── UI5 server middleware (proxy, reload, preview)
    ├── annotations.cds                      ── ★ all UI shape lives here
    ├── README.md                            ── (generator stub)
    ├── eslint.config.mjs
    └── webapp/
        ├── manifest.json                    ── ★ Fiori Elements app descriptor + routes
        ├── index.html                       ── UI5 bootstrap, mounts the Component
        ├── Component.js                     ── thin extension of sap.fe.core.AppComponent
        ├── i18n/i18n.properties             ── appTitle / appDescription strings
        └── test/                            ── OPA5 integration tests (generated)
```

★ = the two files you actually edit when changing UI behavior.

---

## How it boots

```
index.html
  └─ loads UI5 from sapui5.hana.ondemand.com (v1.147.0, sap_horizon theme)
  └─ <div data-sap-ui-component data-name="customer" ...>
       └─ webapp/Component.js
            └─ extends sap/fe/core/AppComponent
            └─ reads manifest.json
                 ├─ dataSource.mainService → /odata/v4/customer/
                 ├─ routes:
                 │    ├─ ""                 → ListReport  (getOrderList)
                 │    └─ "getOrder({key})"  → ObjectPage  (getOrderObjectPage)
                 └─ both targets bound to /getOrder
```

The browser URL `/customer/webapp/index.html` ends up showing the List Report.

---

## OData wiring

| Concept              | Where it points |
| -------------------- | --------------- |
| Service URI          | `/odata/v4/customer/` (manifest → `dataSources.mainService.uri`) |
| Service definition   | `customerService` in `srv/model_srv.cds` |
| Primary entity       | `customerService.getOrder` (projection on `db/model.cds` → `Order`) |
| Child collection     | `customerService.getOrderItems` (composition on `Order.items`) |
| Drafts               | Enabled via `annotate customerService.getOrder with @odata.draft.enabled;` (in `srv/model_srv.cds`) — this is what enables the "Create / Edit / Save / Discard" draft buttons. |
| Backend trigger      | After CREATE/UPDATE of `getOrder`, `srv/model_srv.js` line 19 calls `createShipment(...)` |

---

## What `annotations.cds` declares

(Lives at `app/customer/annotations.cds`, included via `app/services.cds`.)

| Annotation | What it controls |
| --- | --- |
| `@UI.FieldGroup#GeneratedGroup` on `getOrder` | The "General Information" section on the Object Page: `orderDate`, `modifiedBy/At`, `createdBy/At`. |
| `@UI.Facets` on `getOrder` | Object Page sections: "General Information" + "Items". |
| `@UI.LineItem` on `getOrder` | Columns of the **List Report** table: `orderDate`, `ID`, `createdBy`, and a **Create Order** button (`DataFieldForAction → customerService.EntityContainer/createOrder` — the auto-generated draft create action). |
| `@UI.LineItem#Items` on `getOrderItems` | Columns of the **Items** table inside the Object Page: `product_ID`, `quantity`. |
| `Common.ValueList` on `getOrderItems.product` | Turns the `product_ID` cell into a **product picker dropdown** sourced from `getProduct`. |
| `Common.FieldControl: #Mandatory` on `product` and `quantity` | Both fields required on save. |

What's **not** annotated and therefore not visible in the UI:
- The `customer` association on Order (the backend resolves it from `req.user`).
- The `ID` on `OrderItems`.

---

## Routes

From `manifest.json` → `sap.ui5.routing.routes`:

| Pattern | Target | Template |
| --- | --- | --- |
| `""` (root) | `getOrderList` | `sap.fe.templates.ListReport` |
| `getOrder({key}):?query:` | `getOrderObjectPage` | `sap.fe.templates.ObjectPage` |

Both targets resolve `contextPath: /getOrder` against the OData service.

---

## How auth flows in

1. Browser hits `/customer/webapp/index.html` (or the root if launched via `cds watch --open customer/index.html`).
2. UI5 makes its first OData call to `/odata/v4/customer/$metadata`.
3. CDS' mocked-auth middleware (configured in **root** `package.json`) challenges with Basic Auth.
4. User enters `cust` / *(empty password)* — defined as a `customer`-role user.
5. Every subsequent OData call carries `req.user.id = "cust"`.
6. On order CREATE/UPDATE, `model_srv.js:25` runs
   `SELECT.one(getCustomer).where({ name: user.id })` and finds the customer
   row whose `name` field equals `"cust"` (just added to
   `db/data/DeliveryAssignment-Customer.csv`).

---

## Where to make changes

| If you want to… | Edit |
| --- | --- |
| Add/remove columns in the order list | `app/customer/annotations.cds` → `UI.LineItem` block |
| Change the Object Page layout | same file → `UI.Facets` + `UI.FieldGroup` |
| Expose a new field (e.g. order total) | annotate it in `annotations.cds` AND make sure the projection in `srv/model_srv.cds` exposes the underlying field |
| Change the product picker behavior | same file → `Common.ValueList` on `getOrderItems.product` |
| Change routing / page templates | `webapp/manifest.json` → `sap.ui5.routing` |
| Change app title | `webapp/i18n/i18n.properties` (`appTitle`, `appDescription`) |
| Change UI5 version / theme | `webapp/index.html` (CDN URL + `data-sap-ui-theme`) |

You should **never** need to hand-write views (`.xml`) or controllers
(`.controller.js`) for this app — Fiori Elements generates them from the
annotations + manifest at runtime.

---

## How to launch

From repo root:

```bash
npm run watch-customer
```

This is defined in the **root** `package.json` as:
```
cds watch --open customer/index.html?sap-ui-xx-viewCache=false --livereload false
```

It starts the CAP server, opens the customer app in the default browser,
and disables UI5's view cache so annotation edits show up immediately.

Plain `npm start` runs the server without auto-opening the UI.

---

## Known smells / things to revisit

- **`createOrder` action**: `annotations.cds:60` references
  `customerService.EntityContainer/createOrder`. This is the auto-generated
  draft-create action that exists because of `@odata.draft.enabled` — if you
  ever remove draft mode, this button breaks.
- **No filter bar configured** on the List Report — every order is shown.
  Add `@UI.SelectionFields` if you want filtering.
- **Customer isn't auto-bound on order create**. The `Order.customer`
  association is left null in the UI; the backend doesn't currently set it
  from `req.user` either. The `createShipment` hook resolves the customer
  via `req.user.id` instead, but the `Order` row itself remains
  `customer_ID = null`. If you want orders queryable by customer later,
  wire that up.
- **No `customer` role grants** on `getCustomer` / `getOrderItems` — they
  rely on the projection-level `@restrict` already in `model_srv.cds`.
  Cross-check if you change auth rules.
- **`app/services.cds`** is only `using from './customer/annotations';` —
  if you add another Fiori app, add its annotations include here.
- **`Component.js`** is a 12-line stub. Don't put logic in it; in Fiori
  Elements, custom behavior goes through manifest extensions, not Component.

---

## Where to resume next

If you want to make the order list actually useful per-customer:

1. **In `srv/model_srv.js`**, in the `this.before("CREATE", custGetOrder, ...)` hook
   (you'll need to add one), set `req.data.customer_ID` from the Customer
   row resolved by `req.user.id`.
2. **In `annotations.cds`**, add `@UI.SelectionFields` so the customer can
   filter their order history.
3. Confirm `customerService.getOrder` is restricted so customers only see
   their own orders (currently the `@restrict` grants READ to anyone with
   role `customer`, with no row-level filter).
