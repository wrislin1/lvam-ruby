import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["amFileInput", "pmFileInput"]

    openAmFile() {
        this.amFileInputTarget.click()
    }

    openPmFile() {
        this.pmFileInputTarget.click()
    }
}
