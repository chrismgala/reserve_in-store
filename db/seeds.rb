# See https://docs.google.com/spreadsheets/d/1aeZr4BI_tFWwWZRWqV3xUqErYdDS6gf0Izli35QYKzE/edit#gid=0

unless Plan.find_by(code: 'startup')
  Plan.create(
    code: 'startup',
    price: 19,
    name: "Startup",
    features: {
      custom_templates: false,
      dev_support: false
    },
    limits: {
      locations: 1,
      reservations_per_month: 10
    },
    trial_days: 30
  )
end


unless Plan.find_by(code: 'small')
  Plan.create(
    code: 'small',
    price: 49,
    name: "Small",
    features: {
      custom_templates: true,
      dev_support: false
    },
    limits: {
      locations: 3,
      reservations_per_month: 100
    },
    trial_days: 30
  )
end


unless Plan.find_by(code: 'medium')
  Plan.create(
    code: 'medium',
    price: 99,
    name: "Medium",
    features: {
      custom_templates: true,
      dev_support: true
    },
    limits: {
      locations: 10,
      reservations_per_month: 9999999
    },
    trial_days: 30
  )
end

unless Plan.find_by(code: 'medium-2')
  Plan.create(
    code: 'medium-2',
    price: 199,
    name: "Medium 2",
    features: {
      custom_templates: true,
      dev_support: true
    },
    limits: {
      locations: 25,
      reservations_per_month: 9999999
    },
    trial_days: 30
  )
end

unless Plan.find_by(code: 'large')
  Plan.create(
    code: 'large',
    price: 399,
    name: "Large",
    features: {
      custom_templates: true,
      dev_support: true
    },
    limits: {
      locations: 100,
      reservations_per_month: 9999999
    },
    trial_days: 30
  )
end

unless Plan.find_by(code: 'large-2')
  Plan.create(
    code: 'large-2',
    price: 599,
    name: "Large 2",
    features: {
      custom_templates: true,
      dev_support: true
    },
    limits: {
      locations: 250,
      reservations_per_month: 9999999
    },
    trial_days: 30
  )
end


unless Plan.find_by(code: 'enterprise')
  Plan.create(
    code: 'enterprise',
    price: 999,
    name: "Enterprise",
    features: {
      custom_templates: true,
      dev_support: true
    },
    limits: {
      locations: 1000,
      reservations_per_month: 9999999
    },
    trial_days: 30
  )
end
