sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"drivers/test/integration/pages/getDeliveryAssignmentList",
	"drivers/test/integration/pages/getDeliveryAssignmentObjectPage"
], function (JourneyRunner, getDeliveryAssignmentList, getDeliveryAssignmentObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('drivers') + '/test/flp.html#app-preview',
        pages: {
			onThegetDeliveryAssignmentList: getDeliveryAssignmentList,
			onThegetDeliveryAssignmentObjectPage: getDeliveryAssignmentObjectPage
        },
        async: true
    });

    return runner;
});

