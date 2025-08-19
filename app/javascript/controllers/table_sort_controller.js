import {Controller} from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    sort: Array,
    key: String
  };
  sortMap = new Map();

  connect() {
    this.sortValue.forEach(s => {
      const [key, order] = s.split(':');
      this.sortMap.set(key, order);
    });
  }

  navigate = url => window.Turbo.visit(url);

  click = e => {
    if (!e.ctrlKey) return;
    e.preventDefault();
    const alreadySortingDir = this.sortMap.get(this.keyValue);
    if (alreadySortingDir) this.sortMap.set(this.keyValue, alreadySortingDir === 'asc' ? 'desc' : 'asc');
    else this.sortMap.set(this.keyValue, 'asc');
    const newSortValue = [];
    this.sortMap.forEach((v, k) => newSortValue.push(`${k}:${v}`));
    const urlParams = new URLSearchParams(window.location.search);
    urlParams.delete('sort[]');
    urlParams.delete('sort');
    newSortValue.forEach(s => urlParams.append('sort[]', s));
    this.navigate(`${window.location.pathname}?${urlParams.toString()}`);
  }
}
