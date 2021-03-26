class TriggerWebhookJob < ActiveJob::Base
  attr_accessor :store, :object, :topic

  def perform(store_id:, topic:, object_id:, object_klass:)
    @topic = topic
    @object_id = object_id

    @store = Store.find(store_id)
    return if @store.blank?

    @object = object_klass.constantize.find(object_id)
    return if @object.blank?

    store.webhooks.find_all{ |hook| hook['topic'] }.each do |hook|
      topics = hook['topic'].is_a?(Array) ? hook['topic'] : [hook['topic']]
      call_hook(hook['url'], hook['auth_token']) if topics.include? topic
    end
  end

  private

  def call_hook(url, auth_token)
    url = url.to_s.strip.chomp('?')
    return if url.blank?

    ForcedLogger.log("Hitting webhook #{url}", store: store.id, topic: topic, object: @object_id)

    url += url.include?('?') ? '&' : '?'
    url += { secret_key: store.secret_key }.to_param

    data = object.respond_to?(:to_api_h) ? object.to_api_h : object.attributes

    headers = headers(auth_token)

    HTTParty.post(url, body: data.to_json, timeout: 60, headers: headers)

  rescue StandardError => e
    ForcedLogger.error(e, log: "Webhook failed to trigger.", store: store.id, topic: topic, object: @object_id)
    raise e
  end

  def headers(auth_token)
    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    headers = headers.merge('Authorization' => "#{auth_token}") if auth_token.present?

    headers
  end
end
