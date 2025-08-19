import { Controller } from "@hotwired/stimulus"
import Toastify from 'toastify-js'

export default class extends Controller {
  static values = { data: Object };

  connect() {
    const { duration, actionPath } = this.dataValue ?? {};
    this.toast = Toastify({
      text: this.element.children[0].outerHTML,
      className: 'custom-toast',
      duration: duration ?? 5000,
      destination: actionPath,
      close: true,
      gravity: 'top',
      position: 'right',
      stopOnFocus: true,
      escapeMarkup: false
    });
    this.toast.showToast();
  }

  close = () => {
    if (this.toast) this.toast.hideToast();
  }
}
