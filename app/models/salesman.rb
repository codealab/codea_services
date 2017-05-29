class Salesman < ActiveRecord::Base
  def self.assigned
    last_active = self.find_by_active(true)
    if last_active
      last_active.update(active: false)
      salesmen = self.order(:id)
      if last_active.id == salesmen.last.id
        active = salesmen.first
      else
        id = salesmen.index(last_active)
        active = salesmen[id+1]
      end
    else
      active = self.first
    end
    active.update(active: true)
    active
  end
end
