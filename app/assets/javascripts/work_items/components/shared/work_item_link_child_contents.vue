<script>
import {
  GlLabel,
  GlLink,
  GlIcon,
  GlButton,
  GlAvatarsInline,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { isScopedLabel } from '~/lib/utils/common_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import UserLinkWithTooltip from '~/vue_shared/components/user_link_with_tooltip.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/shared/work_item_link_child_metadata.vue';
import RichTimestampTooltip from '../rich_timestamp_tooltip.vue';
import WorkItemTypeIcon from '../work_item_type_icon.vue';
import WorkItemStateBadge from '../work_item_state_badge.vue';
import {
  canRouterNav,
  findLinkedItemsWidget,
  findStatusWidget,
  getDisplayReference,
} from '../../utils';
import {
  STATE_OPEN,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
} from '../../constants';
import WorkItemRelationshipIcons from './work_item_relationship_icons.vue';

export default {
  i18n: {
    confidential: __('Confidential'),
    created: __('Created'),
    closed: __('Closed'),
    remove: s__('WorkItem|Remove'),
    assignee: s__('WorkItem|Assignee'),
  },
  components: {
    GlLabel,
    GlLink,
    GlIcon,
    GlButton,
    GlAvatarsInline,
    GlTooltip,
    RichTimestampTooltip,
    WorkItemLinkChildMetadata,
    WorkItemTypeIcon,
    WorkItemStateBadge,
    WorkItemRelationshipIcons,
    UserLinkWithTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    preventRouterNav: {
      from: INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
      default: false,
    },
    isGroup: {},
  },
  props: {
    childItem: {
      type: Object,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    showWeight: {
      type: Boolean,
      required: false,
      default: true,
    },
    contextualViewEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    labels() {
      return this.metadataWidgets[WIDGET_TYPE_LABELS]?.labels?.nodes || [];
    },
    metadataWidgets() {
      return this.childItem.widgets?.reduce((metadataWidgets, widget) => {
        if (widget.type) {
          // eslint-disable-next-line no-param-reassign
          metadataWidgets[widget.type] = widget;
        }
        return metadataWidgets;
      }, {});
    },
    assignees() {
      return this.metadataWidgets[WIDGET_TYPE_ASSIGNEES]?.assignees?.nodes || [];
    },
    assigneesCollapsedTooltip() {
      if (this.assignees.length > 2) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.assignees.length - 2,
        });
      }
      return '';
    },
    allowsScopedLabels() {
      return this.metadataWidgets[WIDGET_TYPE_LABELS]?.allowsScopedLabels;
    },
    isChildItemOpen() {
      return this.childItem.state === STATE_OPEN;
    },
    childItemType() {
      return this.childItem.workItemType.name;
    },
    childItemIid() {
      return this.childItem.iid;
    },
    childItemWebUrl() {
      return this.childItem.webUrl;
    },
    childItemFullPath() {
      return this.childItem.namespace?.fullPath;
    },
    stateTimestamp() {
      return this.isChildItemOpen ? this.childItem.createdAt : this.childItem.closedAt;
    },
    stateTimestampTypeText() {
      return this.isChildItemOpen ? this.$options.i18n.created : this.$options.i18n.closed;
    },
    childItemTypeIconVariant() {
      return this.isChildItemOpen ? 'default' : 'subtle';
    },
    displayLabels() {
      return this.showLabels && this.labels.length;
    },
    workItemStatus() {
      return findStatusWidget(this.childItem)?.status?.name;
    },
    showState() {
      return this.glFeatures.workItemStatusFeatureFlag
        ? !this.workItemStatus || !this.isChildItemOpen
        : true;
    },
    displayReference() {
      return getDisplayReference(this.workItemFullPath, this.childItem.reference);
    },
    linkedItemsWidget() {
      return findLinkedItemsWidget(this.childItem);
    },
    blockingCount() {
      return this.linkedItemsWidget?.blockingCount || 0;
    },
    blockedByCount() {
      return this.linkedItemsWidget?.blockedByCount || 0;
    },
    hasBlockingRelationships() {
      return this.blockingCount > 0 || this.blockedByCount > 0;
    },
    issueAsWorkItem() {
      return !this.isGroup && this.glFeatures.workItemViewForIssues;
    },
    childItemUniqueId() {
      return `listItem-${this.childItemFullPath}/${getIdFromGraphQLId(this.childItem.id)}`;
    },
  },
  methods: {
    showScopedLabel(label) {
      return isScopedLabel(label) && this.allowsScopedLabels;
    },
    handleItemClick(e) {
      const workItem = this.childItem;
      if (e.metaKey || e.ctrlKey || e.shiftKey) {
        return;
      }
      const shouldDefaultNavigate =
        this.preventRouterNav ||
        !canRouterNav({
          fullPath: this.workItemFullPath,
          webUrl: workItem.webUrl,
          isGroup: this.isGroup,
          issueAsWorkItem: this.issueAsWorkItem,
        });
      const hasListRoute = this.$router.getRoutes().some((route) => route.name === 'workItem');
      if (shouldDefaultNavigate || !hasListRoute) {
        this.$emit('click', e);
      } else {
        e.preventDefault();
        this.$router.push({
          name: 'workItem',
          params: {
            iid: workItem.iid,
          },
        });
      }
    },
  },
};
</script>

<template>
  <div
    data-testid="links-child"
    class="item-body work-item-link-child gl-relative gl-flex gl-min-w-0 gl-grow gl-gap-3 gl-hyphens-auto gl-break-words gl-rounded-base gl-p-3"
    @click="handleItemClick"
  >
    <a
      v-if="contextualViewEnabled"
      :href="childItemWebUrl"
      class="!gl-absolute gl-left-0 gl-top-0 !gl-z-1 !gl-flex gl-h-full gl-w-full"
      data-testid="issuable-card-link-overlay"
      :aria-label="__('Work item')"
    ></a>
    <div ref="stateIcon" class="gl-z-2 gl-cursor-help">
      <work-item-type-icon
        :icon-variant="childItemTypeIconVariant"
        :work-item-type="childItemType"
      />
      <gl-tooltip :target="() => $refs.stateIcon">
        {{ childItemType }}
      </gl-tooltip>
    </div>
    <div
      class="gl-flex gl-min-w-0 gl-grow gl-flex-col gl-flex-wrap"
      :class="{
        'issue-clickable': contextualViewEnabled,
      }"
    >
      <div class="gl-mb-2 gl-min-w-0 gl-justify-between gl-gap-3 sm:gl-flex">
        <div class="item-title gl-mb-2 gl-min-w-0 sm:gl-mb-0">
          <span v-if="childItem.confidential">
            <gl-icon
              v-gl-tooltip.top
              name="eye-slash"
              data-testid="confidential-icon"
              :aria-label="$options.i18n.confidential"
              :title="$options.i18n.confidential"
              variant="warning"
            />
          </span>
          <gl-link
            :id="childItemUniqueId"
            :href="childItemWebUrl"
            :class="{ '!gl-text-subtle': !isChildItemOpen }"
            class="gl-hyphens-auto gl-break-words gl-font-semibold"
            @mouseover="$emit('mouseover')"
            @mouseout="$emit('mouseout')"
          >
            {{ childItem.title }}
          </gl-link>
        </div>
        <div
          class="gl-flex gl-shrink-0 gl-flex-row-reverse gl-items-center gl-justify-end gl-gap-3 sm:gl-flex-row"
        >
          <gl-avatars-inline
            v-if="assignees.length"
            :avatars="assignees"
            collapsed
            :max-visible="2"
            :avatar-size="16"
            badge-tooltip-prop="name"
            :badge-sr-only-text="assigneesCollapsedTooltip"
          >
            <template #avatar="{ avatar }">
              <user-link-with-tooltip :label="$options.i18n.assignee" :avatar="avatar" />
            </template>
          </gl-avatars-inline>
          <work-item-relationship-icons
            v-if="isChildItemOpen && hasBlockingRelationships"
            :work-item-type="childItemType"
            :work-item-full-path="childItemFullPath"
            :work-item-iid="childItemIid"
            :work-item-web-url="childItemWebUrl"
            :blocking-count="blockingCount"
            :blocked-by-count="blockedByCount"
          />
          <slot name="child-contents"></slot>
          <span
            v-if="showState"
            :id="`statusIcon-${childItem.id}`"
            class="gl-cursor-help"
            data-testid="item-status-icon"
          >
            <work-item-state-badge :work-item-state="childItem.state" :show-icon="false" />
          </span>
          <rich-timestamp-tooltip
            :target="`statusIcon-${childItem.id}`"
            :raw-timestamp="stateTimestamp"
            :timestamp-type-text="stateTimestampTypeText"
          />
        </div>
      </div>
      <work-item-link-child-metadata
        :reference="displayReference"
        :is-child-item-open="isChildItemOpen"
        :metadata-widgets="metadataWidgets"
        :show-weight="showWeight"
        :work-item-type="childItemType"
        class="ml-xl-0"
      />
      <div v-if="displayLabels" class="gl-flex gl-flex-wrap">
        <gl-label
          v-for="label in labels"
          :key="label.id"
          :title="label.title"
          :background-color="label.color"
          :description="label.description"
          :scoped="showScopedLabel(label)"
          class="gl-mb-auto gl-mr-2 gl-mt-2"
          tooltip-placement="top"
          @click.stop
        />
      </div>
    </div>
    <div v-if="canUpdate">
      <gl-button
        v-gl-tooltip
        class="gl-relative gl-z-2 -gl-mr-2 -gl-mt-1"
        category="tertiary"
        size="small"
        icon="close"
        :aria-label="$options.i18n.remove"
        :title="$options.i18n.remove"
        data-testid="remove-work-item-link"
        @click.stop="$emit('removeChild', childItem)"
      />
    </div>
  </div>
</template>
