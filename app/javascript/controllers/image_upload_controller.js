import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["fileInput"]

    openFilePicker() {
        this.fileInputTarget.click()
    }
}
