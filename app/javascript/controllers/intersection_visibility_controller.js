import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["intersection", "toggleButton"]
    static values = {
        hiddenIntersections: Array,
        reportId: Number
    }

    connect() {
        this.loadState()
        this.restoreHiddenState()
        this.updateAllToggleButtons()
        this.bindDownloadForms()
    }

    disconnect() {
        if (this.boundFormHandler) {
            document.removeEventListener('submit', this.boundFormHandler)
        }
    }

    bindDownloadForms() {
        this.boundFormHandler = this.handleFormSubmit.bind(this)
        document.addEventListener('submit', this.boundFormHandler)
    }

    handleFormSubmit(event) {
        const form = event.target

        if (form.action && form.action.includes('/download')) {
            const hiddenIntersections = this.getCurrentHiddenIntersectionsForDownload()

            if (hiddenIntersections) {
                this.addHiddenIntersectionsToForm(form, hiddenIntersections)
            }
        }
    }

    getCurrentHiddenIntersectionsForDownload() {
        if (!this.reportIdValue) return null

        const key = `report-${this.reportIdValue}-hidden-intersections`
        const hiddenIntersections = localStorage.getItem(key)

        if (hiddenIntersections) {
            return hiddenIntersections
        }

        return null
    }

    addHiddenIntersectionsToForm(form, hiddenIntersections) {
        const existingInput = form.querySelector('input[name="hidden_intersections"]')
        if (existingInput) {
            existingInput.remove()
        }

        const hiddenInput = document.createElement('input')
        hiddenInput.type = 'hidden'
        hiddenInput.name = 'hidden_intersections'
        hiddenInput.value = hiddenIntersections
        form.appendChild(hiddenInput)
    }

    toggleIntersection(event) {
        const intersectionId = event.currentTarget.dataset.intersectionId
        const intersection = this.findIntersectionElement(intersectionId)

        if (!intersection) {
            console.warn(`Intersection not found: ${intersectionId}`)
            return
        }

        if (intersection.classList.contains('hidden-intersection')) {
            this.showIntersection(intersectionId)
        } else {
            this.hideIntersection(intersectionId)
        }
    }

    hideIntersection(intersectionId) {
        const intersection = this.findIntersectionElement(intersectionId)
        if (!intersection) return

        intersection.classList.add('hidden-intersection')

        if (!this.hiddenIntersectionsValue.includes(intersectionId)) {
            this.hiddenIntersectionsValue = [...this.hiddenIntersectionsValue, intersectionId]
        }

        this.updateToggleButton(intersectionId, true)
        this.saveState()
    }

    showIntersection(intersectionId) {
        const intersection = this.findIntersectionElement(intersectionId)
        if (!intersection) return

        intersection.classList.remove('hidden-intersection')

        this.hiddenIntersectionsValue = this.hiddenIntersectionsValue.filter(id => id !== intersectionId)

        this.updateToggleButton(intersectionId, false)
        this.saveState()
    }

    findIntersectionElement(intersectionId) {
        return this.intersectionTargets.find(el =>
            el.dataset.intersectionId === intersectionId
        )
    }

    updateToggleButton(intersectionId, isHidden) {
        const button = this.toggleButtonTargets.find(btn =>
            btn.dataset.intersectionId === intersectionId
        )

        if (button) {
            const iconOpen = button.querySelector('.intersection-open')
            const iconClosed = button.querySelector('.intersection-closed')

            button.title = isHidden ? 'Show intersection' : 'Hide intersection'
            if (iconOpen) iconOpen.classList.toggle('hidden', isHidden)
            if (iconClosed) iconClosed.classList.toggle('hidden', !isHidden)
        }
    }

    updateAllToggleButtons() {
        this.toggleButtonTargets.forEach(button => {
            const intersectionId = button.dataset.intersectionId
            const isHidden = this.hiddenIntersectionsValue.includes(intersectionId)
            this.updateToggleButton(intersectionId, isHidden)
        })
    }

    restoreHiddenState() {
        this.hiddenIntersectionsValue.forEach(intersectionId => {
            const intersection = this.findIntersectionElement(intersectionId)
            if (intersection) {
                intersection.classList.add('hidden-intersection')
                this.updateToggleButton(intersectionId, true)
            }
        })
    }

    saveState() {
        if (!this.reportIdValue) return

        const hiddenKey = `report-${this.reportIdValue}-hidden-intersections`
        localStorage.setItem(hiddenKey, JSON.stringify(this.hiddenIntersectionsValue))
    }

    loadState() {
        if (!this.reportIdValue) return

        const hiddenKey = `report-${this.reportIdValue}-hidden-intersections`
        const savedHidden = localStorage.getItem(hiddenKey)

        if (savedHidden) {
            try {
                this.hiddenIntersectionsValue = JSON.parse(savedHidden)
            } catch (error) {
                console.warn('Failed to parse saved intersection state:', error)
                this.hiddenIntersectionsValue = []
            }
        }
    }

    showAll() {
        this.intersectionTargets.forEach(intersection => {
            const intersectionId = intersection.dataset.intersectionId
            this.showIntersection(intersectionId)
        })
    }

    hideAll() {
        this.intersectionTargets.forEach(intersection => {
            const intersectionId = intersection.dataset.intersectionId
            this.hideIntersection(intersectionId)
        })
    }
}