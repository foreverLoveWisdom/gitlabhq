<script>
import { GlIcon, GlLink, GlSprintf, GlExperimentBadge } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { glqlWorkItemsFeatureFlagEnabled } from '~/glql/utils/feature_flags';

export default {
  name: 'GlqlFooter',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlExperimentBadge,
  },
  docsPath: `${helpPagePath('user/glql/_index')}#glql-views`,
  computed: {
    featureFlagEnabled() {
      return glqlWorkItemsFeatureFlagEnabled();
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-items-center gl-gap-1 gl-text-sm gl-text-subtle" data-testid="footer">
    <gl-icon class="gl-mb-1 gl-mr-1" :size="12" name="tanuki" />
    <gl-sprintf :message="__('%{linkStart}View%{linkEnd} powered by GLQL')">
      <template #link="{ content }">
        <gl-link
          :href="$options.docsPath"
          target="_blank"
          data-event-tracking="click_glql_info_link"
          >{{ content }}</gl-link
        >
      </template>
    </gl-sprintf>
    <gl-experiment-badge v-if="featureFlagEnabled" type="experiment" class="!gl-mx-2" />
  </div>
</template>
