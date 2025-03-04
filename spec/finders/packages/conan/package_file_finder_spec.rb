# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Conan::PackageFileFinder do
  let_it_be(:package) { create(:conan_package) }
  let_it_be(:package_file) { package.package_files.first }

  let(:package_file_name) { package_file.file_name }
  let(:params) { {} }

  shared_examples 'package file finder examples' do
    it { is_expected.to eq(package_file) }

    context 'with conan_file_type' do
      # conan packages contain a conanmanifest.txt file for both conan_file_types
      let(:package_file_name) { 'conanmanifest.txt' }
      let(:params) { { conan_file_type: :recipe_file } }

      it { expect(subject.conan_file_type).to eq('recipe_file') }
    end

    context 'with conan_package_reference' do
      let_it_be(:package_file) { package.package_files.find_by(file_name: 'conaninfo.txt') }

      let(:params) do
        { conan_package_reference: package_file.conan_file_metadatum.package_reference_value }
      end

      it { expect(subject).to eq(package_file) }
    end

    context 'with file_name_like' do
      let(:package_file_name) { package_file.file_name.upcase }
      let(:params) { { with_file_name_like: true } }

      it { is_expected.to eq(package_file) }
    end

    context 'with recipe_revision' do
      let(:params) { { recipe_revision: recipe_revision_value } }

      context 'with default revision' do
        let(:recipe_revision_value) { Packages::Conan::FileMetadatum::DEFAULT_REVISION }
        let_it_be(:package_file_without_revision) do
          create(:conan_package_file, :conan_recipe_file,
            package: package, conan_recipe_revision: nil)
        end

        it 'returns package files without recipe revision' do
          expect(subject).to eq(package_file_without_revision)
        end
      end

      context 'with specific revision' do
        let(:recipe_revision_value) { package_file.conan_file_metadatum.recipe_revision_value }

        it 'returns package files with matching recipe revision' do
          expect(subject).to eq(package_file)
        end
      end
    end
  end

  shared_examples 'not returning pending_destruction package files' do
    let_it_be(:recent_package_file_pending_destruction) do
      create(:package_file, :pending_destruction, package: package, file_name: package_file.file_name)
    end

    it 'returns the correct package file' do
      # Verify the pending_destruction file is indeed the last one, as only the last file is returned
      expect(package.reload.package_files.last).to eq(recent_package_file_pending_destruction)

      expect(subject).to eq(package_file)
    end
  end

  describe '#execute' do
    subject { described_class.new(package, package_file_name, params).execute }

    it_behaves_like 'package file finder examples'

    it_behaves_like 'not returning pending_destruction package files'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect(subject).to be_nil }
    end
  end

  describe '#execute!' do
    subject { described_class.new(package, package_file_name, params).execute! }

    it_behaves_like 'package file finder examples'

    it_behaves_like 'not returning pending_destruction package files'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
