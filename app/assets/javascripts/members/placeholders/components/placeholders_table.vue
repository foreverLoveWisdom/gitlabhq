<script>
import {
  GlAvatarLabeled,
  GlBadge,
  GlKeysetPagination,
  GlLoadingIcon,
  GlTable,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';

import { DEFAULT_PAGE_SIZE } from '~/members/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import {
  PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER,
  PLACEHOLDER_STATUS_COMPLETED,
  placeholderUserBadges,
} from '~/import_entities/import_groups/constants';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import PlaceholderActions from './placeholder_actions.vue';

const MINIMUM_QUERY_LENGTH = 3;

export default {
  name: 'PlaceholdersTable',
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTable,
    GlSprintf,
    GlLink,
    PlaceholderActions,
    HelpPopover,
    EmptyResult,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['group'],
  props: {
    queryStatuses: {
      type: Array,
      required: true,
    },
    querySearch: {
      type: String,
      required: false,
      default: null,
    },
    querySort: {
      type: String,
      required: false,
      default: null,
    },
    reassigned: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      cursor: {
        before: null,
        after: null,
      },
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    sourceUsers: {
      query: importSourceUsersQuery,
      variables() {
        return {
          fullPath: this.group.path,
          ...this.cursor,
          [this.cursor.before ? 'last' : 'first']: DEFAULT_PAGE_SIZE,
          statuses: this.queryStatuses,
          search: this.querySearch,
          sort: this.querySort,
        };
      },
      // ensures up-to-date (instead of cached, sometimes inaccurate) results when query executes
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      skip() {
        return this.isSearchQueryTooShort;
      },
      update(data) {
        return data.namespace?.importSourceUsers;
      },
      error() {
        createAlert({
          message: s__('UserMapping|Placeholder users could not be fetched.'),
        });
      },
    },
  },

  computed: {
    fields() {
      return [
        {
          key: 'user',
          label: s__('UserMapping|Placeholder user'),
        },
        {
          key: 'source',
          label: s__('BulkImport|Source'),
        },
        {
          key: 'createdAt',
          label: __('Created at'),
        },
        {
          key: 'status',
          label: s__('UserMapping|Reassignment status'),
        },
        {
          key: 'actions',
          label: this.reassigned
            ? s__('UserMapping|Reassigned to')
            : s__('UserMapping|Reassign placeholder to'),
          thClass: 'gl-w-4/10',
        },
      ];
    },
    isLoading() {
      return this.$apollo.queries.sourceUsers.loading;
    },
    nodes() {
      if (this.isSearchQueryTooShort) {
        return [];
      }
      return this.sourceUsers?.nodes || [];
    },
    pageInfo() {
      return this.sourceUsers?.pageInfo || {};
    },
    isSearchQueryTooShort() {
      return this.querySearch && this.querySearch.trim().length < MINIMUM_QUERY_LENGTH;
    },
  },

  methods: {
    statusBadge(item) {
      return placeholderUserBadges[item.status];
    },

    isReassignedItem(item) {
      return (
        item.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER ||
        item.status === PLACEHOLDER_STATUS_COMPLETED
      );
    },
    isPlaceholderUserDeleted(item) {
      return item.status === PLACEHOLDER_STATUS_COMPLETED && !item.placeholderUser;
    },
    reassignedUser(item) {
      if (item.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER) {
        return item.placeholderUser;
      }
      if (item.status === PLACEHOLDER_STATUS_COMPLETED) {
        return item.reassignToUser;
      }

      return {};
    },
    onPrevPage() {
      this.cursor = {
        before: this.sourceUsers.pageInfo.startCursor,
        after: null,
      };
    },

    onNextPage() {
      this.cursor = {
        after: this.sourceUsers.pageInfo.endCursor,
        before: null,
      };
    },

    onConfirm(item) {
      this.$emit('confirm', item);
    },

    formatDate(dateString) {
      return localeDateFormat.asDateTime.format(new Date(dateString));
    },
  },
  placeholderUsersHelpPath: helpPagePath('user/project/import/_index', {
    anchor: 'placeholder-users',
  }),
};
</script>

<template>
  <div>
    <gl-table :items="nodes" :fields="fields" :busy="isLoading" show-empty stacked="md">
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #empty>
        <!-- EmptyResult shows minimum length message when searchMinimumLength is set,
             otherwise shows generic search message -->
        <empty-result type="search" :search-minimum-length="isSearchQueryTooShort ? 3 : null" />
      </template>

      <template #cell(user)="{ item }">
        <gl-avatar-labeled
          v-if="item.placeholderUser"
          :size="32"
          :src="item.placeholderUser.avatarUrl"
          :label="item.placeholderUser.name"
          :sub-label="`@${item.placeholderUser.username}`"
        />
        <span v-else-if="isPlaceholderUserDeleted(item)">{{
          s__('UserMapping|Placeholder deleted')
        }}</span>
      </template>

      <template #cell(source)="{ item }">
        <p class="gl-mb-2">{{ item.sourceHostname }}</p>
        <p class="gl-mb-2">{{ item.sourceName }}</p>
        <p v-if="item.sourceUsername" class="gl-mb-2">@{{ item.sourceUsername }}</p>
        <template v-else>
          <help-popover
            :aria-label="s__('UserMapping|Full user details missing')"
            class="gl-relative gl-top-[-2px]"
          >
            <gl-sprintf
              :message="
                s__(
                  'UserMapping|Full user details could not be fetched from source instance. %{linkStart}Why are placeholder users created%{linkEnd}?',
                )
              "
            >
              <template #link="{ content }">
                <gl-link
                  class="gl-text-sm"
                  :href="$options.placeholderUsersHelpPath"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </help-popover>
          <span class="gl-font-subtle gl-italic"
            >{{ s__('UserMapping|User ID') }}: {{ item.sourceUserIdentifier }}</span
          >
        </template>
      </template>

      <template #head(createdAt)="{ label }">
        <span>{{ label }}</span>
        <help-popover :aria-label="__('Local time is displayed.')" class="gl-ml-2 gl-inline-flex">
          <gl-sprintf :message="__('Local time is displayed.')" />
        </help-popover>
      </template>
      <template #cell(createdAt)="{ item }">
        <span>
          {{ formatDate(item.createdAt) }}
        </span>
      </template>

      <template #cell(status)="{ item }">
        <gl-badge
          v-if="statusBadge(item)"
          v-gl-tooltip="statusBadge(item).tooltip"
          :variant="statusBadge(item).variant"
          data-testid="placeholder-status"
          tabindex="0"
          >{{ statusBadge(item).text }}</gl-badge
        >
      </template>

      <template #cell(actions)="{ item }">
        <template v-if="isReassignedItem(item)">
          <gl-avatar-labeled
            v-if="reassignedUser(item)"
            :size="32"
            :src="reassignedUser(item).avatarUrl"
            :label="reassignedUser(item).name"
            :sub-label="`@${reassignedUser(item).username}`"
            data-testid="placeholder-reassigned"
          />
        </template>
        <placeholder-actions v-else :key="item.id" :source-user="item" @confirm="onConfirm(item)" />
      </template>
    </gl-table>

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        @prev="onPrevPage"
        @next="onNextPage"
      />
    </div>
  </div>
</template>
