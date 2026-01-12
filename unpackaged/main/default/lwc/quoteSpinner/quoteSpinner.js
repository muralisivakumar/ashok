import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from "lightning/refresh";

import CALC_FIELD from '@salesforce/schema/Quote.AVA_SFCLOUD__Calculate_Tax__c';
import MSG_FIELD from '@salesforce/schema/Quote.AVA_SFCLOUD__AvaTax_Message__c';

export default class QuoteSpinner extends LightningElement {
    @api recordId;
    showSpinner = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CALC_FIELD, MSG_FIELD]
    })
    wiredQuote({ error, data }) {

        if (error || !data) {
            return;
        }

        const isCalcChecked = data.fields.AVA_SFCLOUD__Calculate_Tax__c.value;
        const message = data.fields.AVA_SFCLOUD__AvaTax_Message__c.value;

        const storageKey = `avatax_message_shown_${this.recordId}`;
        const lastShownMessage = sessionStorage.getItem(storageKey);
        if (isCalcChecked) {
            //this.showSpinner = true;
        }

        if (!message) {
            return;
        }
        if (message && message !== lastShownMessage) {

             this.showSpinner = true;
                setTimeout(() => {
                    this.showSpinner = false;
                }, 5000);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Tax Calculated',
                    message: message,
                    variant: 'warning',
                    mode: 'dismissible'
                })
            );
            sessionStorage.setItem(storageKey, message);
            setTimeout(() => {
                this.dispatchEvent(new RefreshEvent());
            }, 15000);
        }
    }
}