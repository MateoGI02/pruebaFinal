({
    fetchBeneficios : function(component, accId, tipo, segmento) {
        var action = component.get("c.getAccountBeneficios");
        action.setParams({
            "accountId": accId,
            "tipoTarjeta": tipo || '',
            "segmentoTarjeta": segmento || ''
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                console.log("✅ Beneficios obtenidos de Apex: ", data);
                component.set("v.beneficios", data);
            } else {
                console.error("❌ Error en Beneficios: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    fetchPromociones : function(component, accId, tipo, segmento) {
        var action = component.get("c.getAccountPromociones");
        action.setParams({
            "accountId": accId,
            "tipoTarjeta": tipo || '',
            "segmentoTarjeta": segmento || ''
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                console.log("✅ Promociones obtenidas de Apex: ", data);
                component.set("v.promociones", data);
            } else {
                console.error("❌ Error en Promociones: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})