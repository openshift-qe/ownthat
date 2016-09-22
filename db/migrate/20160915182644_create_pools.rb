class CreatePools < ActiveRecord::Migration[5.0]
  def change
    create_table :pools do |t|
      t.string :name, null: false
      t.string :resource, null: false
      t.boolean :active, null: false
      t.string :note, null: true

      t.timestamps
    end

    add_index(:pools, [:name, :resource], unique: true)
  end
end
