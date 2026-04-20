import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generarYGuardarContrato from '@salesforce/apex/GeneradorContratoController.generarYGuardarContrato';
import verificarContratoExistente from '@salesforce/apex/GeneradorContratoController.verificarContratoExistente';

const FIELDS = ['Opportunity.Contrato_Cargado__c'];

export default class GeneradorContrato extends LightningElement {
    @api recordId;
    
    isGenerating = false;
    mostrarPlantilla = false;
    contratoId; 
    pdfGeneradoUrl;

    // 1. Verifica si ya hay un PDF AUTOGENERADO en los archivos
    @wire(verificarContratoExistente, { recordId: '$recordId' })
    wiredVerificacion({ error, data }) {
        if (data === true) {
            // Si ya existe, saltamos directo a mostrar el visor
            this.pdfGeneradoUrl = '/apex/ContratoTemplate?id=' + this.recordId;
            this.mostrarPlantilla = true;
        } else if (error) {
            console.error('Error verificando contrato existente:', error);
        }
    }

    // 2. Verificamos si ya hay un contrato FIRMADO
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpp({ error, data }) {
        if (data) {
            this.contratoId = data.fields.Contrato_Cargado__c.value;
            if (this.contratoId) {
                this.mostrarPlantilla = true; 
            }
        }
    }

    handleGenerar() {
        this.isGenerating = true;
        
        generarYGuardarContrato({ recordId: this.recordId })
            .then(contentDocId => {
                this.pdfGeneradoUrl = '/apex/ContratoTemplate?id=' + this.recordId;
                this.mostrarPlantilla = true;
                
                const downloadUrl = `/sfc/servlet.shepherd/document/download/${contentDocId}`;
                window.open(downloadUrl, '_blank');
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Contrato autogenerado, guardado y descargado.',
                    variant: 'success'
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al generar',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isGenerating = false;
            });
    }

    handleUploadFinished(event) {
        const docId = event.detail.files[0].documentId;
        this.updateOpp(docId, 'Contrato firmado vinculado exitosamente.');
    }

    handleRemove() {
        this.updateOpp(null, 'Contrato firmado desvinculado.');
    }

    updateOpp(val, msg) {
        const fields = { Id: this.recordId, Contrato_Cargado__c: val };
        
        updateRecord({ fields })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Actualizado',
                    message: msg,
                    variant: 'success'
                }));
            })
            .catch(error => {
                // Ahora atrapa y muestra el error real
                console.error('Error detallado de updateRecord:', JSON.stringify(error));
                
                // Extrae el mensaje de error de la regla de validación o permisos
                let mensajeReal = 'Error desconocido al actualizar';
                if (error && error.body && error.body.output && error.body.output.errors.length > 0) {
                    mensajeReal = error.body.output.errors[0].message;
                } else if (error && error.body && error.body.message) {
                    mensajeReal = error.body.message;
                }
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'No se pudo actualizar la Oportunidad',
                    message: mensajeReal,
                    variant: 'error',
                    mode: 'sticky' // sticky hace que la alerta no desaparezca sola
                }));
            });
    }
}