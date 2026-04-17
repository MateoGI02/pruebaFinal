public class EnvioContratoService {

    @InvocableMethod(label='Enviar Contrato al Cliente' description='Envía el correo con el PDF adjunto usando el Email de la Cuenta')
    public static void enviarContratoInvocable(List<Id> oppIds) {
        System.enqueueJob(new CorreoContratoQueueable(oppIds));
    }

    public class CorreoContratoQueueable implements Queueable {
        private List<Id> oppIds;

        public CorreoContratoQueueable(List<Id> oppIds) {
            this.oppIds = oppIds;
        }

        public void execute(QueueableContext context) {
            List<Messaging.SingleEmailMessage> correosAEnviar = new List<Messaging.SingleEmailMessage>();
            
            // 1. Buscamos la plantilla Classic por su DeveloperName
            EmailTemplate plantilla = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plantilla_Contrato_Aprobado' LIMIT 1];

            // 2. Buscamos las Oportunidades y los datos de la Cuenta
            List<Opportunity> oportunidades = [
                SELECT Id, AccountId, Account.Email__c, Account.Name
                FROM Opportunity 
                WHERE Id IN :oppIds
            ];

            // Delegamos la lógica de mapeo a métodos auxiliares para pasar la validación de PMD
            Map<Id, Id> mapCuentaContacto = obtenerMapaContactos(oportunidades);
            Map<Id, Id> mapaOppArchivo = obtenerMapaArchivos(oppIds);

            // 6. Construimos los correos
            for(Opportunity opp : oportunidades) {
                // Si la cuenta no tiene correo electrónico, saltamos a la siguiente
                if(String.isBlank(opp.Account.Email__c)) {
                    System.debug('Aviso: No se pudo enviar el contrato a la Oportunidad ' + opp.Id + ' porque la Cuenta no tiene un correo registrado.');
                    continue;
                }

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(plantilla.Id);
                email.setWhatId(opp.Id); // Permite que {!Opportunity.Campo} funcione
                
                // Definimos el destino real
                email.setToAddresses(new String[] { opp.Account.Email__c });

                // Asignamos el Contacto puente
                Id contactId = mapCuentaContacto.get(opp.AccountId);
                
                if(contactId != null){
                    email.setTargetObjectId(contactId);
                    // IMPORTANTE: Evita que el correo se envíe a la dirección del Contacto
                    email.setTreatTargetObjectAsRecipient(false); 
                } else {
                    // Si no hay ningún contacto en la cuenta, la plantilla fallará.
                    System.debug('Error: La cuenta ' + opp.Account.Name + ' no tiene contactos relacionados.');
                    continue; 
                }

                // Adjuntamos el PDF
                if(mapaOppArchivo.containsKey(opp.Id)) {
                    email.setEntityAttachments(new List<Id>{ mapaOppArchivo.get(opp.Id) });
                }

                correosAEnviar.add(email);
            }

            // 7. Enviar todos los correos en un solo bloque
            if(!correosAEnviar.isEmpty()) {
                Messaging.sendEmail(correosAEnviar, false);
            }
        }

        // --- MÉTODOS AUXILIARES ---
        
        // 3 y 4. Extraemos los IDs de Cuentas y buscamos al menos un Contacto por Cuenta
        private Map<Id, Id> obtenerMapaContactos(List<Opportunity> oportunidades) {
            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp : oportunidades) {
                if(opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }

            Map<Id, Id> mapCuentaContacto = new Map<Id, Id>();
            List<Contact> contactos = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds];
            for(Contact c : contactos) {
                // Guardamos el primer contacto que encontremos para cada cuenta
                if(!mapCuentaContacto.containsKey(c.AccountId)) {
                    mapCuentaContacto.put(c.AccountId, c.Id);
                }
            }
            return mapCuentaContacto;
        }

        // 5. Buscamos los PDFs adjuntos a las oportunidades
        private Map<Id, Id> obtenerMapaArchivos(List<Id> idsOportunidades) {
            Map<Id, Id> mapaOppArchivo = new Map<Id, Id>();
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :idsOportunidades 
                AND ContentDocument.Title LIKE 'Contrato_Generado%' 
            ];
            
            for(ContentDocumentLink link : links) {
                mapaOppArchivo.put(link.LinkedEntityId, link.ContentDocument.LatestPublishedVersionId);
            }
            return mapaOppArchivo;
        }
    }
}