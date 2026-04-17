public class BenefitTriggerHandler {
    
    public void run() {
        /*
        // --- CONTEXTOS BEFORE --- 
        if (Trigger.isBefore) {
            
            if (Trigger.isInsert) {
                //Validaciones before insert
            } else if (Trigger.isUpdate) {
                // Validaciones before update
            } else if (Trigger.isDelete) {
                // Validaciones before delete
            }
        }*/
        
        // --- CONTEXTOS AFTER --- 
        if (Trigger.isAfter) {
            if (Trigger.isInsert || Trigger.isUndelete) {
                BenefitService.updateProductSummaries(Trigger.new);
                
            } else if (Trigger.isUpdate) {
                // Manda los nuevos para actualizar los productos
                BenefitService.updateProductSummaries(Trigger.new);
                // Manda los viejos por si le cambiaron el Segmento a un beneficio y hay que limpiar el producto anterior
                BenefitService.updateProductSummaries(Trigger.old);
                
            } else if (Trigger.isDelete) {
                // Si se borra un beneficio, actualiza el producto para que ya no lo muestre
                BenefitService.updateProductSummaries(Trigger.old);
            }
        }
    }
}