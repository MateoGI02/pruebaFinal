import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getMyAccounts from '@salesforce/apex/AccountManagerController.getMyAccounts';
import deleteAccount from '@salesforce/apex/AccountManagerController.deleteAccount';
import getAccountLeads from '@salesforce/apex/AccountManagerController.getAccountLeads';
import getAccountCases from '@salesforce/apex/AccountManagerController.getAccountCases';

const COLUMNS = [
    { label: 'Nombre de Cuenta', fieldName: 'Name', editable: true },
    { label: 'Industria', fieldName: 'Industry', editable: true },
    { label: 'Teléfono', fieldName: 'Phone', type: 'phone', editable: true },
    { label: 'Ingresos Anuales', fieldName: 'AnnualRevenue', type: 'currency', editable: true }
];

const LEAD_COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Estado', fieldName: 'Status' },
    { label: 'Email', fieldName: 'Email' }
];

const CASE_COLUMNS = [
    { label: 'Número', fieldName: 'CaseNumber' },
    { label: 'Asunto', fieldName: 'Subject' },
    { label: 'Estado', fieldName: 'Status' }
];

export default class AccountManager extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    leadColumns = LEAD_COLUMNS;
    caseColumns = CASE_COLUMNS;
    
    accounts;
    leads;
    cases;
    error;
    
    wiredAccountsResult; 
    draftValues = [];
    selectedRecordId = null;

    // --- WIRES ---

    @wire(getMyAccounts)
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) {
            this.accounts = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
            this.accounts = undefined;
        }
    }

    // Se ejecuta automáticamente cuando cambia selectedRecordId
    @wire(getAccountLeads, { accountId: '$selectedRecordId' })
    wiredLeads({ error, data }) {
        if (data) {
            this.leads = data.length > 0 ? data : null;
        } else if (error) {
            this.leads = null;
            console.error(error);
        }
    }

    // Se ejecuta automáticamente cuando cambia selectedRecordId
    @wire(getAccountCases, { accountId: '$selectedRecordId' })
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data.length > 0 ? data : null;
        } else if (error) {
            this.cases = null;
            console.error(error);
        }
    }

    // --- HANDLERS CUENTAS ---

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        // Al asignar esto, los @wire de Leads y Casos se disparan solos
        this.selectedRecordId = selectedRows.length > 0 ? selectedRows[0].Id : null;
    }

    handleNew() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Account', actionName: 'new' }
        });
    }

    handleEdit() {
        if (!this.selectedRecordId) {
            this.showToast('Atención', 'Selecciona una cuenta.', 'warning');
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.selectedRecordId, objectApiName: 'Account', actionName: 'edit' }
        });
    }

    handleDelete() {
        if (!this.selectedRecordId) {
            this.showToast('Atención', 'Selecciona una cuenta.', 'warning');
            return;
        }
        deleteAccount({ accountId: this.selectedRecordId })
            .then(() => {
                this.showToast('Éxito', 'Cuenta eliminada.', 'success');
                this.selectedRecordId = null;
                return refreshApex(this.wiredAccountsResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    async handleSave(event) {
        const records = event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
        this.draftValues = [];
        try {
            const recordUpdatePromises = records.map(record => updateRecord(record));
            await Promise.all(recordUpdatePromises);
            this.showToast('Éxito', 'Cuentas actualizadas.', 'success');
            refreshApex(this.wiredAccountsResult);
        } catch (error) {
            this.showToast('Error', 'Error al actualizar.', 'error');
        }
    }

    // --- HANDLERS LEADS Y CASOS ---

    handleNewLead() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Lead', actionName: 'new' }
        });
    }

    handleNewCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Case', actionName: 'new' }
        });
    }

    // --- UTILIDADES ---

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}