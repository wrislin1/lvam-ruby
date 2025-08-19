import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [ 'confirm', 'form', 'input', 'cancel', 'close' ];

  connect() {
    this.initFormListeners();
  }

  toggleActions = disabled => {
    if (disabled) this.confirmTarget.setAttribute('disabled', 'disabled');
    else this.confirmTarget.removeAttribute('disabled');
    if (this.hasCancelTarget) {
      if (disabled) this.cancelTarget.setAttribute('disabled', 'disabled');
      else this.cancelTarget.removeAttribute('disabled');
    }
    if (this.hasCloseTarget) {
      if (disabled) this.closeTarget.setAttribute('disabled', 'disabled');
      else this.closeTarget.removeAttribute('disabled');
    }
  }

  initFormListeners = () => {
    // Remove any existing listeners
    this.formTarget.removeEventListener('turbo:submit-start', this.submitStart);
    this.formTarget.removeEventListener('turbo:submit-end', this.submitEnd);
    // Add new listeners
    this.formTarget.addEventListener('turbo:submit-start', this.submitStart);
    this.formTarget.addEventListener('turbo:submit-end', this.submitEnd);
  }

  submitStart = e => {
    this.toggleActions(true);
    this.confirmTarget.querySelector('.icon:not(.spinner)').classList.add('hidden');
    this.confirmTarget.querySelector('.icon.spinner').classList.remove('hidden');
  }

  submitEnd = e => {
    this.toggleActions(false);
    this.confirmTarget.querySelector('.icon:not(.spinner)').classList.remove('hidden');
    this.confirmTarget.querySelector('.icon.spinner').classList.add('hidden');
    this.initFormListeners();
  }

  input = e => {
    if (this.inputTarget.checkValidity()) {
      this.confirmTarget.classList.remove('disabled');
      this.confirmTarget.removeAttribute('disabled')
    }
    else {
      this.confirmTarget.classList.add('disabled');
      this.confirmTarget.setAttribute('disabled', 'disabled');
    }
  }

  submit = () => this.formTarget.requestSubmit();
}