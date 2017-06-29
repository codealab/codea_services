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

  def self.actual_id
    ids = { 'Omar Vazquez' => '2066727000001483009', 'Jonathan Reyes' => '2066727000000531969', 'Enrique Hernandez' => '2066727000004666316' }
    ids[self.find_by_active(true).name]
  end

end
