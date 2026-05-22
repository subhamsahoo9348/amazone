using customerService as service from '../../srv/model_srv';

annotate service.getOrder with @(
    Capabilities.FilterRestrictions : {
        FilterExpressionRestrictions : [
            {
                Property           : orderDate,
                AllowedExpressions : 'SingleRange'
            }
        ]
    }
);

annotate service.getOrder with {
    status @Common.ValueListWithFixedValues : true
};

annotate service.getOrder with @(

    // ── Object Page Header ──────────────────────────────────────
    UI.HeaderInfo : {
        TypeName       : 'Order',
        TypeNamePlural : 'Orders',
        Title          : {
            $Type : 'UI.DataField',
            Value : orderDate,
            Label : 'Order Date'
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : createdBy,
            Label : 'Created By'
        }
    },

    UI.DataPoint #OrderDateKPI : {
        $Type : 'UI.DataPointType',
        Value : orderDate,
        Title : 'Order Date'
    },

    UI.HeaderFacets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'OrderDateHeaderFacet',
            Label  : 'Order Date',
            Target : '@UI.DataPoint#OrderDateKPI'
        }
    ],

    UI.Identification : [
        {
            $Type : 'UI.DataField',
            Label : 'Order Date',
            Value : orderDate
        },
        {
            $Type : 'UI.DataField',
            Label : 'Created By',
            Value : createdBy
        }
    ],

    // ── Field Groups ────────────────────────────────────────────
    UI.FieldGroup #AdminData : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Created By',
                Value : createdBy
            },
            {
                $Type : 'UI.DataField',
                Label : 'Created At',
                Value : createdAt
            },
            {
                $Type : 'UI.DataField',
                Label : 'Last Modified By',
                Value : modifiedBy
            },
            {
                $Type : 'UI.DataField',
                Label : 'Last Modified At',
                Value : modifiedAt
            }
        ]
    },

    // ── Facets (Object Page sections) ───────────────────────────
    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'Items',
            Label  : 'Order Items',
            Target : 'items/@UI.LineItem#Items'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'AdminDataFacet',
            Label  : 'Administrative Data',
            Target : '@UI.FieldGroup#AdminData'
        }
    ],

    // ── List Report ─────────────────────────────────────────────
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Order Date',
            Value : orderDate
        },
        {
            $Type : 'UI.DataField',
            Label : 'Created By',
            Value : createdBy
        },
        {
            $Type       : 'UI.DataField',
            Label       : 'Status',
            Value       : status,
            Criticality : statusCriticality
        }
    ],

    UI.SelectionFields : [
        orderDate,
        createdBy,
        status
    ],

    UI.PresentationVariant : {
        $Type          : 'UI.PresentationVariantType',
        SortOrder      : [
            {
                $Type      : 'Common.SortOrderType',
                Property   : orderDate,
                Descending : true
            }
        ],
        Visualizations : ['@UI.LineItem']
    }
);


// ── Order Items ─────────────────────────────────────────────────
annotate service.getOrderItems with @(
    UI.LineItem #Items : [
        {
            $Type : 'UI.DataField',
            Label : 'Product',
            Value : product_ID
        },
        {
            $Type : 'UI.DataField',
            Label : 'Quantity',
            Value : quantity
        }
    ]
);

annotate service.getOrderItems with {
    product @(
        Common.Text                     : product.name,
        Common.TextArrangement          : #TextOnly,
        Common.ExternalID               : product.name,
        Common.ValueList                : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'getProduct',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : product_ID,
                    ValueListProperty : 'ID'
                }
            ],
            Label          : 'Select Product'
        },
        Common.ValueListWithFixedValues : false,
        Common.FieldControl             : #Mandatory
    )
};

annotate service.getOrderItems with {
    quantity @(
        Common.FieldControl : #Mandatory,
        assert.range        : [1, 9999]
    )
};
