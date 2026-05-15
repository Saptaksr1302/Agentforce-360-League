import { LightningElement, api } from 'lwc';

/** TODO FOR THE CHALLENGE: import the state manager, and the context modules */
import promotionStateManager from 'c/promotionStateManager';
import { fromContext } from '@lwc/state';

export default class PromotionWizardStep1 extends LightningElement {
    
    /** TODO FOR THE CHALLENGE: initialize/inherit the state from the parent */
    promotionState = fromContext(promotionStateManager);
    promotionName;

    connectedCallback(){
        this.promotionName = this.promotionState?.value?.promotionName;
    }

    handleChange(event) {
        this.promotionName = event.target.value;
        console.log('Promotion Name:', this.promotionName);
    }

    @api
    allValid(){
        // Read the current input value (handles clicking Next before onchange fires)
        this.promotionName = this.template.querySelector('lightning-input')?.value || this.promotionName;

        if(this.promotionName === undefined || this.promotionName === ''){
            return false;
        }else{
            console.log('allValid() Called');
            // Update the promotion name in the state
            this.promotionState.value.updatePromotionName(this.promotionName);
            console.log(this.promotionName);
        
            return true;
        }
    }
}