class TriggerWebhookJob < ActiveJob::Base
  attr_accessor :store, :object, :topic

  def perform(store_id:, topic:, object_id:, object_klass:)
    @topic = topic

    @store = Store.find(store_id)
    return if @store.blank?

    @object = object_klass.constantize.find(object_id)
    return if @object.blank?

    store.webhooks.find_all{ |hook| hook['topic'] == topic }.each do |hook|
      call_hook(hook['url'])
    end
  end

  private

  def call_hook(url)
    url = url.to_s.strip.chomp('?')
    return if url.blank?

    ForcedLogger.log("Hitting webhook #{url}", store: store.id, topic: topic, object: object_id)

    url += url.include?('?') ? '?' : '&'
    url += { secret_key: store.secret_key }.to_param

    HTTParty.post(url, body: object.attributes.to_json, timeout: 10, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
  end
end
