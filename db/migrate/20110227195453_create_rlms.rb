class CreateRlms < ActiveRecord::Migration
  def self.up
    create_table :rlms do |t|
      t.string :md5
      t.string :spread
      t.timestamps
    end
  end

  def self.down
    drop_table :rlms
  end
end
