<script>
import { GlAvatar, GlCollapsibleListbox } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { TYPENAME_DESIGN_VERSION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { findVersionId } from './utils';

export default {
  components: {
    GlAvatar,
    GlCollapsibleListbox,
    TimeAgo,
  },
  props: {
    allVersions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    allVersionsList() {
      return this.allVersions.map(({ id, ...item }, index) => ({
        value: id,
        index,
        ...item,
      }));
    },
    queryVersion() {
      return this.$route.query.version;
    },
    currentVersionIdx() {
      if (!this.queryVersion) return 0;

      const idx = this.allVersions.findIndex(
        (version) => this.findVersionId(version.id) === this.queryVersion,
      );

      // if the currentVersionId isn't a valid version (i.e. not in allVersions)
      // then return the latest version (index 0)
      return idx !== -1 ? idx : 0;
    },
    dropdownText() {
      if (this.isLatestVersion) {
        return __('Latest version');
      }
      // allVersions is sorted in reverse chronological order (the latest first)
      const currentVersionNumber = this.allVersions.length - this.currentVersionIdx;

      return sprintf(__('Showing version #%{versionNumber}'), {
        versionNumber: currentVersionNumber,
      });
    },
    hasValidVersion() {
      return (
        this.$route.query.version &&
        this.allVersions &&
        this.allVersions.some((version) => version.id.endsWith(this.$route.query.version))
      );
    },
    designsVersion() {
      return this.hasValidVersion
        ? convertToGraphQLId(TYPENAME_DESIGN_VERSION, this.$route.query.version)
        : null;
    },
    latestVersionId() {
      const latestVersion = this.allVersions[0];
      return latestVersion && findVersionId(latestVersion.id);
    },
    isLatestVersion() {
      if (this.allVersions.length > 0) {
        return (
          !this.$route.query.version ||
          !this.latestVersionId ||
          this.$route.query.version === this.latestVersionId
        );
      }
      return true;
    },
  },
  methods: {
    findVersionId,
    routeToVersion(versionId) {
      this.$router.push({
        path: this.$route.path,
        query: {
          // Retain any existing page params and only append/override `version`.
          ...queryToObject(window.location.search, { specialOperators: true }),
          version: this.findVersionId(versionId),
        },
      });
    },
    versionText(item) {
      const versionNumber = this.allVersions.length - item.index;
      const message =
        this.findVersionId(item.value) === this.latestVersionId
          ? __('Version %{versionNumber} (latest)')
          : __('Version %{versionNumber}');
      return sprintf(message, { versionNumber });
    },
    getAvatarUrl(version) {
      return version?.author?.avatarUrl || defaultAvatarUrl;
    },
    getAuthorName(author) {
      return author?.name;
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    is-check-centered
    :items="allVersionsList"
    :toggle-text="dropdownText"
    :selected="designsVersion"
    size="small"
    @select="routeToVersion"
  >
    <template #list-item="{ item }">
      <span class="gl-flex gl-items-center gl-gap-3">
        <gl-avatar :alt="getAuthorName(item.author)" :size="32" :src="getAvatarUrl(item)" />
        <span class="gl-flex gl-flex-col">
          <span class="gl-font-bold">{{ versionText(item) }}</span>
          <span v-if="item.author" class="gl-mt-1 gl-text-subtle">
            <span class="gl-block">{{ getAuthorName(item.author) }}</span>
            <time-ago
              v-if="item.createdAt"
              class="gl-text-sm"
              :time="item.createdAt"
              tooltip-placement="bottom"
            />
          </span>
        </span>
      </span>
    </template>
  </gl-collapsible-listbox>
</template>
