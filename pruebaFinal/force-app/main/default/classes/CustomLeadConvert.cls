public with sharing class CustomLeadConvert {
    
    // ¡Aquí está la solución! Declaramos la excepción personalizada.
    public class CustomLeadConvertException extends Exception {}
    
    @InvocableMethod(label='Convertir Lead desde Flow' description='Ejecuta la conversión nativa de un Lead en Salesforce')
    public static void convertLeadAction(List<ConvertRequest> requests) {
        
        // 1. Buscamos el estado estándar de conversión configurado en la org
        LeadStatus convertStatus;
        if (Schema.sObjectType.LeadStatus.isAccessible()) {
            convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        } else {
            // Ahora esto funcionará perfectamente
            throw new CustomLeadConvertException('No access to LeadStatus object');
        }
        
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        
        // 2. Preparamos los registros para conversión
        for(ConvertRequest req : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setAccountId(req.accountId);
            lc.setOpportunityId(req.oppId); // Vinculamos la Opp creada en el Flow
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            leadsToConvert.add(lc);
        }
        
        // 3. Ejecutamos la acción DML
        if(!leadsToConvert.isEmpty()) {
            Database.convertLead(leadsToConvert);
        }
    }
    
    // Wrapper class para recibir múltiples variables desde el Flow
    public class ConvertRequest {
        @InvocableVariable(required=true label='ID del Lead' description='recordId del flujo') 
        public Id leadId;
        
        @InvocableVariable(required=true label='ID de la Cuenta' description='Account__c del Lead') 
        public Id accountId;
        
        @InvocableVariable(required=true label='ID de la Oportunidad' description='La oportunidad recién creada') 
        public Id oppId;
    }
}