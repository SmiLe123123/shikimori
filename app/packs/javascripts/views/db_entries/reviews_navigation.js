import { bind, memoize } from 'shiki-decorators';
import TinyUri from 'tiny-uri';

import View from '@/views/application/view';
import axios from '@/helpers/axios';

export class ReviewsNavigation extends View {
  initialize() {
    this.$navigations = this.$('.navigation-container > .navigation-node');
    this.$contents = this.$('.content-container > .content-node');

    this.states = this.$navigations.toArray().map((node, index) => ({
      navigationNode: node,
      contentNode: this.$contents[index],
      opinion: node.getAttribute('data-opinion'),
      isActive: false,
      isLoading: false
    }));

    this.$navigations.on('click', this.navigationBlockClick);

    this.selectOpinion(this.initialOption);
  }

  @memoize
  get initialOption() {
    return this.$node.data('initial-opinion');
  }

  @memoize
  get fetchUrlBase() {
    return this.$node.data('fetch-url-base');
  }

  @bind
  navigationBlockClick({ currentTarget }) {
    this.selectOpinion(currentTarget.getAttribute('data-opinion'));
  }

  selectOpinion(opinion) {
    const state = this.findEntry(opinion);
    if (state.isActive) { return; }

    this.deselectActiveOpinion();

    state.isActive = true;
    state.navigationNode.classList.add('is-active');
    state.contentNode.classList.add('is-active');

    this.replaceHistoryState(state);

    if (this.isNoContentLoaded(state.contentNode)) {
      this.loadContent(state);
    } else {
    }

    this.ellipsisFixes();
  }

  deselectActiveOpinion() {
    const state = this.states.find(v => v.isActive);
    if (!state) { return; }

    state.isActive = false;
    state.navigationNode.classList.remove('is-active');
    state.contentNode.classList.remove('is-active');
  }

  findEntry(opinion) {
    return this.states.find(state => state.opinion === opinion);
  }

  ellipsisFixes() {
    this.$navigations
      .filter('[data-ellispsis-allowed]')
      .removeClass('is-ellipsis');

    this.$navigations
      .filter('[data-ellispsis-allowed]:not(.is-active)')
      .last()
      .addClass('is-ellipsis');
  }

  isNoContentLoaded(node) {
    return node.childElementCount === 0;
  }

  fetchUrl(opinion) {
    if (!opinion) {
      return this.fetchUrlBase;
    }

    return this.fetchUrlBase + '/' + opinion;
  }

  replaceHistoryState(state) {
    const url = this.fetchUrl(state.opinion);
    window.history.replaceState({ turbolinks: true, url }, '', url);
  }

  async loadContent(state) {
    if (state.isLoading) { return; }

    state.contentNode.classList.add('b-ajax');
    state.isLoading = true;

    const { data } = await axios.get(this.fetchUrl(state.opinion));

    state.contentNode.innerHTML = data.content + data.postloader;
    state.contentNode.classList.remove('b-ajax');
    state.isLoading = false;
  }
}
