# frozen_string_literal: true

module Ci
  module PartitioningTesting
    module SchemaHelpers
      module_function

      def with_routing_tables
        previous_table_name = CommitStatus.table_name
        CommitStatus.table_name = :p_ci_builds
        CommitStatus.descendants.each(&:reset_table_name)

        yield

      ensure
        CommitStatus.table_name = previous_table_name
        CommitStatus.descendants.each(&:reset_table_name)
      end

      def setup(connection: Ci::ApplicationRecord.connection)
        each_partitionable_table do |table_name|
          create_test_partition("p_#{table_name}", connection: connection)
        end
        ensure_builds_id_uniquness(connection: connection)
      end

      def teardown(connection: Ci::ApplicationRecord.connection)
        each_partitionable_table do |table_name|
          drop_test_partition("p_#{table_name}", connection: connection)
        end
      end

      def each_partitionable_table
        ::Ci::Partitionable::Testing::PARTITIONABLE_MODELS.each do |klass|
          model = klass.safe_constantize
          table_name = model.table_name.delete_prefix('p_')

          yield(table_name)

          model.reset_column_information if model.connected?
        end
      end

      def create_test_partition(table_name, connection:)
        return unless table_available?(table_name, connection: connection)

        drop_test_partition(table_name, connection: connection)

        connection.execute(<<~SQL.squish)
          CREATE TABLE #{full_partition_name(table_name)}
            PARTITION OF #{table_name}
            FOR VALUES IN (#{PartitioningTesting::PartitionIdentifiers.ci_testing_partition_id});
        SQL
      end

      def drop_test_partition(table_name, connection:)
        return unless table_available?(table_name, connection: connection)
        return unless connection.table_exists?(full_partition_name(table_name))

        connection.execute(<<~SQL.squish)
          ALTER TABLE #{table_name} DETACH PARTITION  #{full_partition_name(table_name)};
          DROP TABLE IF EXISTS #{full_partition_name(table_name)};
        SQL
      end

      # This can be removed after https://gitlab.com/gitlab-org/gitlab/-/issues/421173
      # is implemented
      def ensure_builds_id_uniquness(connection:)
        connection.execute(<<~SQL.squish)
          CREATE TRIGGER assign_p_ci_builds_id_trigger
            BEFORE INSERT ON #{full_partition_name('ci_builds')}
            FOR EACH ROW EXECUTE FUNCTION assign_p_ci_builds_id_value();
        SQL
      end

      def table_available?(table_name, connection:)
        connection.table_exists?(table_name) &&
          connection.column_exists?(table_name, :partition_id)
      end

      def full_partition_name(table_name)
        [
          Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA,
          '._test_gitlab_',
          table_name.delete_prefix('p_'),
          '_partition'
        ].join('')
      end
    end
  end
end
