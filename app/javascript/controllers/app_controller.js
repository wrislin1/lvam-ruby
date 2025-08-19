import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'loadingOverlay' ];

  connect() {
    console.log('app connect');
    this.hideLoadingOverlay();
    this.initFlowbite();
  }

  morph = () => {
    console.log('app morph');
    this.initFlowbite();
  }

  frameRender = () => {
    console.log('app frameRender');
    this.initFlowbite();
  }

  initFlowbite = () => {
    window.initFlowbite();
  }

  showLoadingOverlay = () => {
    this.loadingOverlayTarget.classList.remove('hidden');
  }

  hideLoadingOverlay = () => {
    this.loadingOverlayTarget.classList.add('hidden');
  }
}
