class DeleteTranslations < ActiveRecord::Migration
  def change
    drop_table :translations
  end
end
