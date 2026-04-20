({
    doInit : function(component, event, helper) {
        component.set('v.columns', [
            { label: 'Nombre', fieldName: 'Name', type: 'text' },
            { label: 'Descripción', fieldName: 'Description__c', type: 'text' }
        ]);
    },

    handleMessage : function(component, event, helper) {
        // Recibe los datos del LWC
        var accountId = event.getParam('accountId');
        var tipoTarjeta = event.getParam('tipoTarjeta');
        var segmentoTarjeta = event.getParam('segmentoTarjeta');

        console.log("⚡ AURA RECIBIÓ EL MENSAJE LMS -> AccountId:", accountId, " | Tipo:", tipoTarjeta, " | Segmento:", segmentoTarjeta);
        if(accountId) {
            helper.fetchBeneficios(component, accountId, tipoTarjeta, segmentoTarjeta);
            helper.fetchPromociones(component, accountId, tipoTarjeta, segmentoTarjeta);
        } else {
            // Si deseleccionan la cuenta, vaciamos las listas
            component.set("v.beneficios", []);
            component.set("v.promociones", []);
        }
    }
})