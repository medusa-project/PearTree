class ChangeTypeOfBytestreamByteSizeColumn < ActiveRecord::Migration
  def change
    change_column :bytestreams, :byte_size, :decimal, precision: 15, scale: 0
  end
end
