using driversService as service from '../../srv/model_srv';

annotate service.getDeliveryAssignment with @(

    // ── Object Page Header ──────────────────────────────────────
    UI.HeaderInfo : {
        TypeName       : 'Delivery Assignment',
        TypeNamePlural : 'Delivery Assignments',
        Title          : {
            $Type : 'UI.DataField',
            Value : assignedDate,
            Label : 'Assigned Date'
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : deliveryStatus,
            Label : 'Delivery Status'
        }
    },

    UI.DataPoint #StatusKPI : {
        $Type       : 'UI.DataPointType',
        Value       : deliveryStatus,
        Title       : 'Delivery Status',
        Criticality : deliveryStatusCriticality
    },

    UI.HeaderFacets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'StatusHeaderFacet',
            Label  : 'Delivery Status',
            Target : '@UI.DataPoint#StatusKPI'
        }
    ],

    UI.Identification : [
        {
            $Type : 'UI.DataField',
            Label : 'Assigned Date',
            Value : assignedDate
        },
        {
            $Type : 'UI.DataField',
            Label : 'Delivery Status',
            Value : deliveryStatus
        }
    ],

    // ── Field Groups ────────────────────────────────────────────
    UI.FieldGroup #AssignmentDetails : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Assigned Date',
                Value : assignedDate
            },
            {
                $Type       : 'UI.DataField',
                Label       : 'Delivery Status',
                Value       : deliveryStatus,
                Criticality : deliveryStatusCriticality
            },
            {
                $Type : 'UI.DataField',
                Label : 'Shipment',
                Value : shipment_ID
            },
            {
                $Type : 'UI.DataField',
                Label : 'Vehicle',
                Value : vehicle_ID
            }
        ]
    },

    // ── Facets (Object Page sections) ───────────────────────────
    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'AssignmentDetailsFacet',
            Label  : 'Assignment Details',
            Target : '@UI.FieldGroup#AssignmentDetails'
        }
    ],

    // ── List Report ─────────────────────────────────────────────
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Assigned Date',
            Value : assignedDate
        },
        {
            $Type : 'UI.DataField',
            Label : 'Shipment',
            Value : shipment_ID
        },
        {
            $Type : 'UI.DataField',
            Label : 'Vehicle',
            Value : vehicle_ID
        },
        {
            $Type       : 'UI.DataField',
            Label       : 'Delivery Status',
            Value       : deliveryStatus,
            Criticality : deliveryStatusCriticality
        }
    ],

    UI.SelectionFields : [
        assignedDate,
        deliveryStatus
    ],

    UI.PresentationVariant : {
        $Type          : 'UI.PresentationVariantType',
        SortOrder      : [
            {
                $Type      : 'Common.SortOrderType',
                Property   : assignedDate,
                Descending : true
            }
        ],
        Visualizations : ['@UI.LineItem']
    }
);


annotate service.getDeliveryAssignment with @(
    Capabilities.FilterRestrictions : {
        FilterExpressionRestrictions : [
            {
                Property           : assignedDate,
                AllowedExpressions : 'SingleRange'
            }
        ]
    }
);


// ── Value-help pickers ──────────────────────────────────────────
annotate service.getDeliveryAssignment with {
    shipment @(
        Common.Text            : shipment.destinationAddress_city,
        Common.TextArrangement : #TextOnly,
        Common.ValueList       : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'getShipment',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : shipment_ID,
                    ValueListProperty : 'ID'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'destinationAddress_street'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'destinationAddress_city'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'destinationAddress_state'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'destinationAddress_zipCode'
                }
            ]
        }
    )
};

annotate service.getDeliveryAssignment with {
    driver @Common.ValueList : {
        $Type          : 'Common.ValueListType',
        CollectionPath : 'getDriver',
        Parameters     : [
            {
                $Type             : 'Common.ValueListParameterInOut',
                LocalDataProperty : driver_ID,
                ValueListProperty : 'ID'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'name'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'licenseType'
            },
            {
                $Type             : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty : 'status'
            }
        ]
    }
};

annotate service.getDeliveryAssignment with {
    vehicle @(
        Common.Text            : vehicle.number,
        Common.TextArrangement : #TextOnly,
        Common.ValueList       : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'getVehicle',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : vehicle_ID,
                    ValueListProperty : 'ID'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'number'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'type'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'maxLoadCapacity'
                }
            ]
        }
    )
};
