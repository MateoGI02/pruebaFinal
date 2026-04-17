trigger BenefitTrigger on Benefit__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    // Instancia el Handler
    BenefitTriggerHandler handler = new BenefitTriggerHandler();
    
    // Ejecuta el ruteador de contextos
    handler.run();
}