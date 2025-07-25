# frozen_string_literal: true

class AddBulkImportConfigurationsOrganizationIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :bulk_import_configurations, :organization_id
  end

  def down
    remove_not_null_constraint :bulk_import_configurations, :organization_id
  end
end
