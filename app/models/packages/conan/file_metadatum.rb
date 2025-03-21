# frozen_string_literal: true

class Packages::Conan::FileMetadatum < ApplicationRecord
  ignore_column :conan_package_reference, remove_with: '18.0', remove_after: '2025-04-17'

  belongs_to :package_file, inverse_of: :conan_file_metadatum
  belongs_to :recipe_revision, inverse_of: :file_metadata, class_name: 'Packages::Conan::RecipeRevision'
  belongs_to :package_revision, inverse_of: :file_metadata, class_name: 'Packages::Conan::PackageRevision'
  belongs_to :package_reference, inverse_of: :file_metadata, class_name: 'Packages::Conan::PackageReference'

  DEFAULT_REVISION = '0'

  validates :package_file, presence: true
  validates :package_reference, absence: true, if: :recipe_file?
  validates :package_reference, presence: true, if: :package_file?
  validate :conan_package_type
  # package_revision is not supported yet
  validates :package_revision, absence: true

  enum conan_file_type: { recipe_file: 1, package_file: 2 }

  RECIPE_FILES = ::Gitlab::Regex::Packages::CONAN_RECIPE_FILES
  PACKAGE_FILES = ::Gitlab::Regex::Packages::CONAN_PACKAGE_FILES
  PACKAGE_BINARY = 'conan_package.tgz'
  CONAN_MANIFEST = 'conanmanifest.txt'
  CONANINFO_TXT = 'conaninfo.txt'

  def recipe_revision_value
    recipe_revision&.revision || DEFAULT_REVISION
  end

  def package_revision_value
    return unless package_file?

    DEFAULT_REVISION
  end

  def package_reference_value
    package_reference&.reference
  end

  private

  def conan_package_type
    unless package_file&.package&.conan?
      errors.add(:base, _('Package type must be Conan'))
    end
  end
end
