class Salesman < ActiveRecord::Base
  def self.assigned
    p last_active = self.find_by_active(true)
    p last_active.update(active: false)
    p salesmen = self.order(:id)
    p id = last_active.id == salesmen.last.id ? salesmen.first.id : last_active.id + 1
    p active = self.find(id)
    p active.update(active: true)
    p active
  end
end
