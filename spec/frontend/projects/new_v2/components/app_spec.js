import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/projects/new_v2/components/app.vue';
import CommandLine from '~/projects/new_v2/components/command_line.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('New project creation app', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        rootPath: '/',
        projectsUrl: '/dashboard/projects',
        userNamespaceId: '1',
        ...props,
      },
    });
  };

  const findMultyStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findCommandLine = () => wrapper.findComponent(CommandLine);

  it('renders a form', () => {
    createComponent();

    expect(findMultyStepForm().exists()).toBe(true);
  });

  describe('personal namespace project', () => {
    beforeEach(() => {
      createComponent();
    });

    it('starts with personal namespace when no namespaceId provided', () => {
      expect(wrapper.findByTestId('personal-namespace-button').props('selected')).toBe(true);
      expect(wrapper.findByTestId('group-namespace-button').props('selected')).toBe(false);
    });

    it('does not renders a group select', () => {
      expect(wrapper.findByTestId('group-selector').exists()).toBe(false);
    });
  });

  describe('with command line', () => {
    it('renders for a personal namespace', () => {
      createComponent();

      expect(findCommandLine().exists()).toBe(true);
    });

    it('does not renders for a group namespace', () => {
      createComponent({ namespaceId: '13' });

      expect(findCommandLine().exists()).toBe(false);
    });
  });
});
