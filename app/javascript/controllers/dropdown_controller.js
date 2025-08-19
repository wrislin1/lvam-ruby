import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { init: Boolean };
  static targets = [ 'trigger' ];

  get dropdownToggles() {
    const trigger = this.hasTriggerTarget ? this.triggerTarget : this.element.querySelector('[data-dropdown-toggle]');
    return trigger?.getAttribute('data-dropdown-toggle');
  }

  get dropdownEl() {
    const id = this.dropdownToggles;
    return !!id?.length ? document.getElementById(id) : null;
  }

  get dropdownInstance() {
    const id = this.dropdownToggles;
    if (!id?.length) return;
    const { [id]: dropdown } = window.FlowbiteInstances['_instances']['Dropdown'];
    return dropdown;
  }

  connect() {
    if (!this.initValue) return;
    new window.Dropdown(this.dropdownEl, this.triggerTarget);
    this.addClickListeners();
  }

  disconnect() {
    this.hideDropdown()();
    this.removeClickListeners();
  }

  hideDropdown = (that = null) => () => {
    const dropdown = (that ?? this).dropdownInstance;
    if (dropdown) dropdown.hide();
  }

  removeClickListeners = () => {
    const dropdown = this.dropdownEl;
    if (!dropdown) return;
    const els = [ ...dropdown.querySelectorAll('a'), ...dropdown.querySelectorAll('form button[type="submit"]') ];
    els.forEach(el => el.removeEventListener('click', this.hideDropdown(this)));
  }

  addClickListeners = () => {
    const dropdown = this.dropdownEl;
    if (!dropdown) return;
    const els = [ ...dropdown.querySelectorAll('a'), ...dropdown.querySelectorAll('form button[type="submit"]') ];
    els.forEach(el => el.addEventListener('click', this.hideDropdown(this)));
  }
}
