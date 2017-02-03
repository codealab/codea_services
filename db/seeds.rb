users = {"Abraham Eleno" => "abraham@codea.mx", "Jonathan Reyes" => "contacto@codea.mx", "Omar Vazquez" => "omar@codea.mx", "Javier Ibarrola" => "javier@codea.mx"}

users.each do |name, email|
  p Salesman.create(name: name, email: email)
end
Salesman.first.update(active: true)
