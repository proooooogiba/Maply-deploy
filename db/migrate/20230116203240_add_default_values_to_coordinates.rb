class AddDefaultValuesToCoordinates < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :latitude, 30.801903
    change_column_default :users, :longitude, -172.826409
  end
end
