<script>
import {
  GlButton,
  GlFormCheckbox,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import { visitUrl, queryToObject } from '~/lib/utils/url_utility';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import RefSelector from '~/ref/components/ref_selector.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import createPipelineScheduleMutation from '../graphql/mutations/create_pipeline_schedule.mutation.graphql';
import updatePipelineScheduleMutation from '../graphql/mutations/update_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineVariablesFormGroup from './pipeline_variables_form_group.vue';

const scheduleId = queryToObject(window.location.search).id;

const trackingMixin = InternalEvents.mixin();
const EVENT_NAME = 'modify_inputs_on_pipeline_schedule_page';
const EDIT_EVENT_LABEL = 'edit_pipeline_schedule';
const NEW_EVENT_LABEL = 'new_pipeline_schedule';
const EVENT_PROPERTY = 'form_submission';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    IntervalPatternInput,
    PipelineInputsForm,
    PipelineVariablesFormGroup,
    RefSelector,
    TimezoneDropdown,
  },
  mixins: [trackingMixin],
  inject: [
    'projectPath',
    'projectId',
    'defaultBranch',
    'dailyLimit',
    'settingsLink',
    'schedulesPath',
  ],
  props: {
    timezoneData: {
      type: Array,
      required: true,
    },
    refParam: {
      type: String,
      required: false,
      default: '',
    },
    editing: {
      type: Boolean,
      required: true,
    },
    canSetPipelineVariables: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {
    schedule: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ids: scheduleId,
        };
      },
      update(data) {
        return data.project?.pipelineSchedules?.nodes[0] || {};
      },
      result({ data }) {
        if (data) {
          const {
            project: {
              pipelineSchedules: { nodes },
            },
          } = data;

          const schedule = nodes[0];
          const variables = schedule.variables?.nodes || [];

          this.description = schedule.description;
          this.cron = schedule.cron;
          this.cronTimezone = schedule.cronTimezone;
          this.savedInputs = schedule.inputs?.nodes || [];
          this.scheduleRef = schedule.ref || this.defaultBranch;
          this.variables = variables.map((variable) => {
            return {
              id: variable.id,
              variableType: variable.variableType,
              key: variable.key,
              value: variable.value,
              destroy: false,
            };
          });
          this.activated = schedule.active;
        }
      },
      skip() {
        return !this.editing;
      },
      error() {
        createAlert({ message: this.$options.i18n.scheduleFetchError });
      },
    },
  },
  data() {
    return {
      activated: true,
      cron: '',
      cronTimezone: '',
      description: '',
      pipelineInputs: [],
      savedInputs: [],
      schedule: {},
      scheduleRef: this.defaultBranch,
      updatedVariables: [],
      variables: [],
      inputsMetadata: {
        totalAvailable: 0,
        totalModified: 0,
        newlyModified: 0,
      },
    };
  },
  i18n: {
    activated: __('Activated'),
    cronTimezoneText: s__('PipelineSchedules|Cron timezone'),
    description: s__('PipelineSchedules|Description'),
    shortDescriptionPipeline: s__(
      'PipelineSchedules|Provide a short description for this pipeline',
    ),
    saveScheduleBtnText: s__('PipelineSchedules|Save changes'),
    createScheduleBtnText: s__('PipelineSchedules|Create pipeline schedule'),
    cancel: __('Cancel'),
    targetBranchTag: __('Select target branch or tag'),
    intervalPattern: s__('PipelineSchedules|Interval Pattern'),

    scheduleCreateError: s__(
      'PipelineSchedules|An error occurred while creating the pipeline schedule.',
    ),
    scheduleUpdateError: s__(
      'PipelineSchedules|An error occurred while updating the pipeline schedule.',
    ),
    scheduleFetchError: s__(
      'PipelineSchedules|An error occurred while trying to fetch the pipeline schedule.',
    ),
  },
  computed: {
    dropdownTranslations() {
      return {
        dropdownHeader: this.$options.i18n.targetBranchTag,
      };
    },
    getEnabledRefTypes() {
      return [REF_TYPE_BRANCHES, REF_TYPE_TAGS];
    },
    filledVariables() {
      return this.updatedVariables.filter((variable) => variable.key !== '' && !variable.empty);
    },
    preparedVariablesUpdate() {
      return this.filledVariables.map((variable) => {
        return {
          id: variable.id,
          key: variable.key,
          value: variable.value,
          variableType: variable.variableType,
          destroy: variable.destroy,
        };
      });
    },
    preparedVariablesCreate() {
      const vars = this.updatedVariables.filter((variable) => variable.key !== '');

      return vars.map((variable) => {
        return {
          key: variable.key,
          value: variable.value,
          variableType: variable.variableType,
        };
      });
    },
    loading() {
      return this.$apollo.queries.schedule.loading;
    },
    buttonText() {
      return this.editing
        ? this.$options.i18n.saveScheduleBtnText
        : this.$options.i18n.createScheduleBtnText;
    },
  },
  methods: {
    async createPipelineSchedule() {
      try {
        const {
          data: {
            pipelineScheduleCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: createPipelineScheduleMutation,
          variables: {
            input: {
              description: this.description,
              cron: this.cron,
              cronTimezone: this.cronTimezone,
              ref: this.scheduleRef,
              variables: this.preparedVariablesCreate,
              active: this.activated,
              projectPath: this.projectPath,
              inputs: this.pipelineInputs,
            },
          },
        });

        if (errors.length > 0) {
          createAlert({ message: errors[0] });
        } else {
          this.trackPipelineInputsModification();
          visitUrl(this.schedulesPath);
        }
      } catch {
        createAlert({ message: this.$options.i18n.scheduleCreateError });
      }
    },
    async updatePipelineSchedule() {
      try {
        const {
          data: {
            pipelineScheduleUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updatePipelineScheduleMutation,
          variables: {
            input: {
              id: this.schedule.id,
              description: this.description,
              cron: this.cron,
              cronTimezone: this.cronTimezone,
              ref: this.scheduleRef,
              variables: this.preparedVariablesUpdate,
              active: this.activated,
              inputs: this.pipelineInputs,
            },
          },
        });

        if (errors.length > 0) {
          createAlert({ message: errors[0] });
        } else {
          this.trackPipelineInputsModification();
          visitUrl(this.schedulesPath);
        }
      } catch {
        createAlert({ message: this.$options.i18n.scheduleUpdateError });
      }
    },
    scheduleHandler() {
      if (this.editing) {
        this.updatePipelineSchedule();
      } else {
        this.createPipelineSchedule();
      }
    },
    setCronValue(cron) {
      this.cron = cron;
    },
    setTimezone(timezone) {
      this.cronTimezone = timezone.identifier || '';
    },
    trackPipelineInputsModification() {
      this.trackEvent(EVENT_NAME, {
        label: this.editing ? EDIT_EVENT_LABEL : NEW_EVENT_LABEL,
        property: EVENT_PROPERTY,
        value: this.inputsMetadata.newlyModified,
        total_modified: this.inputsMetadata.totalModified,
        total_inputs: this.inputsMetadata.totalAvailable,
      });
    },
    handleInputsMetadataUpdate(data) {
      if (!data) return;
      this.inputsMetadata = {
        ...this.inputsMetadata,
        ...data,
      };
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading && editing" size="lg" />
  <gl-form v-else @submit.prevent="scheduleHandler">
    <!--Description-->
    <gl-form-group
      :label="$options.i18n.description"
      label-for="schedule-description"
      class="lg:gl-w-2/3"
    >
      <gl-form-input
        id="schedule-description"
        v-model="description"
        type="text"
        :placeholder="$options.i18n.shortDescriptionPipeline"
        data-testid="schedule-description"
        required
      />
    </gl-form-group>
    <!--Timezone-->
    <gl-form-group
      :label="$options.i18n.cronTimezoneText"
      label-for="user_timezone"
      class="lg:gl-w-2/3"
    >
      <timezone-dropdown
        id="schedule-timezone"
        input-id="user_timezone"
        :value="cronTimezone"
        :timezone-data="timezoneData"
        name="schedule-timezone"
        required
        @input="setTimezone"
      />
    </gl-form-group>
    <!--Interval Pattern-->
    <gl-form-group
      :label="$options.i18n.intervalPattern"
      label-for="schedule-interval"
      class="lg:gl-w-2/3"
    >
      <interval-pattern-input
        id="schedule-interval"
        :initial-cron-interval="cron"
        :daily-limit="dailyLimit"
        :send-native-errors="false"
        @cronValue="setCronValue"
      />
    </gl-form-group>
    <!--Branch/Tag Selector-->
    <gl-form-group
      :label="$options.i18n.targetBranchTag"
      label-for="schedule-target-branch-tag"
      class="lg:gl-w-2/3"
    >
      <ref-selector
        id="schedule-target-branch-tag"
        v-model="scheduleRef"
        :enabled-ref-types="getEnabledRefTypes"
        :project-id="projectId"
        :value="scheduleRef"
        :use-symbolic-ref-names="true"
        :translations="dropdownTranslations"
        class="gl-w-full"
      />
    </gl-form-group>
    <!--Pipeline inputs-->
    <pipeline-inputs-form
      :saved-inputs="savedInputs"
      :query-ref="scheduleRef"
      :empty-selection-text="
        s__('PipelineSchedules|Select inputs to create a new scheduled pipeline.')
      "
      class="gl-mb-6"
      @update-inputs="pipelineInputs = $event"
      @update-inputs-metadata="handleInputsMetadataUpdate"
    />
    <!--Variable List-->
    <pipeline-variables-form-group
      v-if="canSetPipelineVariables"
      :initial-variables="variables"
      :editing="editing"
      @update-variables="updatedVariables = $event"
    />

    <!--Activated-->
    <gl-form-checkbox id="schedule-active" v-model="activated" class="gl-mb-3">
      {{ $options.i18n.activated }}
    </gl-form-checkbox>
    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        data-testid="schedule-submit-button"
        class="gl-w-full sm:gl-w-auto"
      >
        {{ buttonText }}
      </gl-button>
      <gl-button
        :href="schedulesPath"
        data-testid="schedule-cancel-button"
        class="gl-w-full sm:gl-w-auto"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>
