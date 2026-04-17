@RestResource(urlMapping='/v1/clientes/*/oportunidades-ganadas')
global with sharing class NovaBankOportunidadesAPI {

    @HttpGet
    global static void getOportunidadesGanadas() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            // 1. Extraer el clienteId de la URL
            // La URL es: /v1/clientes/{clienteId}/oportunidades-ganadas
            String urlPath = req.requestURI;
            String clienteId = urlPath.substringBetween('clientes/', '/oportunidades-ganadas');

            if (String.isBlank(clienteId)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error": "El parámetro clienteId es obligatorio"}');
                return;
            }

            // 2. Buscar la Cuenta y sus Oportunidades Cerradas Ganadas.
            // NOTA: Usando AccountNumber como identificador del cliente.
            // Si tienes un campo personalizado Identificacion__c, cámbialo aquí.
            
            // Verificar permisos de lectura de objetos y campos antes de ejecutar la consulta
            if (!Schema.sObjectType.Account.isAccessible() || 
                !Schema.sObjectType.Opportunity.isAccessible()) {
                res.statusCode = 403;
                res.responseBody = Blob.valueOf('{"error": "Permisos insuficientes para acceder a los datos"}');
                return;
            }
            
            // Verificar permisos de campo (FLS) para Account
            if (!Schema.sObjectType.Account.fields.Id.isAccessible() ||
                !Schema.sObjectType.Account.fields.Name.isAccessible() ||
                !Schema.sObjectType.Account.fields.AccountNumber.isAccessible()) {
                res.statusCode = 403;
                res.responseBody = Blob.valueOf('{"error": "Permisos insuficientes para acceder a los campos de la cuenta"}');
                return;
            }
            
            // Verificar permisos de campo (FLS) para Opportunity
            if (!Schema.sObjectType.Opportunity.fields.Id.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.Name.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.Amount.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.CloseDate.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.LeadSource.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.StageName.isAccessible() ||
                !Schema.sObjectType.Opportunity.fields.OwnerId.isAccessible()) {
                res.statusCode = 403;
                res.responseBody = Blob.valueOf('{"error": "Permisos insuficientes para acceder a los campos de oportunidades"}');
                return;
            }
            
            List<Account> cuentas = [
                SELECT Id, Name, AccountNumber,
                    (SELECT Id, Name, Amount, CloseDate, LeadSource, Owner.Name 
                    FROM Opportunities 
                    WHERE StageName = 'Closed Won')
                FROM Account 
                WHERE AccountNumber = :clienteId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Aplicar seguridad a nivel de campo (FLS)
            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.READABLE, 
                cuentas
            );
            cuentas = securityDecision.getRecords();

            // 3. Validar si el cliente existe
            if (cuentas.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('{"error": "Cliente no encontrado"}');
                return;
            }

            Account cliente = cuentas[0];

            // 4. Construir la respuesta usando los Wrappers
            ResponseWrapper respuesta = new ResponseWrapper();
            respuesta.clienteId = cliente.AccountNumber;
            respuesta.nombreCliente = cliente.Name;
            respuesta.oportunidadesGanadas = new List<OportunidadWrapper>();
            
            for (Opportunity opp : cliente.Opportunities) {
                OportunidadWrapper oppWrapper = new OportunidadWrapper();
                oppWrapper.oportunidadId = opp.Id;
                oppWrapper.producto = opp.Name; // O el campo personalizado Producto__c si lo tienes
                oppWrapper.montoAprobado = opp.Amount != null ? opp.Amount : 0.0;
                // Los siguientes campos personalizados no existen en tu org.
                // Si necesitas estos campos, créalos primero en Account/Opportunity
                oppWrapper.lineaCredito = 0.0; // Campo personalizado Linea_Credito__c no disponible
                oppWrapper.tasaInteres = 0.0;  // Campo personalizado Tasa_Interes__c no disponible
                
                // Formatear la fecha como string (YYYY-MM-DD)
                oppWrapper.fechaCierre = String.valueOf(opp.CloseDate); 
                oppWrapper.canalOrigen = opp.LeadSource;
                oppWrapper.ejecutivo = opp.Owner.Name;
                
                respuesta.oportunidadesGanadas.add(oppWrapper);
            }
            
            respuesta.totalOportunidades = respuesta.oportunidadesGanadas.size();

            // 5. Enviar la respuesta exitosa
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(respuesta));

        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "Error interno del servidor: ' + e.getMessage() + '"}');
        }
    }

    // --- CLASES WRAPPER PARA FORMATEAR EL JSON EXACTAMENTE COMO SE PIDIÓ ---

    global class ResponseWrapper {
        public String clienteId;
        public String nombreCliente;
        public List<OportunidadWrapper> oportunidadesGanadas;
        public Integer totalOportunidades;
    }

    global class OportunidadWrapper {
        public String oportunidadId;
        public String producto;
        public Decimal montoAprobado;
        public Decimal lineaCredito;
        public Decimal tasaInteres;
        public String fechaCierre;
        public String canalOrigen;
        public String ejecutivo;
    }
}