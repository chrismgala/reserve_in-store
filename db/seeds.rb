# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

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
    price: 149,
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

unless Plan.find_by(code: 'enterprise')
  Plan.create(
    code: 'enterprise',
    price: 999,
    name: "Large",
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
