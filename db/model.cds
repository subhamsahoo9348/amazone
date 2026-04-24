using {
    cuid,
    managed
} from '@sap/cds/common';

namespace DeliveryAssignment;


entity WareHouse : cuid {
    name     : String(100);
    address  : {
        street    : String(100);
        city      : String(100);
        state     : String(100);
        zipCode   : String(20);
        latitude  : Decimal(9, 6);
        longitude : Decimal(9, 6);
    };
    capacity : Integer;
    vehicles : Association to many Vehicle
                   on vehicles.assignWareHouse = $self;
}

entity Product : cuid {
    name     : String(100);
    weight   : Integer;
    category : String(100);
}

entity WarehouseInventory : cuid {
    warehouse         : Association to WareHouse;
    product           : Association to Product;
    quantityAvailable : Integer;
}

entity Vehicle : cuid {
    number          : String(100);
    type            : String enum {
        Van = 'V';
        Truck = 'T';
        Bike = 'B';
    };
    maxLoadCapacity : Integer;
    assignWareHouse : Association to WareHouse;
}

entity Driver : cuid {
    name            : String(100);
    licenseType     : String(100);
    assignedVehicle : Association to Vehicle;
    status          : String enum {
        Available = 'A';
        Busy = 'B'
    };
}

entity Customer : cuid {
    name        : String(100);
    contactInfo : String(100);
    address     : {
        street    : String(100);
        city      : String(100);
        state     : String(100);
        zipCode   : String(20);
        latitude  : Decimal(9, 6);
        longitude : Decimal(9, 6);
    };
    orders      : Association to many Order
                      on orders.customer = $self;
}

entity Shipment : cuid, managed {
    sourceWarehouse    : Association to WareHouse;
    product            : Association to Product;
    destinationAddress : {
        street    : String(100);
        city      : String(100);
        state     : String(100);
        zipCode   : String(20);
        latitude  : Decimal(9, 6);
        longitude : Decimal(9, 6);
    };
    weight             : Integer;
    priority           : String enum {
        High = 'H';

        Medium = 'M';
        Low = 'L';
    } default 'L';
    status             : String enum {
        Pending = 'P';
        Assigned = 'A';
        Delivered = 'D';
    } default 'P';
}

entity DeliveryAssignment : cuid {
    shipment       : Association to Shipment;
    driver         : Association to Driver;
    vehicle        : Association to Vehicle;
    assignedDate   : Date;
    deliveryStatus : String(100);
}


entity Order : cuid, managed {
    customer  : Association to Customer;
    items     : Composition of many OrderItems
                    on items.order = $self;
    orderDate : Date;
}

entity OrderItems : cuid {
    order    : Association to Order;
    product  : Association to one Product;
    quantity : Integer;
}
