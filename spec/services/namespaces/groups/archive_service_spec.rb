# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::ArchiveService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  subject(:service_response) { described_class.new(group, user).execute }

  context 'when the group is already archived' do
    before do
      group.namespace_settings.update!(archived: true)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("Group is already archived!")
    end
  end

  context 'when ancestor group is already archived' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_owner(user)
      parent.update!(archived: true)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message)
        .to eq("Cannot archive group since one of the ancestor groups is already archived!")
    end
  end

  context 'when the group is not archived' do
    before do
      group.namespace_settings.update!(archived: false)
    end

    context 'when archiving succeeds' do
      it 'calls archive on the group' do
        expect(group).to receive(:archive).and_return(true)
        service_response
      end

      it 'returns a success response with the group' do
        expect(service_response).to be_success
      end
    end

    context 'when archiving fails' do
      before do
        allow(group).to receive(:archive).and_return(false)
      end

      it 'returns an error response with the appropriate message' do
        response = service_response
        expect(response).to be_error
        expect(response.message).to eq("Failed to archive group!")
      end
    end
  end

  describe "#error_response" do
    subject(:error_response_result) { described_class.new(group, user).send(:error_response, "Test error message") }

    it "returns a service response error" do
      expect(error_response_result).to be_error
      expect(error_response_result.message).to eq("Test error message")
    end
  end
end
