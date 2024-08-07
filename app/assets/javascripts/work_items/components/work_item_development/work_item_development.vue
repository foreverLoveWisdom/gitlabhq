<script>
import { GlLoadingIcon, GlIcon, GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { s__, __ } from '~/locale';

import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { sprintfWorkItem, WIDGET_TYPE_DEVELOPMENT, STATE_OPEN } from '~/work_items/constants';

import WorkItemDevelopmentRelationshipList from './work_item_development_relationship_list.vue';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
    GlButton,
    WorkItemDevelopmentRelationshipList,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItem || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        this.$emit('error', this.$options.i18n.fetchError);
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
  },
  data() {
    return {
      error: '',
    };
  },
  computed: {
    workItemState() {
      return this.workItem?.state;
    },
    workItemTypeName() {
      return this.workItem?.workItemType?.name;
    },
    workItemDevelopment() {
      return this.workItem?.widgets?.find(({ type }) => type === WIDGET_TYPE_DEVELOPMENT);
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    willAutoCloseByMergeRequest() {
      return this.workItemDevelopment?.willAutoCloseByMergeRequest;
    },
    linkedMergeRequests() {
      return this.workItemDevelopment?.closingMergeRequests?.nodes || [];
    },
    shouldShowDevWidget() {
      return this.glFeatures.workItemsAlpha ? true : !this.isEmptyRelatedWorkItems;
    },
    isEmptyRelatedWorkItems() {
      return !this.error && this.linkedMergeRequests.length === 0;
    },
    showAutoCloseInformation() {
      return (
        this.linkedMergeRequests.length > 0 && this.willAutoCloseByMergeRequest && !this.isLoading
      );
    },
    openStateText() {
      return this.linkedMergeRequests.length > 1
        ? sprintfWorkItem(this.$options.i18n.openStateText, this.workItemTypeName)
        : sprintfWorkItem(
            this.$options.i18n.openStateWithOneMergeRequestText,
            this.workItemTypeName,
          );
    },
    closedStateText() {
      return sprintfWorkItem(this.$options.i18n.closedStateText, this.workItemTypeName);
    },
    tooltipText() {
      return this.workItemState === STATE_OPEN ? this.openStateText : this.closedStateText;
    },
  },
  createMRModalId: 'create-merge-request-modal',
  i18n: {
    development: s__('WorkItem|Development'),
    fetchError: s__('WorkItem|Something went wrong when fetching items. Please refresh this page.'),
    createMergeRequest: __('Create merge request'),
    createBranch: __('Create branch'),
    openStateWithOneMergeRequestText: s__(
      'WorkItem|This %{workItemType} will be closed when the following is merged.',
    ),
    openStateText: s__(
      'WorkItem|This %{workItemType} will be closed when any of the following is merged.',
    ),
    closedStateText: s__(
      'WorkItem|The %{workItemType} was closed automatically when a branch was merged.',
    ),
  },
};
</script>
<template>
  <div v-if="shouldShowDevWidget">
    <div class="gl-flex gl-items-center gl-gap-3 gl-justify-between">
      <h3
        class="gl-mb-0! gl-heading-5 gl-flex gl-items-center gl-gap-2"
        data-testid="dev-widget-label"
      >
        {{ $options.i18n.development }}
        <gl-button
          v-if="showAutoCloseInformation"
          v-gl-tooltip
          class="hover:!gl-bg-transparent !gl-p-0"
          category="tertiary"
          :title="tooltipText"
          :aria-label="tooltipText"
          data-testid="more-information"
        >
          <gl-icon name="information-o" class="!gl-text-blue-500" />
        </gl-button>
      </h3>
      <gl-button
        v-if="canUpdate"
        v-gl-modal="$options.createMRModalId"
        v-gl-tooltip.top
        category="tertiary"
        size="small"
        data-testid="add-item"
        :title="__('Add branch or merge request')"
        :aria-label="__('Add branch or merge request')"
      >
        <gl-icon name="plus" class="gl-text-gray-900!" />
      </gl-button>
    </div>
    <gl-loading-icon v-if="isLoading" class="gl-my-2" />
    <template v-else-if="isEmptyRelatedWorkItems">
      <span v-if="!canUpdate" class="gl-text-secondary">{{ __('None') }}</span>
      <template v-else>
        <gl-button category="secondary" size="small" data-testid="create-mr-button">{{
          $options.i18n.createMergeRequest
        }}</gl-button>
        <gl-button category="tertiary" size="small" data-testid="create-branch-button">{{
          $options.i18n.createBranch
        }}</gl-button>
      </template>
    </template>
    <work-item-development-relationship-list v-else :work-item-dev-widget="workItemDevelopment" />
  </div>
</template>
