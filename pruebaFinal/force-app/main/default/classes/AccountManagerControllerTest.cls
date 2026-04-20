@isTest
private class AccountManagerControllerTest {

    @testSetup
    static void setupTestData() {
        // 1. Crear Cuenta (¡Ahora con todos los campos obligatorios!)
        Account acc = new Account(
            Name = 'Cuenta Test12', 
            Industry = 'Banking', 
            Phone = '123456789',
            Active__c = 'Yes', 
            Email__c = 'test@example.com',
            Fecha_de_nacimiento__c = Date.newInstance(1990, 1, 1),
            Situacion_Laboral__c = 'Dependiente', 
            Tipo_de_Documento__c = 'DNI',       
            Numero_de_Documento__c = 12345678
        );
        insert acc;

        // 2. Crear Producto para la Cuenta Financiera
        Product2 prod = new Product2(
            Name = 'Tarjeta Test', 
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Oro',
            Linea_de_Credito_Maxima__c = 5000,
            Tasa_de_Interes__c = 10

        );
        insert prod;

        // 3. Crear registros relacionados
        Lead ld = new Lead(
            LastName = 'Lead Test', 
            Company = 'Empresa Lead', 
            Account__c = acc.Id, 
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Oro',
            Ingreso_Mensual__c = 5000,
            Situacion_Laboral__c = 'Dependiente',
            Linea_de_Credito_Solicitada__c = 5000,
            Fecha_de_nacimiento__c = Date.newInstance(1990, 1, 1)
        );
        insert ld;

        Case cs = new Case(
            AccountId = '001aj00002WfnHRAAZ', 
            Subject = 'Caso Test', 
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Clásica'
        );
        insert cs;

        Opportunity opp = new Opportunity(
            Name = 'Opp Test', 
            AccountId = acc.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today().addDays(10),
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Oro'
        );
        insert opp;

        FinancialAccount__c fa = new FinancialAccount__c(
            Name = 'Cuenta Financiera Test', 
            Account__c = acc.Id, 
            Product__c = prod.Id
        );
        insert fa;

        // 4. Crear Beneficios y Promociones (Catálogo general)
        Benefit__c ben = new Benefit__c(
            Category__c = 'Beneficio',
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Oro'
        );
        insert ben;

        Benefit__c prom = new Benefit__c(
            Category__c = 'Promoción',
            Tipo_de_Tarjeta__c = 'Visa', 
            Segmento_de_Tarjeta__c = 'Oro'
        );
        insert prom;
    }

    // ==========================================
    // ESCENARIOS: HAPPY PATH
    // ==========================================

    @isTest
    static void testGetMyAccounts() {
        Test.startTest();
        List<Account> accounts = AccountManagerController.getMyAccounts();
        Test.stopTest();

        Assert.isTrue(accounts.size() > 0, 'Debe retornar al menos una cuenta.');
        Assert.areEqual('Cuenta Test', accounts[0].Name, 'El nombre de la cuenta debe coincidir.');
    }

    @isTest
    static void noFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Lead> leads = AccountManagerController.getAccountLeads(acc.Id, null, null);
        List<Case> cases = AccountManagerController.getAccountCases(acc.Id, null, null);
        List<sObject> finAccs = AccountManagerController.getAccountFinancialAccounts(acc.Id, null, null);
        Test.stopTest();

        Assert.areEqual(1, leads.size(), 'Debe retornar 1 Lead relacionado.');
        Assert.areEqual(1, cases.size(), 'Debe retornar 1 Caso relacionado.');
        Assert.areEqual(1, finAccs.size(), 'Debe retornar 1 Cuenta Financiera.');
    }

    @isTest
    static void withFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // Filtros exactos basados en el @testSetup
        List<Opportunity> opps = AccountManagerController.getAccountOpportunities(acc.Id, 'Credito', 'Premium');
        List<sObject> beneficios = AccountManagerController.getAccountBeneficios(acc.Id, 'Credito', 'Premium');
        List<sObject> promociones = AccountManagerController.getAccountPromociones(acc.Id, 'Credito', 'Premium');
        Test.stopTest();

        Assert.areEqual(1, opps.size(), 'Debe retornar la Oportunidad que coincide con los filtros.');
        Assert.areEqual(1, beneficios.size(), 'Debe retornar 1 Beneficio.');
        Assert.areEqual(1, promociones.size(), 'Debe retornar 1 Promoción.');
    }

    @isTest
    static void delete_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        AccountManagerController.deleteAccount(acc.Id);
        Test.stopTest();

        List<Account> deletedAccs = [SELECT Id FROM Account WHERE Id = :acc.Id];
        Assert.isTrue(deletedAccs.isEmpty(), 'La cuenta debió ser eliminada de la base de datos.');
    }

    // ==========================================
    // ESCENARIOS: NEGATIVE PATH
    // ==========================================

    @isTest
    static void nullAccountId() {
        Test.startTest();
        // Pasamos null como AccountId, el código debería atajarlo y retornar lista vacía
        List<Lead> leads = AccountManagerController.getAccountLeads(null, 'Credito', 'Premium');
        List<sObject> beneficios = AccountManagerController.getAccountBeneficios(null, null, null);
        Test.stopTest();

        Assert.isTrue(leads.isEmpty(), 'Debe retornar lista vacía si el Id de la cuenta es null.');
        Assert.isTrue(beneficios.isEmpty(), 'Debe retornar lista vacía si el Id de la cuenta es null.');
    }

    @isTest
    static void test_Exception() {
        // Obtenemos un Id falso (usamos el Id de un Lead para forzar el fallo al intentar borrarlo como Account)
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        try {
            AccountManagerController.deleteAccount(ld.Id);
            Assert.fail('Se esperaba que arrojara una AuraHandledException.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'La excepción debe ser manejada para Aura/LWC.');
        }
        Test.stopTest();
    }

    // ==========================================
    // ESCENARIOS: BOUNDARY / EDGE CASES
    // ==========================================

    @isTest
    static void partialFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // Solo enviamos Tipo de Tarjeta, Segmento es nulo
        List<Case> cases = AccountManagerController.getAccountCases(acc.Id, 'Credito', null);
        Test.stopTest();

        Assert.areEqual(1, cases.size(), 'Debe funcionar correctamente con filtros parciales.');
    }

    @isTest
    static void noMatchingFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // Filtros que no existen en la data de prueba
        List<Opportunity> opps = AccountManagerController.getAccountOpportunities(acc.Id, 'Debito', 'Clasico');
        Test.stopTest();

        Assert.isTrue(opps.isEmpty(), 'Debe retornar lista vacía si los filtros no coinciden con la data.');
    }
}