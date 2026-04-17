public with sharing class GeneradorContratoController {
    
    @AuraEnabled
    public static String generarYGuardarContrato(Id recordId) {
        try {
            // 1. Instanciar la página Visualforce con el ID de la Oportunidad
            PageReference pdfPage = Page.ContratoTemplate;
            pdfPage.getParameters().put('id', recordId);
            
            // 2. Generar el Blob del PDF (Simulado en Test porque getContentAsPDF no funciona en pruebas unitarias)
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('PDF de prueba');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            if (!Schema.sObjectType.ContentVersion.isCreateable()) {
                throw new AuraHandledException('Tu perfil no tiene permisos para crear documentos.');
            }
            // 3. Crear el ContentVersion (Almacenamiento físico del archivo)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Contrato_Generado_' + recordId;
            cv.PathOnClient = 'Contrato_' + recordId + '.pdf';
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = recordId; // Esto crea automáticamente el ContentDocumentLink hacia la Oportunidad
            insert cv;
            
            if (!Schema.sObjectType.ContentVersion.isAccessible()) {
                throw new AuraHandledException('Tu perfil no tiene permisos para leer documentos.');
            }
            // 4. Obtener el ContentDocumentId generado para enviarlo al LWC
            ContentVersion cvInsertado = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            
            return cvInsertado.ContentDocumentId;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error al generar el contrato: ' + e.getMessage());
        }
    }

    // NUEVO MÉTODO: Verifica si ya existe un contrato generado previamente
    @AuraEnabled(cacheable=true)
    public static Boolean verificarContratoExistente(Id recordId) {
        Integer conteoArchivos = [SELECT COUNT() 
                                  FROM ContentDocumentLink 
                                  WHERE LinkedEntityId = :recordId 
                                  AND ContentDocument.Title LIKE 'Contrato_Generado_%'
                                  WITH SECURITY_ENFORCED];
        return conteoArchivos > 0;
    }
}