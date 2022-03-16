/**
 * Room frontend state, for Alpine x-data directive.
 */

const BottomBarStates = {
  NORMAL: Symbol('normal'),
  FULL: Symbol('full'),
  COLLAPSED: Symbol('collapsed')
};

export default () => ({
  chatSidebarShow: true,
  mobileChatOpen: false,
  bottomBarState: BottomBarStates.NORMAL,
  bottomBarTapped: null,

  bottomBarFull() {
    this.toggleBetweenBottomBarStates(BottomBarStates.NORMAL, BottomBarStates.FULL);
  },

  bottomBarCollapse() {
    this.toggleBetweenBottomBarStates(BottomBarStates.NORMAL, BottomBarStates.COLLAPSED);
  },

  toggleBetweenBottomBarStates(state1, state2) {
    if (this.bottomBarState === state2) {
      this.bottomBarState = state1;
    } else {
      this.bottomBarState = state2;
    }
  },

  get bottomRowHeight() {
    switch (this.bottomBarState) {
      case BottomBarStates.NORMAL: return 'h-2/5';
      case BottomBarStates.FULL: return 'h-full';
      case BottomBarStates.COLLAPSED: return '';
    }
  },

  get bottomBarShow() {
    return this.bottomBarState != BottomBarStates.COLLAPSED;
  },

  handleBottomBarTap() {
    if (!this.bottomBarTapped) {
      // First tap
      this.bottomBarTapped = setTimeout(() => {
        this.bottomBarTapped = null
      }, 300);
    } else {
      // Second tap
      clearTimeout(this.bottomBarTapped);
      this.bottomBarTapped = null
      this.bottomBarFull();
    }
  },

  addTouchPropagationStoppers() {
    this.$el.querySelectorAll('button').forEach(
      el => el.addEventListener('touchstart', e => e.stopPropagation())
    );
  },

  toggleMobileChat() {
    if (!this.mobileChatOpen) {
      this.$store.unreadChat = false;
    }

    this.mobileChatOpen = !this.mobileChatOpen;
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
    this.calibratePagination();
    this.maybeToggleChatSidebar();

    window.addEventListener('phx:unread-chat', (_e) => {
      if (!(this.chatSidebarShow || this.mobileChatOpen)) {
        window.Alpine.store('unreadChat', true);
      }
    });
  },

  handleWindowResize() {
    this.calibratePagination();
    this.maybeToggleChatSidebar();
  },

  maybeToggleChatSidebar() {
    const bodyEl = document.querySelector('body');

    if (bodyEl.clientWidth >= 640) { // Tailwind sm
      this.chatSidebarShow = true;
      this.mobileChatOpen = false;
    } else {
      this.chatSidebarShow = false;
    }
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

    if (this.numUsersPages > 0 && this.usersPage > this.numUsersPages) {
      this.usersPage = this.numUsersPages;
    }
  }
});
