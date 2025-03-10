---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Vue.js style guide
---

## Linting

We default to [eslint-vue-plugin](https://github.com/vuejs/eslint-plugin-vue), with the `plugin:vue/recommended`.
Check the [rules](https://github.com/vuejs/eslint-plugin-vue#bulb-rules) for more documentation.

## Basic Rules

1. The service has its own file
1. The store has its own file
1. Use a function in the bundle file to instantiate the Vue component:

   ```javascript
   // bad
   class {
     init() {
       new Component({})
     }
   }

   // good
   document.addEventListener('DOMContentLoaded', () => new Vue({
     el: '#element',
     components: {
       componentName
     },
     render: createElement => createElement('component-name'),
   }));
   ```

1. Do not use a singleton for the service or the store

   ```javascript
   // bad
   class Store {
     constructor() {
       if (!this.prototype.singleton) {
         // do something
       }
     }
   }

   // good
   class Store {
     constructor() {
       // do something
     }
   }
   ```

1. Use `.vue` for Vue templates. Do not use `%template` in HAML.

1. Explicitly define data being passed into the Vue app

   ```javascript
   // bad
   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     provide: {
       ...someDataset
     },
     props: {
       ...anotherDataset
     },
     render: createElement => createElement('component-name'),
   }));

   // good
   const { foobar, barfoo } = someDataset;
   const { foo, bar } = anotherDataset;

   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     provide: {
       foobar,
       barfoo
     },
     props: {
       foo,
       bar
     },
     render: createElement => createElement('component-name'),
   }));
   ```

   We discourage the use of the spread operator in this specific case in
   order to keep our codebase explicit, discoverable, and searchable.
   This applies in any place where we would benefit from the above, such as
   when [initializing Vuex state](../vuex.md#why-not-just-spread-the-initial-state).
   The pattern above also enables us to easily parse non scalar values during
   instantiation.

   ```javascript
   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     props: {
       foo,
       bar: parseBoolean(bar)
     },
     render: createElement => createElement('component-name'),
   }));
   ```

## Naming

1. **Extensions**: Use `.vue` extension for Vue components. Do not use `.js` as file extension
   ([#34371](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34371)).
1. **Reference Naming**: Use PascalCase for their default imports:

   ```javascript
   // bad
   import cardBoard from 'cardBoard.vue'

   components: {
     cardBoard,
   };

   // good
   import CardBoard from 'cardBoard.vue'

   components: {
     CardBoard,
   };
   ```

1. **Props Naming:** Avoid using DOM component prop names.
1. **Props Naming:** Use kebab-case instead of camelCase to provide props in templates.

   ```html
   // bad
   <component class="btn">

   // good
   <component css-class="btn">

   // bad
   <component myProp="prop" />

   // good
   <component my-prop="prop" />
   ```

## Alignment

1. Follow these alignment styles for the template method:

   1. With more than one attribute, all attributes should be on a new line:

      ```html
      // bad
      <component v-if="bar"
          param="baz" />

      <button class="btn">Click me</button>

      // good
      <component
        v-if="bar"
        param="baz"
      />

      <button class="btn">
        Click me
      </button>
      ```

   1. The tag can be inline if there is only one attribute:

      ```html
      // good
        <component bar="bar" />

      // good
        <component
          bar="bar"
          />

      // bad
       <component
          bar="bar" />
      ```

## Quotes

1. Always use double quotes `"` inside templates and single quotes `'` for all other JS.

   ```javascript
   // bad
   template: `
     <button :class='style'>Button</button>
   `

   // good
   template: `
     <button :class="style">Button</button>
   `
   ```

## Props

1. Props should be declared as an object

   ```javascript
   // bad
   props: ['foo']

   // good
   props: {
     foo: {
       type: String,
       required: false,
       default: 'bar'
     }
   }
   ```

1. Required key should always be provided when declaring a prop

   ```javascript
   // bad
   props: {
     foo: {
       type: String,
     }
   }

   // good
   props: {
     foo: {
       type: String,
       required: false,
       default: 'bar'
     }
   }
   ```

1. Default key should be provided if the prop is not required.
   There are some scenarios where we need to check for the existence of the property.
   On those a default key should not be provided.

   ```javascript
   // good
   props: {
     foo: {
       type: String,
       required: false,
     }
   }

   // good
   props: {
     foo: {
       type: String,
       required: false,
       default: 'bar'
     }
   }

   // good
   props: {
     foo: {
       type: String,
       required: true
     }
   }
   ```

## Data

1. `data` method should always be a function

   ```javascript
   // bad
   data: {
     foo: 'foo'
   }

   // good
   data() {
     return {
       foo: 'foo'
     };
   }
   ```

## Directives

1. Shorthand `@` is preferable over `v-on`

   ```html
   // bad
   <component v-on:click="eventHandler"/>

   // good
   <component @click="eventHandler"/>
   ```

1. Shorthand `:` is preferable over `v-bind`

   ```html
   // bad
   <component v-bind:class="btn"/>

   // good
   <component :class="btn"/>
   ```

1. Shorthand `#` is preferable over `v-slot`

   ```html
   // bad
   <template v-slot:header></template>

   // good
   <template #header></template>
   ```

## Closing tags

1. Prefer self-closing component tags

   ```html
   // bad
   <component></component>

   // good
   <component />
   ```

## Component usage within templates

1. Prefer a component's kebab-cased name over other styles when using it in a template

   ```html
   // bad
   <MyComponent />

   // good
   <my-component />
   ```

## `<style>` tags

We don't use `<style>` tags in Vue components for a few reasons:

1. You cannot use SCSS variables and mixins or [Tailwind CSS](scss.md#tailwind-css) `@apply` directive.
1. These styles get inserted at runtime.
1. We already have a few other ways to define CSS.

Instead of using a `<style>` tag you should use [Tailwind CSS utility classes](scss.md#tailwind-css) or [page specific CSS](https://gitlab.com/groups/gitlab-org/-/epics/3694).

## Ordering

1. Tag order in `.vue` file

   ```html
   <script>
     // ...
   </script>

   <template>
     // ...
   </template>

   // We don't use `<style>` tags but there are few instances of this
   <style>
     // ...
   </style>
   ```

1. Properties in a Vue Component:
   Check [order of properties in components rule](https://github.com/vuejs/eslint-plugin-vue/blob/master/docs/rules/order-in-components.md).

## `:key`

When using `v-for` you need to provide a *unique* `:key` attribute for each item.

1. If the elements of the array being iterated have an unique `id` it is advised to use it:

   ```html
   <div
     v-for="item in items"
     :key="item.id"
   >
     <!-- content -->
   </div>
   ```

1. When the elements being iterated don't have a unique ID, you can use the array index as the `:key` attribute

   ```html
   <div
     v-for="(item, index) in items"
     :key="index"
   >
     <!-- content -->
   </div>
   ```

1. When using `v-for` with `template` and there is more than one child element, the `:key` values
   must be unique. It's advised to use `kebab-case` namespaces.

   ```html
   <template v-for="(item, index) in items">
     <span :key="`span-${index}`"></span>
     <button :key="`button-${index}`"></button>
   </template>
   ```

1. When dealing with nested `v-for` use the same guidelines as above.

   ```html
   <div
     v-for="item in items"
     :key="item.id"
   >
     <span
       v-for="element in array"
       :key="element.id"
     >
       <!-- content -->
     </span>
   </div>
   ```

Useful links:

1. [Maintaining State](https://v2.vuejs.org/v2/guide/list.html#Maintaining-State)
1. [Vue Style Guide: Keyed v-for](https://vuejs.org/v2/style-guide/#Keyed-v-for-essential)

## Vue testing

Over time, a number of programming patterns and style preferences have emerged in our efforts to
effectively test Vue components. The following guide describes some of these.
**These are not strict guidelines**, but rather a collection of suggestions and good practices that
aim to provide insight into how we write Vue tests at GitLab.

### Mounting a component

Typically, when testing a Vue component, the component should be "re-mounted" in every test block.

To achieve this:

1. Create a mutable `wrapper` variable inside the top-level `describe` block.
1. Mount the component using [`mount`](https://v1.test-utils.vuejs.org/api/#mount) or [`shallowMount`](https://v1.test-utils.vuejs.org/api/#shallowMount).
1. Reassign the resulting [`Wrapper`](https://v1.test-utils.vuejs.org/api/wrapper/#wrapper) instance to our `wrapper` variable.

Creating a global, mutable wrapper provides a number of advantages, including the ability to:

- Define common functions for finding components/DOM elements:

  ```javascript
  import MyComponent from '~/path/to/my_component.vue';
  describe('MyComponent', () => {
    let wrapper;

    // this can now be reused across tests
    const findMyComponent = wrapper.findComponent(MyComponent);
    // ...
  })
  ```

- Use a `beforeEach` block to mount the component (see
  [the `createComponent` factory](#the-createcomponent-factory) for more information).
- Automatically destroy the component after the test is run with [`enableAutoDestroy`](https://v1.test-utils.vuejs.org/api/#enableautodestroy-hook)
  set in [`shared_test_setup.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/d0bdc8370ef17891fd718a4578e41fef97cf065d/spec/frontend/__helpers__/shared_test_setup.js#L20).

#### Async child components

`shallowMount` will not create component stubs for [async child components](https://v2.vuejs.org/v2/guide/components-dynamic-async#Async-Components). In order to properly stub async child components, use the [`stubs`](https://v1.test-utils.vuejs.org/api/options.html#stubs) option. Make sure the async child component has a [`name`](https://v2.vuejs.org/v2/api/#name) option defined, otherwise your `wrapper`'s `findComponent` method may not work correctly.

#### The `createComponent` factory

To avoid duplicating our mounting logic, it's useful to define a `createComponent` factory function
that we can reuse in each test block. This is a closure which should reassign our `wrapper` variable
to the result of [`mount`](https://v1.test-utils.vuejs.org/api/#mount) and
[`shallowMount`](https://v1.test-utils.vuejs.org/api/#shallowMount):

```javascript
import MyComponent from '~/path/to/my_component.vue';
import { shallowMount } from '@vue/test-utils';

describe('MyComponent', () => {
  // Initiate the "global" wrapper variable. This will be used throughout our test:
  let wrapper;

  // Define our `createComponent` factory:
  function createComponent() {
    // Mount component and reassign `wrapper`:
    wrapper = shallowMount(MyComponent);
  }

  it('mounts', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });

  it('`isLoading` prop defaults to `false`', () => {
    createComponent();

    expect(wrapper.props('isLoading')).toBe(false);
  });
})
```

Similarly, we could further de-duplicate our test by calling `createComponent` in a `beforeEach` block:

```javascript
import MyComponent from '~/path/to/my_component.vue';
import { shallowMount } from '@vue/test-utils';

describe('MyComponent', () => {
  // Initiate the "global" wrapper variable. This will be used throughout our test
  let wrapper;

  // define our `createComponent` factory
  function createComponent() {
    // mount component and reassign `wrapper`
    wrapper = shallowMount(MyComponent);
  }

  beforeEach(() => {
    createComponent();
  });

  it('mounts', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('`isLoading` prop defaults to `false`', () => {
    expect(wrapper.props('isLoading')).toBe(false);
  });
})
```

#### `createComponent` best practices

1. Consider using a single (or a limited number of) object arguments over many arguments.
   Defining single parameters for common data like `props` is okay,
   but keep in mind our [JavaScript style guide](javascript.md#limit-number-of-parameters) and
   stay within the parameter number limit:

   ```javascript
   // bad
   function createComponent(props, stubs, mountFn, foo) { }

   // good
   function createComponent({ props, stubs, mountFn, foo } = {}) { }

   // good
   function createComponent(props = {}, { stubs, mountFn, foo } = {}) { }
   ```

1. If you require both `mount` _and_ `shallowMount` within the same set of tests, it
   can be useful define a `mountFn` parameter for the `createComponent` factory that accepts
   the mounting function (`mount` or `shallowMount`) to be used to mount the component:

   ```javascript
   import { shallowMount } from '@vue/test-utils';

   function createComponent({ mountFn = shallowMount } = {}) { }
   ```

1. Use the `mountExtended` and `shallowMountExtended` helpers to expose `wrapper.findByTestId()`:

   ```javascript
   import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
   import { SomeComponent } from 'components/some_component.vue';

   let wrapper;

   const createWrapper = () => { wrapper = shallowMountExtended(SomeComponent); };
   const someButton = () => wrapper.findByTestId('someButtonTestId');
   ```

1. Avoid using `data`, `methods`, or any other mounting option that extends component internals.

   ```javascript
   import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
   import { SomeComponent } from 'components/some_component.vue';

   let wrapper;

   // bad :( - This circumvents the actual user interaction and couples the test to component internals.
   const createWrapper = ({ data }) => {
     wrapper = shallowMountExtended(SomeComponent, {
       data
     });
   };

   // good :) - Helpers like `clickShowButton` interact with the actual I/O of the component.
   const createWrapper = () => {
     wrapper = shallowMountExtended(SomeComponent);
   };
   const clickShowButton = () => {
     wrapper.findByTestId('show').trigger('click');
   }
   ```

### Setting component state

1. Avoid using [`setProps`](https://v1.test-utils.vuejs.org/api/wrapper/#setprops) to set
   component state wherever possible. Instead, set the component's
   [`propsData`](https://v1.test-utils.vuejs.org/api/options.html#propsdata) when mounting the component:

   ```javascript
   // bad
   wrapper = shallowMount(MyComponent);
   wrapper.setProps({
     myProp: 'my cool prop'
   });

   // good
   wrapper = shallowMount({ propsData: { myProp: 'my cool prop' } });
   ```

   The exception here is when you wish to test component reactivity in some way.
   For example, you may want to test the output of a component when after a particular watcher has
   executed. Using `setProps` to test such behavior is okay.

1. Avoid using [`setData`](https://v1.test-utils.vuejs.org/api/wrapper/#setdata) which sets the
   component's internal state and circumvents testing the actual I/O of the component.
   Instead, trigger events on the component's children or other side-effects to force state changes.

### Accessing component state

1. When accessing props or attributes, prefer the `wrapper.props('myProp')` syntax over
   `wrapper.props().myProp` or `wrapper.vm.myProp`:

   ```javascript
   // good
   expect(wrapper.props().myProp).toBe(true);
   expect(wrapper.attributes().myAttr).toBe(true);

   // better
   expect(wrapper.props('myProp').toBe(true);
   expect(wrapper.attributes('myAttr')).toBe(true);
   ```

1. When asserting multiple props, check the deep equality of the `props()` object with
   [`toEqual`](https://jestjs.io/docs/expect#toequalvalue):

   ```javascript
   // good
   expect(wrapper.props('propA')).toBe('valueA');
   expect(wrapper.props('propB')).toBe('valueB');
   expect(wrapper.props('propC')).toBe('valueC');

   // better
   expect(wrapper.props()).toEqual({
     propA: 'valueA',
     propB: 'valueB',
     propC: 'valueC',
   });
   ```

1. If you are only interested in some of the props, you can use
   [`toMatchObject`](https://jestjs.io/docs/expect#tomatchobjectobject). Prefer `toMatchObject`
   over [`expect.objectContaining`](https://jestjs.io/docs/expect#expectobjectcontainingobject):

   ```javascript
   // good
   expect(wrapper.props()).toEqual(expect.objectContaining({
     propA: 'valueA',
     propB: 'valueB',
   }));

   // better
   expect(wrapper.props()).toMatchObject({
     propA: 'valueA',
     propB: 'valueB',
   });
   ```

### Testing props validation

When checking component props use `assertProps` helper. Props validation failures will be thrown as errors:

```javascript
import { assertProps } from 'helpers/assert_props'

// ...

expect(() => assertProps(SomeComponent, { invalidPropValue: '1', someOtherProp: 2 })).toThrow()
```
