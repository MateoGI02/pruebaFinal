public with sharing class BenefitService {
    
    // Método estático para actualizar los textos resumen en Product2
    public static void updateProductSummaries(List<Benefit__c> benefits) {
        
        // Validar permisos CRUD
        if (!Schema.sObjectType.Product2.isAccessible() || !Schema.sObjectType.Benefit__c.isAccessible()) {
            return;
        }
        if (!Schema.sObjectType.Product2.isUpdateable()) {
            return;
        }
        
        // 1. Recolectar las Marcas y Segmentos de los beneficios que dispararon el trigger
        Map<String, Set<String>> tiposYSegmentos = collectTiposAndSegmentos(benefits);
        Set<String> tipos = tiposYSegmentos.get('tipos');
        Set<String> segmentos = tiposYSegmentos.get('segmentos');
        
        if (tipos.isEmpty() || segmentos.isEmpty()) {
            return;
        }
        
        // 2. Traer los productos que coinciden con esos grupos
        List<Product2> productsToUpdate = [
            SELECT Id, Tipo_de_Tarjeta__c, Segmento_de_Tarjeta__c 
            FROM Product2 
            WHERE Tipo_de_Tarjeta__c IN :tipos AND Segmento_de_Tarjeta__c IN :segmentos
        ];
        
        if (productsToUpdate.isEmpty()) {
            return;
        }
        
        // 3. Traer TODOS los beneficios activos para esos grupos para reconstruir el texto
        List<Benefit__c> activeBenefits = [
            SELECT Name, Description__c, Category__c, Tipo_de_Tarjeta__c, Segmento_de_Tarjeta__c 
            FROM Benefit__c 
            WHERE Status__c = 'Active'
            AND Tipo_de_Tarjeta__c IN :tipos 
            AND Segmento_de_Tarjeta__c IN :segmentos
        ];
        
        // 4. Agrupar beneficios por clave (Tipo + Segmento)
        Map<String, List<Benefit__c>> benefitsByKey = groupBenefitsByKey(activeBenefits);
        
        // 5. Lógica de concatenación y "Abrir la llave"
        updateProductBenefits(productsToUpdate, benefitsByKey);
    }
    
    // Método auxiliar para recolectar tipos y segmentos
    private static Map<String, Set<String>> collectTiposAndSegmentos(List<Benefit__c> benefits) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        result.put('tipos', new Set<String>());
        result.put('segmentos', new Set<String>());
        
        for(Benefit__c b : benefits) {
            if(b.Tipo_de_Tarjeta__c != null && b.Segmento_de_Tarjeta__c != null) {
                result.get('tipos').add(b.Tipo_de_Tarjeta__c);
                result.get('segmentos').add(b.Segmento_de_Tarjeta__c);
            }
        }
        return result;
    }
    
    // Método auxiliar para actualizar productos con beneficios
    private static void updateProductBenefits(List<Product2> productsToUpdate, Map<String, List<Benefit__c>> benefitsByKey) {
        for(Product2 p : productsToUpdate) {
            String key = p.Tipo_de_Tarjeta__c + '|' + p.Segmento_de_Tarjeta__c;
            List<Benefit__c> productBenefits = benefitsByKey.get(key);
            
            p.Is_System_Update__c = true;
            setBenefitTexts(p, productBenefits);
        }
        
        update productsToUpdate;
        
        for(Product2 p : productsToUpdate) {
            p.Is_System_Update__c = false;
        }
        
        update productsToUpdate;
    }
    
    // Método auxiliar para establecer los textos de beneficios
    private static void setBenefitTexts(Product2 p, List<Benefit__c> productBenefits) {
        if (productBenefits != null) {
            p.Beneficios_principales__c = buildBenefitsText(productBenefits, 'Beneficio');
            p.Promociones_asociadas__c = buildBenefitsText(productBenefits, 'Promoción');
        } else {
            p.Beneficios_principales__c = '';
            p.Promociones_asociadas__c = '';
        }
    }
    
    // Método auxiliar para agrupar beneficios por clave
    private static Map<String, List<Benefit__c>> groupBenefitsByKey(List<Benefit__c> benefits) {
        Map<String, List<Benefit__c>> result = new Map<String, List<Benefit__c>>();
        for(Benefit__c b : benefits) {
            String key = b.Tipo_de_Tarjeta__c + '|' + b.Segmento_de_Tarjeta__c;
            if (!result.containsKey(key)) {
                result.put(key, new List<Benefit__c>());
            }
            result.get(key).add(b);
        }
        return result;
    }
    
    // Método auxiliar para construir el texto de beneficios/promociones
    private static String buildBenefitsText(List<Benefit__c> benefits, String category) {
        String text = '';
        for(Benefit__c b : benefits) {
            if(b.Category__c == category) {
                text += '• ' + b.Name + ': ' + b.Description__c + '\n';
            }
        }
        return text;
    }
}