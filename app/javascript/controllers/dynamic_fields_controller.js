import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dynamic-fields"
export default class extends Controller {
    static targets = ["template"];

    connect() {}

    // __CHILD_INDEX__ will be replaced dynamically
    add(event) {
        event.preventDefault();
        event.currentTarget.insertAdjacentHTML(
            "beforebegin",
            this.templateTarget.innerHTML.replace(
                /__CHILD_INDEX__/g,
                new Date().getTime().toString()
            )
        );
        window.initFlowbite();
    }

    remove(event) {
        const container = event.currentTarget.closest(".nested-fields"),
            id = container.querySelector("input.id")?.value,
            destroy = container.querySelector("input.destroy");

        if (id?.length) {
            destroy.value = "1";
            container.classList.add("hidden");
        } else if (container) {
            container.remove();
        }
    }

    removeWithConfirm = e => {
        const { confirmation } = e.currentTarget.dataset ?? {};
        if (!confirm(confirmation ?? 'Are you sure?')) return;
        this.remove(e);
    }
}
