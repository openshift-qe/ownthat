class CreateLocks < ActiveRecord::Migration[5.0]
  def change
    create_table :locks do |t|
      t.string :namespace, null: true
      t.string :resource, null: false
      t.string :owner, null: false
      t.datetime :expires, null: false

      t.timestamps
    end

    add_index(:locks, [:namespace, :resource], unique: true)
  end
end
