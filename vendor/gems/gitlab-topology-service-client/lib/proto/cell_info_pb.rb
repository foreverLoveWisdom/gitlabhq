# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: proto/cell_info.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("proto/cell_info.proto", :syntax => :proto3) do
    add_message "gitlab.cells.topology_service.CellInfo" do
      optional :id, :int64, 1
      optional :name, :string, 2
      optional :address, :string, 3
      optional :session_prefix, :string, 4
    end
    add_message "gitlab.cells.topology_service.GetCellsRequest" do
    end
    add_message "gitlab.cells.topology_service.GetCellsResponse" do
      repeated :cells, :message, 1, "gitlab.cells.topology_service.CellInfo"
    end
  end
end

module Gitlab
  module Cells
    module TopologyService
      CellInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.CellInfo").msgclass
      GetCellsRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.GetCellsRequest").msgclass
      GetCellsResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.GetCellsResponse").msgclass
    end
  end
end
