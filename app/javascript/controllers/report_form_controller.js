import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = [ 'app' ];
  static targets = [ 'column' ];

  connect() {
  }

  get sortedColumnIndices() {
    if (!this.hasColumnTarget) return [];
    return this.columnTargets.map(column => column.dataset.index);
  }

  updatePositions = () => {
    if (!this.hasColumnTarget) return;
    this.columnTargets.forEach((col, idx) => {
      const positionInput = col.querySelector('input.position');
      if (positionInput) positionInput.value = idx + 1;
    });
  }

  columnUp = e => {
    e.preventDefault();
    if (!this.hasColumnTarget) return;
    const reportCol = e.currentTarget.closest('.report-column'),
        { index } = reportCol.dataset,
        colSort = this.sortedColumnIndices.indexOf(index);
    if (colSort <= 0) return;
    const prevCol = this.columnTargets[colSort - 1];
    prevCol.parentElement.before(reportCol.parentElement);
    this.updatePositions();
  }

  columnDown = e => {
    e.preventDefault();
    if (!this.hasColumnTarget) return;
    const reportCol = e.currentTarget.closest('.report-column'),
        { index } = reportCol.dataset,
        colSort = this.sortedColumnIndices.indexOf(index);
    if (colSort === this.sortedColumnIndices.length - 1) return;
    const nextCol = this.columnTargets[colSort + 1];
    nextCol.parentElement.after(reportCol.parentElement);
    this.updatePositions();
  }

  syncColTitle = e => {
    const input = e.currentTarget,
        title = e.currentTarget.value,
        reportCol = input.closest('.report-column'),
        index = reportCol.dataset.index,
        headerTitle = reportCol.querySelector(`span.column-title[data-index="${index}"]`);
    if (!!title?.length) headerTitle.textContent = `(${title})`;
    else headerTitle.textContent = '';
  }

  submitStart = () => {
    this.appOutlet.showLoadingOverlay();
  }

  submitEnd = e => {
    this.appOutlet.hideLoadingOverlay();
  }
}
