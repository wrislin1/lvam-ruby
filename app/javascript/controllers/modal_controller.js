import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { open: Boolean, backdrop: String };
  static targets = [ 'form', 'submit', 'cancel', 'close', 'focusInput' ];
  modal;
  unloaded = false;

  connect() {
    this.modal = new window.Modal(this.element, {
      backdrop: this.backdropValue ?? 'static',
      onHide: () => {
        this.unload();
      }
    }, {
      id: this.element.id,
      override: true
    });
    this.initFormListeners();
    if (this.openValue) {
      this.modal.show();
      if (this.hasFocusInputTarget) this.focusInputTarget.focus();
    }
  }

  disconnect() {
    this.unload();
  }

  initFormListeners = () => {
    if (!this.hasFormTarget) return;
    // Remove any existing listeners
    this.formTarget.removeEventListener('turbo:submit-start', this.submitStart);
    this.formTarget.removeEventListener('turbo:submit-end', this.submitEnd);
    // Add new listeners
    this.formTarget.addEventListener('turbo:submit-start', this.submitStart);
    this.formTarget.addEventListener('turbo:submit-end', this.submitEnd);
  }

  close = () => {
    if (this.modal) {
      try {
        this.modal.hide();
      }
      catch (e) {}
    }
  }

  unload = () => {
    if (this.unloaded) return;
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener('turbo:submit-start', this.submitStart);
      this.formTarget.removeEventListener('turbo:submit-end', this.submitEnd);
    }
    if (this.modal) {
      if (this.modal.isVisible()) this.close();
      try {
        this.modal.destroy();
      }
      catch (e) {}
      this.modal = null;
      try {
        this.element.remove();
      }
      catch (e) {}
    }
    this.unloaded = true;
  }

  submitStart = e => {
    if (!this.hasSubmitTarget) return;
    this.toggleActions(true);
    this.submitTarget.querySelector('.icon:not(.spinner)').classList.add('hidden');
    this.submitTarget.querySelector('.icon.spinner').classList.remove('hidden');
  }

  submitEnd = e => {
    this.toggleActions(false);
    this.submitTarget.querySelector('.icon:not(.spinner)').classList.remove('hidden');
    this.submitTarget.querySelector('.icon.spinner').classList.add('hidden');
    this.initFormListeners();
  }

  toggleActions = disabled => {
    if (this.hasSubmitTarget) {
      if (disabled) this.submitTarget.setAttribute('disabled', 'disabled');
      else this.submitTarget.removeAttribute('disabled');
    }
    if (this.hasCancelTarget) {
      if (disabled) this.cancelTarget.setAttribute('disabled', 'disabled');
      else this.cancelTarget.removeAttribute('disabled');
    }
    if (this.hasCloseTarget) {
      if (disabled) this.closeTarget.setAttribute('disabled', 'disabled');
      else this.closeTarget.removeAttribute('disabled');
    }
  }

  submit = () => {
    if (!this.hasFormTarget) return;
    if (this.formTarget.checkValidity()) this.formTarget.requestSubmit();
    else this.formTarget.reportValidity();
  }

  keydown = e => {
    if (e.key === 'Enter' && this.hasFormTarget) this.submit();
  }
}
