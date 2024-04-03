class AddStaticListToSequence < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :sequences, :static_list, :bigint, array: true, default: []
    end
  end
end
