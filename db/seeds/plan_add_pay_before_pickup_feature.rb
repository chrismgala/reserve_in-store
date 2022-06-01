plans = [
  { code: "startup", pay_before_pickup: false },
  { code: "small", pay_before_pickup: false },
  { code: "medium", pay_before_pickup: false },
  { code: "medium-2", pay_before_pickup: false },
  { code: "large", pay_before_pickup: true },
  { code: "large-2", pay_before_pickup: true },
  { code: "enterprise", pay_before_pickup: true },
]

plans.each do |plan|
  Plan.where(
    code: plan[:code]).update_all(
    "features = jsonb_set(features, '{pay_before_pickup}', to_json(#{ plan[:pay_before_pickup] }::boolean)::jsonb)"
  )
end
