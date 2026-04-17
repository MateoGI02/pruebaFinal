import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Indicamos qué campos queremos "escuchar" de la Oportunidad
const FIELDS = [
    'Opportunity.Doc_Boleta_Pago__c',
    'Opportunity.Doc_Recibo_Honorarios__c',
    'Opportunity.Doc_PDT__c',
    'Opportunity.Doc_Reporte_Tributario__c'
];

export default class CargaSustentos extends LightningElement {
    @api recordId;

    // Variables internas para guardar el ID de cada documento
    boletaId;
    reciboId;
    pdtId;
    reporteId;

    // Escucha automáticamente los datos de la Oportunidad apenas carga la página
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.boletaId = data.fields.Doc_Boleta_Pago__c.value;
            this.reciboId = data.fields.Doc_Recibo_Honorarios__c.value;
            this.pdtId = data.fields.Doc_PDT__c.value;
            this.reporteId = data.fields.Doc_Reporte_Tributario__c.value;
        } else if (error) {
            console.error('Error cargando los datos', error);
        }
    }

    // "Getters" que le dicen al HTML si debe mostrar la vista con archivo o sin archivo
    get hasBoleta() { return !!this.boletaId; }
    get hasRecibo() { return !!this.reciboId; }
    get hasPdt() { return !!this.pdtId; }
    get hasReporte() { return !!this.reporteId; }

    // Función: Cuando se termina de subir un PDF (Nuevo o Reemplazo)
    handleUploadFinished(event) {
        const docName = event.target.name;
        const documentId = event.detail.files[0].documentId;
        this.updateOpportunityField(docName, documentId, '¡PDF cargado y guardado con éxito!');
    }

    // Función: Cuando hacen clic en el botón rojo de Eliminar
    handleRemove(event) {
        const docName = event.target.dataset.name;
        // Al enviar "null", limpiamos el campo y desenlazamos el archivo
        this.updateOpportunityField(docName, null, 'Documento eliminado del registro.');
    }

    // Función maestra que guarda el cambio en la base de datos de Salesforce
    updateOpportunityField(docName, docId, successMessage) {
        const fields = { Id: this.recordId };

        if (docName === 'boleta') fields.Doc_Boleta_Pago__c = docId;
        else if (docName === 'recibo') fields.Doc_Recibo_Honorarios__c = docId;
        else if (docName === 'pdt') fields.Doc_PDT__c = docId;
        else if (docName === 'reporte') fields.Doc_Reporte_Tributario__c = docId;

        // Actualizamos el registro nativamente
        updateRecord({ fields })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: successMessage,
                        variant: 'success',
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error al actualizar',
                        message: error.body ? error.body.message : 'Error desconocido',
                        variant: 'error',
                    })
                );
            });
    }
}