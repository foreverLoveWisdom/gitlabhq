import applyGitLabUIConfig from '@gitlab/ui/dist/config';
import { __, s__, n__ } from '~/locale';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';

applyGitLabUIConfig({
  translations: {
    'CloseButton.title': __('Close'),
    'DuoChatContextItemPopover.DisabledReason': __('This item is disabled'),
    'GlAlert.closeButtonTitle': __('Dismiss'),
    'GlBanner.closeButtonTitle': __('Dismiss'),
    'GlBreadcrumb.showMoreLabel': __('Show more breadcrumbs'),
    'GlBroadcastMessage.closeButtonTitle': __('Dismiss'),
    'GlDuoChatContextItemMenu.emptyStateMessage': s__('DuoChat|No results found'),
    'GlDuoChatContextItemMenu.loadingMessage': __('Loading...'),
    'GlDuoChatContextItemMenu.searchInputPlaceholder': s__('DuoChat|Search %{categoryLabel}...'),
    'GlDuoChatContextItemMenu.selectedContextItemsTitle': s__('DuoChat|Included references'),
    'GlDuoWorkflowPanel.collapseButtonTitle': s__('GitLabDuo|Collapse'),
    'GlDuoWorkflowPanel.expandButtonTitle': s__('GitLabDuo|Expand'),
    'GlDuoWorkflowPrompt.cancelButtonText': s__('GitLabDuo|Cancel'),
    'GlDuoWorkflowPrompt.confirmButtonText': s__('GitLabDuo|Generate plan'),
    'GlDuoWorkflowPrompt.imageDescription': s__(
      'GitLabDuo|It should have any tools necessary for the workflow installed.',
    ),
    'GlDuoWorkflowPrompt.imageLabel': s__('GitLabDuo|Image'),
    'GlDuoWorkflowPrompt.imageLabelDescription': s__(
      'GitLabDuo|The container image to run the workflow in.',
    ),
    'GlDuoWorkflowPrompt.promptDescription': s__(
      'GitLabDuo|Be specific and include any requirements.',
    ),
    'GlDuoWorkflowPrompt.promptLabel': __('Description'),
    'GlDuoWorkflowPrompt.promptLabelDescription': s__(
      'GitLabDuo|What would you like to do and how.',
    ),
    'GlDuoWorkflowPrompt.title': s__('GitLabDuo|Goal'),
    'GlModal.closeButtonTitle': __('Close'),
    'GlToken.closeButtonTitle': __('Remove'),
    'GlSearchBoxByType.input.placeholder': __('Search'),
    'GlSearchBoxByType.clearButtonTitle': __('Clear'),
    'GlSorting.sortAscending': __('Sort direction: Ascending'),
    'GlSorting.sortDescending': __('Sort direction: Descending'),
    'ClearIconButton.title': __('Clear'),
    'GlKeysetPagination.prevText': PREV,
    'GlKeysetPagination.navigationLabel': s__('Pagination|Pagination'),
    'GlKeysetPagination.nextText': NEXT,
    'GlPagination.labelFirstPage': LABEL_FIRST_PAGE,
    'GlPagination.labelLastPage': LABEL_LAST_PAGE,
    'GlPagination.labelNextPage': LABEL_NEXT_PAGE,
    'GlPagination.labelPage': s__('Pagination|Go to page %{page}'),
    'GlPagination.labelPrevPage': LABEL_PREV_PAGE,
    'GlPagination.nextText': NEXT,
    'GlPagination.prevText': PREV,
    'GlCollapsibleListbox.srOnlyResultsLabel': (count) => n__('%d result', '%d results', count),
  },
});
