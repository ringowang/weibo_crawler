class CreateWeibos < ActiveRecord::Migration[5.1]
  def change
    create_table :weibos do |table|
      table.column :content,     :string
      table.column :pic_url, :string
      table.column :pic_combination_url, :string
      table.column :pics_downloaded?, :boolean, default: false
      table.column :active, :boolean, default: true
      table.column :released_at, :datetime, null: false
    end
  end
end
