const NUM_PAGES = 5;

export default () => ({
  modalOpen: false,
  currentPage: 1,

  prevPage() {
    if (this.currentPage > 1) {
      this.currentPage -= 1;
    }
  },

  nextPage() {
    if (this.currentPage < NUM_PAGES) {
      this.currentPage += 1;
    }
  },

  get showPrevArrow() {
    return this.currentPage !== 1;
  },

  get showNextArrow() {
    return this.currentPage !== NUM_PAGES;
  },

  openModal() {
    this.modalOpen = true;
  },

  closeModal() {
    this.modalOpen = false;
    this.currentPage = 1;
  }
});
