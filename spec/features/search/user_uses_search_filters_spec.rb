# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses search filters', :js do
  let(:group) { create(:group) }
  let!(:group_project) { create(:project, group: group) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    group.add_owner(user)
    sign_in(user)
  end

  context 'when filtering by group' do
    it 'shows group projects' do
      visit search_path

      find('.js-search-group-dropdown').click

      wait_for_requests

      page.within('.search-page-form') do
        click_link(group.name)
      end

      expect(find('.js-search-group-dropdown')).to have_content(group.name)

      page.within('.project-filter') do
        find('.js-search-project-dropdown').click

        wait_for_requests

        expect(page).to have_link(group_project.full_name)
      end
    end

    context 'when the group filter is set' do
      before do
        visit search_path(search: "test", group_id: group.id, project_id: project.id)
      end

      describe 'clear filter button' do
        it 'removes Group and Project filters' do
          link = find('[data-testid="group-filter"] .js-search-clear')
          params = CGI.parse(URI.parse(link[:href]).query)

          expect(params).not_to include(:group_id, :project_id)
        end
      end
    end
  end

  context 'when filtering by project' do
    it 'shows a project' do
      visit search_path

      page.within('.project-filter') do
        find('.js-search-project-dropdown').click

        wait_for_requests

        click_link(project.full_name)
      end

      expect(find('.js-search-project-dropdown')).to have_content(project.full_name)
    end

    context 'when the project filter is set' do
      before do
        visit search_path(search: "test", project_id: project.id)
      end

      let(:query) { { project_id: project.id } }

      describe 'clear filter button' do
        it 'removes Project filters' do
          link = find('.project-filter .js-search-clear')
          params = CGI.parse(URI.parse(link[:href]).query)

          expect(params).not_to include(:project_id)
        end
      end
    end
  end
end
