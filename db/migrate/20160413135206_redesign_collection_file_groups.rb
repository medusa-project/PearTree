class RedesignCollectionFileGroups < ActiveRecord::Migration
  def change
    remove_column :collections, :medusa_metadata_file_group_id
    rename_column :collections, :medusa_data_file_group_id, :medusa_file_group_id
  end
end
