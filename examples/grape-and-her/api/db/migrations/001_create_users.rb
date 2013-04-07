class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :fullname
      t.integer :organization_id, null: false

      t.timestamps
    end
  end
end
