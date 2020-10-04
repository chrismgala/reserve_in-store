class TriggerWebhookJob < ActiveJob::Base
  attr_accessor :store, :object, :topic

  def perform(store_id:, topic:, object_id:, object_klass:)
    @topic = topic

    @store = Store.find(store_id)
    return if @store.blank?

    sleep(1.second)

    @object = object_klass.constantize.find(object_id)
    return if @object.blank?

    store.webhooks.find_all{ |hook| hook['topic'] }.each do |hook|
      hook['topic'].each do |hook_topic|
        call_hook(hook['url'], hook_topic) if hook_topic == topic
      end
    end
  end

  private

  def call_hook(url, auth_token)
    url = url.to_s.strip.chomp('?')
    return if url.blank?

    ForcedLogger.log("Hitting webhook #{url}", store: store.id, topic: topic, object: object_id)

    url += url.include?('?') ? '?' : '&'
    url += { secret_key: store.secret_key }.to_param

    data = object.respond_to?(:to_api_h) ? object.to_api_h : object.attributes

    HTTParty.post(url, body: data.to_json, timeout: 10, headers: {
      'Authorization' => "Bearer #{auth_token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json' })
  end
end
