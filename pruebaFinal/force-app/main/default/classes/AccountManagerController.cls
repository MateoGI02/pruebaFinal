public with sharing class AccountManagerController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getMyAccounts() {
        return [
            SELECT Id, Name, Industry, Phone, AnnualRevenue 
            FROM Account 
            WHERE OwnerId = :UserInfo.getUserId() 
            WITH SECURITY_ENFORCED 
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        if (!Account.sObjectType.getDescribe().isDeletable()) {
            throw new AuraHandledException('No tienes permisos para eliminar Cuentas.');
        }
        try {
            delete new Account(Id = accountId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar: ' + e.getMessage());
        }
    }

    // --- NUEVOS MÉTODOS PARA LEADS Y CASOS ---

    @AuraEnabled(cacheable=true)
    public static List<Lead> getAccountLeads(Id accountId) {
        if (accountId == null) return new List<Lead>();
        // Recuerda: Account__c debe existir en tu org para enlazar Leads a Cuentas
        return [
            SELECT Id, Name, Status, Email 
            FROM Lead 
            WHERE Account__c = :accountId 
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCases(Id accountId) {
        if (accountId == null) return new List<Case>();
        return [
            SELECT Id, CaseNumber, Subject, Status 
            FROM Case 
            WHERE AccountId = :accountId 
            WITH SECURITY_ENFORCED
        ];
    }
}