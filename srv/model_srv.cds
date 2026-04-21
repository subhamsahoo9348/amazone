using {DeliveryAssignment as DA} from '../db/model';


//require Admin  ;>Will add Role later

service adminService {
    entity getWareHouse          as projection on DA.WareHouse;
    entity getShipment           as projection on DA.Shipment;
    entity getOrder              as projection on DA.Order;
    entity getDeliveryAssignment as projection on DA.DeliveryAssignment;
    entity getCustomer           as projection on DA.Customer;
    entity getVehicle            as projection on DA.Vehicle;
    entity getDriver             as projection on DA.Driver;
    entity getProduct            as projection on DA.Product;
    entity getWarehouseInventory as projection on DA.WarehouseInventory;
    entity getOrderItems         as projection on DA.OrderItems;
}

//require   Custmers
service customerService @(requires: 'authenticated-user') {
    @restrict: [
        {
            grant: 'READ',
            to   : 'customer'
        },
        {
            grant: 'WRITE',
            to   : 'customer'
        }
    ]
    entity getOrder      as projection on DA.Order;

    entity getCustomer   as projection on DA.Customer;

    @restrict: [
        {
            grant: 'READ',
            to   : 'customer'
        },
        {
            grant: 'WRITE',
            to   : 'customer'
        }
    ]
    entity getProduct    as projection on DA.Product;

    @restrict: [
        {
            grant: 'READ',
            to   : 'customer'
        },
        {
            grant: 'WRITE',
            to   : 'customer'
        }
    ]
    entity getOrderItems as projection on DA.OrderItems
}


annotate customerService.getOrder with @odata.draft.enabled;


//require   Drivers

service driversService {
    entity getWareHouse          as projection on DA.WareHouse;
    entity getDeliveryAssignment as projection on DA.DeliveryAssignment;
    entity getVehicle            as projection on DA.Vehicle;
    entity getDriver             as projection on DA.Driver;
}
