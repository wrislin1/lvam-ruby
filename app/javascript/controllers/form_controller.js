import {useDebounce, ApplicationController} from "stimulus-use";

export default class extends ApplicationController {
  static targets = ['submit', 'cancel'];
  static debounces = ['debouncedSubmit'];

  connect() {
    useDebounce(this, { wait: 300 });
    const form = this.element;
    form.addEventListener('turbo:submit-end', this.submitEnd);
    form.addEventListener('turbo:submit-start', this.submitStart);
    window.initFlowbite();
  }

  disconnect() {
    const form = this.element;
    form.removeEventListener('turbo:submit-end', this.submitEnd);
    form.removeEventListener('turbo:submit-start', this.submitStart);
  }

  submit = () => this.element.requestSubmit();

  debouncedSubmit = () => this.element.requestSubmit();

  resetInputs = e => {
    const inputs = JSON.parse(e.currentTarget.dataset.inputs);
    const form = this.element;
    inputs.forEach(inputName => {
      Array.from(form.querySelectorAll(`[name="${inputName}"]`)).forEach(input => {
        const tag = input.tagName.toLowerCase(),
            type = input.getAttribute('type');
        if (tag === 'input') {
          if (type === 'checkbox') input.checked = false;
          else input.value = '';
        }
        else if (tag === 'select') input.value = '';
        else if (tag === 'textarea') input.value = '';
      });
    });
    this.submit();
  }

  clearInputs = () => {
    this.element.querySelectorAll('input, select, textarea').forEach(input => {
        const tag = input.tagName.toLowerCase(),
            type = input.getAttribute('type');
        if (tag === 'input') {
            if (type === 'checkbox') input.checked = false;
            else input.value = '';
        }
        else if (tag === 'select') input.value = '';
        else if (tag === 'textarea') input.value = '';
    })
  }

  clearAll = e => {
    this.clearInputs();
    this.submit();
  }

  reset = e => {
    e.preventDefault();
    this.resetInputs();
    this.submit();
  }

  toggleActions = disabled => {
    if (this.hasSubmitTarget) {
      if (disabled) {
        this.submitTarget.setAttribute('disabled', 'disabled');
        this.submitTarget.querySelector('.icon:not(.spinner)')?.classList?.add('hidden');
        this.submitTarget.querySelector('.icon.spinner')?.classList?.remove('hidden');
      }
      else {
        this.submitTarget.removeAttribute('disabled');
        this.submitTarget.querySelector('.icon:not(.spinner)')?.classList?.remove('hidden');
        this.submitTarget.querySelector('.icon.spinner')?.classList?.add('hidden');
      }
    }
    if (this.hasCancelTarget) {
      if (disabled) this.cancelTarget.setAttribute('disabled', 'disabled');
      else this.cancelTarget.removeAttribute('disabled');
    }
  }

  submitStart = e => {
    this.toggleActions(true);
    if (this.loadingOverlayValue) document.getElementById('loading-overlay')?.classList?.remove('hidden');
  }

  submitEnd = e => {
    this.toggleActions(false);
    if (this.loadingOverlayValue) document.getElementById('loading-overlay')?.classList?.add('hidden');
    const { success, fetchResponse } = e.detail,
        { response } = fetchResponse ?? {},
        { redirected, url } = response ?? {};
    if (success && this.resetOnSubmitValue) this.resetInputs();
    if (this.redirectValue) {
      if (!success || !redirected) return;
      Turbo.visit(url);
    }
  }

  disableSubmit = () => {
    const submitButton = this.element.querySelector('button[type="submit"]');
    if (submitButton) {
      submitButton.disabled = true;
    }
  }
}
