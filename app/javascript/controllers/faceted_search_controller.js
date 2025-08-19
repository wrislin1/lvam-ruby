import {useDebounce, ApplicationController} from "stimulus-use";

export default class extends ApplicationController {
  static debounces = [ 'search' ];
  static targets = [ 'checkbox', 'chips', 'chipTemplate', 'blank', 'searchInput', 'option', 'toggle' ];
  static values = { id: String, single: Boolean };

  connect() {
    useDebounce(this, { wait: 300 });
  }

  disconnect() {
    if (this.dropdownInstance) this.dropdownInstance.destroyAndRemoveInstance();
  }

  get selectedValues() {
    return this.checkboxTargets
        .filter(checkbox => checkbox.checked)
        .map(checkbox => ({ value: checkbox.value, label: checkbox.dataset.label }));
  }

  get dropdownInstance() {
    return window.FlowbiteInstances.getInstance('Dropdown', this.idValue);
  }

  change = e => {
    this.chipsTarget.innerHTML = '';
    this.selectedValues.forEach(({ value, label }) => {
      const chip = this.chipTemplateTarget.content.cloneNode(true);
      chip.querySelector('.chip-text').textContent = label;
      this.chipsTarget.appendChild(chip);
    });
    if (this.selectedValues.length) {
      this.chipsTarget.classList.remove('hidden');
      this.toggleTarget.classList.add('divide-x');
      this.blankTarget.checked = false;
    }
    else {
      this.chipsTarget.classList.add('hidden');
      this.toggleTarget.classList.remove('divide-x');
      this.blankTarget.checked = true;
    }
    const form = this.element.closest('form');
    if (!!form) form.requestSubmit();
  }

  search = () => {
    const q = (this.searchInputTarget.value ?? '').trim().toLowerCase();
    if (!q.length) return this.optionTargets.forEach(option => option.classList.remove('hidden'));
    this.optionTargets.forEach(option => {
      const { searchLabel } = option.dataset;
      if (!searchLabel?.length) return;
      if (searchLabel.toLowerCase().includes(q)) option.classList.remove('hidden');
      else option.classList.add('hidden');
    });
  }

  clearSearch = e => {
    this.searchInputTarget.value = '';
    this.search();
  }

  clearAll = e => {
    this.checkboxTargets.forEach(checkbox => checkbox.checked = false);
    if (this.dropdownInstance) this.dropdownInstance.hide();
    this.blankTarget.checked = true;
    this.change(e);
  }
}
