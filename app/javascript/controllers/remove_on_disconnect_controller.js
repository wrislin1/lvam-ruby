import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  disconnect() {
    this.element.remove();
  }
}
