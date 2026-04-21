using customerService as service from '../../srv/model_srv';
annotate service.getOrder with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'orderDate',
                Value : orderDate,
            },
            {
                $Type : 'UI.DataField',
                Value : modifiedBy,
            },
            {
                $Type : 'UI.DataField',
                Value : modifiedAt,
            },
            {
                $Type : 'UI.DataField',
                Value : createdBy,
            },
            {
                $Type : 'UI.DataField',
                Value : createdAt,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Items',
            ID : 'Items',
            Target : 'items/@UI.LineItem#Items',
        },
    ],
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'orderDate',
            Value : orderDate,
        },
        {
            $Type : 'UI.DataField',
            Value : ID,
            Label : 'ID',
        },
        {
            $Type : 'UI.DataField',
            Value : createdBy,
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'customerService.EntityContainer/createOrder',
            Label : 'Create Order',
        },
    ],
);

annotate service.getOrderItems with @(
    UI.LineItem #Items : [
        {
            $Type : 'UI.DataField',
            Value : product_ID,
            Label : 'product_ID',
        },
        {
            $Type : 'UI.DataField',
            Value : quantity,
            Label : 'quantity',
        },
    ]
);

annotate service.getOrderItems with {
    product @(
        Common.ExternalID : product.name,
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'getProduct',
            Parameters : [
                {
                    $Type : 'Common.ValueListParameterInOut',
                    LocalDataProperty : product_ID,
                    ValueListProperty : 'ID',
                },
            ],
            Label : 'Select Product',
        },
        Common.ValueListWithFixedValues : false,
    )
};

