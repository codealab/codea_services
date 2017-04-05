class Salesman < ActiveRecord::Base
  def self.assigned
    last_active = self.find_by_active(true)
    last_active.update(active: false)
    salesmen = self.order(:id)
    id = last_active.id == salesmen.last.id ? salesmen.first.id : last_active.id + 1
    active = self.find(id)
    active.update(active: true)
    active
  end
end
