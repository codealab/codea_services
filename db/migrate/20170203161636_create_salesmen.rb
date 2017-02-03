class CreateSalesmen < ActiveRecord::Migration
  def change
    create_table :salesmen do |t|
      t.string    :name
      t.string    :email
      t.boolean   :active, default: false
    end
  end
end
