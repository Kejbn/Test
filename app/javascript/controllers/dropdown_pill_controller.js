import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "input", "pillContainer"];

  connect() {
    this.addPIllsFromCheckboxes()
  }

  addPIllsFromCheckboxes() {
    // look up all checked checkboxes and add a pill for each
    const checkedBoxes = document.querySelectorAll("div[id=specialties-accordion] input[type=checkbox]:checked")

    checkedBoxes.forEach((checkbox) => {
      this.addPill(checkbox.value)
    })
  }

  addPill(domId) {
    const displayedPill = document.getElementById(`specialty_${domId}`)

    if (!displayedPill) {
      const template = document.getElementById(`specialty_${domId}-template`)
      const content = template.content.cloneNode(true)
      this.pillContainerTarget.appendChild(content)

      const checkbox = document.getElementById(`specialty_ids_${domId}`)
      checkbox.checked = true
    }
    else {
      // the pill is already there, so don't do anything
    }
  }

  removePill(event) {
    event.currentTarget.remove()

    const checkbox = document.getElementById(`specialty_ids_${event.currentTarget.dataset.specialtyId}`)
    checkbox.checked = false
  }

  onSpecialityClick(event) {
    event.preventDefault();
    const domId = event.currentTarget.dataset.value;
    this.addPill(domId);
    this.inputTarget.value = "";
    this.dropdownTarget.innerHTML = "";
  }
}
