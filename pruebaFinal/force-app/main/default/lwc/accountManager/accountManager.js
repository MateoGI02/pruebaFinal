import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getMyAccounts from '@salesforce/apex/AccountManagerController.getMyAccounts';
import deleteAccount from '@salesforce/apex/AccountManagerController.deleteAccount';
import getAccountLeads from '@salesforce/apex/AccountManagerController.getAccountLeads';
import getAccountCases from '@salesforce/apex/AccountManagerController.getAccountCases';
import getAccountOpportunities from '@salesforce/apex/AccountManagerController.getAccountOpportunities';
import getAccountFinancialAccounts from '@salesforce/apex/AccountManagerController.getAccountFinancialAccounts';
import getAccountBeneficios from '@salesforce/apex/AccountManagerController.getAccountBeneficios';
import getAccountPromociones from '@salesforce/apex/AccountManagerController.getAccountPromociones';

const ACTIONS = [{ label: 'Editar', name: 'edit_record' }];

const COLUMNS = [
    { label: 'Nombre de Cuenta', fieldName: 'Name', editable: true },
    { label: 'Industria', fieldName: 'Industry', editable: true },
    { label: 'Teléfono', fieldName: 'Phone', type: 'phone', editable: true },
    { label: 'Ingresos Anuales', fieldName: 'AnnualRevenue', type: 'currency', editable: true }
];

const LEAD_COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Estado', fieldName: 'Status' },
    { label: 'Email', fieldName: 'Email' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

const CASE_COLUMNS = [
    { label: 'Número', fieldName: 'CaseNumber' },
    { label: 'Asunto', fieldName: 'Subject' },
    { label: 'Estado', fieldName: 'Status' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

const OPP_COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Etapa', fieldName: 'StageName' },
    { label: 'Monto', fieldName: 'Amount', type: 'currency' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

const FINACC_COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Estado', fieldName: 'Estado__c' },
    { label: 'Línea Actual', fieldName: 'Linea_Actual__c', type: 'currency' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

const BENEFICIO_COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Descripción', fieldName: 'Description__c' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class AccountManager extends NavigationMixin(LightningElement) {
    columns = COLUMNS; leadColumns = LEAD_COLUMNS; caseColumns = CASE_COLUMNS; 
    oppColumns = OPP_COLUMNS; finAccColumns = FINACC_COLUMNS; beneficioColumns = BENEFICIO_COLUMNS;
    
    accounts; leads; cases; opportunities; financialAccounts; beneficios; promociones;
    error; wiredAccountsResult; draftValues = []; selectedRecordId = null;

    tipoTarjetaSeleccionado = '';
    segmentoTarjetaSeleccionado = '';

    get tipoOpciones() {
        return [
            { label: 'Ninguno', value: '' },
            { label: 'Visa', value: 'Visa' },
            { label: 'Mastercard', value: 'Mastercard' },
            { label: 'Amex', value: 'Amex' }
        ];
    }

    get segmentoOpciones() {
        if (this.tipoTarjetaSeleccionado === 'Visa') {
            return [
                { label: 'Ninguno', value: '' },
                { label: 'Light', value: 'Light' }, { label: 'Clásica', value: 'Clásica' }, 
                { label: 'Oro', value: 'Oro' }, { label: 'Platinum', value: 'Platinum' }, 
                { label: 'Signature', value: 'Signature' }, { label: 'Infinite', value: 'Infinite' }
            ];
        } else if (this.tipoTarjetaSeleccionado === 'Mastercard') {
            return [
                { label: 'Ninguno', value: '' },
                { label: 'Standard', value: 'Standard' }, { label: 'Oro', value: 'Oro' }, 
                { label: 'Platinum', value: 'Platinum' }
            ];
        } else if (this.tipoTarjetaSeleccionado === 'Amex') {
            return [
                { label: 'Ninguno', value: '' },
                { label: 'Clásica', value: 'Clásica' }, { label: 'Oro', value: 'Oro' }, 
                { label: 'Platinum', value: 'Platinum' }, { label: 'Black', value: 'Black' }
            ];
        }
        return [{ label: 'Seleccione Tipo primero', value: '' }];
    }

    get isSegmentoDisabled() {
        return !this.tipoTarjetaSeleccionado;
    }

    handleTipoChange(event) {
        this.tipoTarjetaSeleccionado = event.detail.value;
        this.segmentoTarjetaSeleccionado = '';
    }

    handleSegmentoChange(event) {
        this.segmentoTarjetaSeleccionado = event.detail.value;
    }

    @wire(getMyAccounts)
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) { this.accounts = result.data; this.error = undefined; } 
        else if (result.error) { this.error = result.error.body.message; this.accounts = undefined; }
    }

    @wire(getAccountLeads, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredLeads({ error, data }) { this.leads = data && data.length > 0 ? data : null; }

    @wire(getAccountCases, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredCases({ error, data }) { this.cases = data && data.length > 0 ? data : null; }

    @wire(getAccountOpportunities, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredOpps({ error, data }) { this.opportunities = data && data.length > 0 ? data : null; }

    @wire(getAccountFinancialAccounts, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredFinAccs({ error, data }) { this.financialAccounts = data && data.length > 0 ? data : null; }

    @wire(getAccountBeneficios, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredBeneficios({ error, data }) { this.beneficios = data && data.length > 0 ? data : null; }

    @wire(getAccountPromociones, { accountId: '$selectedRecordId', tipoTarjeta: '$tipoTarjetaSeleccionado', segmentoTarjeta: '$segmentoTarjetaSeleccionado' })
    wiredPromociones({ error, data }) { this.promociones = data && data.length > 0 ? data : null; }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecordId = selectedRows.length > 0 ? selectedRows[0].Id : null;
    }

    // ABRIR MODAL DE EDICIÓN NATIVO
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const rowId = event.detail.row.Id;

        if (actionName === 'edit_record') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: rowId,
                    actionName: 'edit'
                }
            });
        }
    }

    handleNew() {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Account', actionName: 'new' } });
    }

    handleEdit() {
        if (!this.selectedRecordId) return this.showToast('Atención', 'Selecciona una cuenta.', 'warning');
        this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: this.selectedRecordId, objectApiName: 'Account', actionName: 'edit' } });
    }

    handleDelete() {
        if (!this.selectedRecordId) return this.showToast('Atención', 'Selecciona una cuenta.', 'warning');
        deleteAccount({ accountId: this.selectedRecordId })
            .then(() => {
                this.showToast('Éxito', 'Cuenta eliminada.', 'success');
                this.selectedRecordId = null;
                return refreshApex(this.wiredAccountsResult);
            })
            .catch(error => this.showToast('Error', error.body.message, 'error'));
    }

    async handleSave(event) {
        const records = event.detail.draftValues.slice().map(draft => ({ fields: Object.assign({}, draft) }));
        this.draftValues = [];
        try {
            await Promise.all(records.map(record => updateRecord(record)));
            this.showToast('Éxito', 'Cuentas actualizadas.', 'success');
            refreshApex(this.wiredAccountsResult);
        } catch (error) {
            this.showToast('Error', 'Error al actualizar.', 'error');
        }
    }

    handleNewLead() {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Lead', actionName: 'new' } });
    }

    handleNewCase() {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Case', actionName: 'new' } });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}