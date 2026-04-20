sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"customer/test/integration/pages/getOrderList",
	"customer/test/integration/pages/getOrderObjectPage"
], function (JourneyRunner, getOrderList, getOrderObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('customer') + '/test/flp.html#app-preview',
        pages: {
			onThegetOrderList: getOrderList,
			onThegetOrderObjectPage: getOrderObjectPage
        },
        async: true
    });

    return runner;
});

