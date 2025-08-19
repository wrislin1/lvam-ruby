const closeModal = id => {
    try {
        const el = document.getElementById(id);
        if (!el) return;
        const instance = new window.Modal(el);
        if (instance) instance.hide();
        el.remove();
    }
    catch (e) {
        console.error(`Error closing modal for ID=${id}`, e);
    }
}

window.Turbo.StreamActions.close_modals = function() {
    const modalId = this.getAttribute('id');
    if (!!modalId?.length) closeModal(modalId);
    else {
        const modals = document.querySelectorAll('.modal');
        modals.forEach(modal => closeModal(modal.id));
    }
}

window.Turbo.StreamActions.change_value = function() {
    const target = this.getAttribute('target');
    const value = this.getAttribute('value');
    const element = document.getElementById(target);
    if (element) element.value = value;
}

window.Turbo.StreamActions.redirect_to = function() {
    const path = this.getAttribute('path');
    if (!!path?.length) window.Turbo.visit(path);
}