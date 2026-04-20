public with sharing class AccountManagerController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getMyAccounts() {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('No tienes permisos para leer Cuentas.');
        }
        return [
            SELECT Id, Name, Industry, Phone, AnnualRevenue 
            FROM Account 
            //WHERE OwnerId = :UserInfo.getUserId() 
            WITH SECURITY_ENFORCED 
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        if (!Schema.sObjectType.Account.isDeletable()) {
            throw new AuraHandledException('No tienes permisos para eliminar Cuentas.');
        }
        try {
            delete new Account(Id = accountId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar: ' + e.getMessage());
        }
    }

    // --- MÉTODOS CON FILTROS DINÁMICOS ---

    @AuraEnabled(cacheable=true)
    public static List<Lead> getAccountLeads(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<Lead>(); }
        String query = 'SELECT Id, Name, Status, Email FROM Lead WHERE Account__c = :accountId';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCases(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<Case>(); }
        String query = 'SELECT Id, CaseNumber, Subject, Status FROM Case WHERE AccountId = :accountId';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getAccountOpportunities(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<Opportunity>(); }
        String query = 'SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE AccountId = :accountId';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getAccountFinancialAccounts(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<sObject>(); }
        // Usando campos reales y relación Product__r hacia Product2
        String query = 'SELECT Id, Name, Estado__c, Linea_Actual__c FROM FinancialAccount__c WHERE Account__c = :accountId';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Product__r.Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Product__r.Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getAccountBeneficios(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<sObject>(); }
        // Sin Account__c, filtrando solo por catálogo general
        String query = 'SELECT Id, Name, Description__c FROM Benefit__c WHERE Category__c = \'Beneficio\'';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getAccountPromociones(Id accountId, String tipoTarjeta, String segmentoTarjeta) {
        if (accountId == null) { return new List<sObject>(); }
        // Sin Account__c, filtrando solo por catálogo general
        String query = 'SELECT Id, Name, Description__c FROM Benefit__c WHERE Category__c = \'Promoción\'';
        if (String.isNotBlank(tipoTarjeta)) { query += ' AND Tipo_de_Tarjeta__c = :tipoTarjeta'; }
        if (String.isNotBlank(segmentoTarjeta)) { query += ' AND Segmento_de_Tarjeta__c = :segmentoTarjeta'; }
        query += ' WITH SECURITY_ENFORCED';
        return Database.query(query);
    }
}