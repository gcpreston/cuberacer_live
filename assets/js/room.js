/**
 * Room frontend state, for Alpine x-data directive.
 */

 export default () => ({
  mobileChatOpen: false,

  addTouchPropagationStoppers() {
    this.$el.querySelectorAll('button').forEach(
      el => el.addEventListener('touchstart', e => e.stopPropagation())
    );
  },

  // Pagination

  numPresentUsers: 0,
  usersPage: 1,
  usersPerPage: 4,

  get numUsersPages() {
    return Math.ceil(this.numPresentUsers / this.usersPerPage)
  },

  get displayStartEnd() {
    let start = (this.usersPage - 1) * this.usersPerPage;
    let end = start + this.usersPerPage;

    if (end > this.numPresentUsers) {
      end = this.numPresentUsers;
      start = end - this.usersPerPage;
    }

    return [start, end];
  },

  isColShown(index) {
    const [start, end] = this.displayStartEnd;
    return (start <= index) && (index < end);
  },

  get moreUsersLeft() {
    const [start, _end] = this.displayStartEnd;
    return start > 0;
  },

  get moreUsersRight() {
    const [_start, end] = this.displayStartEnd;
    return end < (this.numPresentUsers);
  },

  pageLeft() {
    if (this.moreUsersLeft) this.usersPage -= 1;
  },

  pageRight() {
    if (this.moreUsersRight) this.usersPage += 1;
  },

  initializeRoom(numPresentUsers) {
    this.numPresentUsers = numPresentUsers;
    this.calibratePagination()
  },

  calibratePagination() {
    const fontSize = parseFloat(
      getComputedStyle(
        document.querySelector('html')
      )['font-size']
    );

    const timesTableEl = document.querySelector('#times-table');
    const timesTableWidth = (timesTableEl.clientWidth) / fontSize;

    const cellEl = document.querySelector('#times-table th:not(.hidden)');
    const cellWidth = (cellEl.clientWidth) / fontSize;

    this.usersPerPage = Math.floor(timesTableWidth / cellWidth);

    if (this.usersPage > this.numUsersPages) {
      this.usersPage = this.numUsersPages;
    }
  }
 });
