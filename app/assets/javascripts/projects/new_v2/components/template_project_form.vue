<script>
import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    MultiStepFormTemplate,
  },
  props: {
    option: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <multi-step-form-template :title="option.title" :current-step="2" :steps-total="3">
    <template #next>
      <gl-button
        category="primary"
        variant="confirm"
        :disabled="true"
        data-testid="template-project-next-button"
      >
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        data-testid="template-project-back-button"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
