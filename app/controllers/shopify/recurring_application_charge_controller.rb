module Shopify
  class RecurringApplicationChargeController < LoggedInController
    before_action :create, :load_current_recurring_charge, only: [:create]

    def create
      if params[:plan].blank?
        session['plan'] = @current_store.recommended_plan_code
      else
        session['plan'] = params[:plan]
      end

      if params[:post_subscribe_url].present?
        session[:post_subscribe_url] = params[:post_subscribe_url]
      end

      ForcedLogger.log("Hit create recurring app charge", store: @current_store.try(:id), plan: plan_id, referrer: request.referrer, current_rac: @current_rac.try(:id))

      @current_rac.try!(:cancel)

      @current_rac = current_store.api.recurring_application_charge.new(new_charge_params)

      @current_rac.test = Rails.env.development?
      @current_rac.return_url = recurring_application_charge_callback_url

      if @current_rac.save
        redirect_to @current_rac.confirmation_url
      else
        ForcedLogger.error("Failed to save the recurring application charge in shopify: #{@current_rac.errors.inspect}.", store: @current_store.try(:id))

        flash[:error] = @current_rac.errors.full_messages.first.to_s.capitalize

        redirect_to_correct_path(false)
      end
    end

    def callback
      ForcedLogger.log("Hit callback recurring app charge", store: @current_store.try(:id), charge_id: params[:charge_id], referrer: request.referrer)

      @current_rac = current_store.api.recurring_application_charge.find(params[:charge_id])

      if @current_rac.status == 'accepted'
        @current_rac.activate
        find_or_update_subscription

        if @subscription.save
          unless session['post_subscribe_success_message'] == 'none'
            flash[:notice] = (session['post_subscribe_success_message'] || "You've been subscribed successfully! Congrats!")
          end

          Thread.new { ping_slack }

          redirect_to_correct_path(true)
        else
          ForcedLogger.error("Subscription failed unexpectedly. See logs.",
                             log: "Subscription save NOT successful: #{@subscription.inspect}",
                             sentry: true,
                             store: @current_store.try(:id))

          unless session['hide_errors'] == 'yes'
            flash[:error] = "Sorry, there was a problem with your subscription. " + \
                            "Please contact our support team for help. Our engineers have been notified about the " + \
                            "problem so we can help you more quickly."
          end

          redirect_to_correct_path(false)
        end
      else
        unless session['post_subscribe_decline_message'] == 'none'
          flash[:error] = session['post_subscribe_decline_message'] || "Plan was not accepted. Please click 'accept' when you're redirected to Shopify."
        end

        redirect_to_correct_path(false)
      end

      session.delete('post_subscribe_message')
      session.delete('post_subscribe_success_message')
      session.delete('hide_errors')
      session.delete('post_subscribe_decline_message')
      session.delete('plan')
    end

    private

    def ping_slack
      store = @store

      plan_msg = store.trial_days_left > 0 ? "(#{store.trial_days_left}d trial)" : '(non-trial)'

      Bananastand::SlackNotifer.ping_general("💵 #{store_markdown(store)} :long_arrow_right: *#{subscription.nice_price}* #{plan_msg}")
    end

    def store_markdown(store)
      return "_store that no longer exists_" if store.blank?
      store_name = store.name.size > 22 ? "#{store.name[0..20]}..." : store.name
      "[:shopify:](#{store.url.to_s.strip}) #{store_name}"
    end

    def plan_rules_store_context
      @plan_rules_store_context ||= @current_store.plan_recommender.plan_rule_context
    end

    def find_or_update_subscription
      @subscription = @current_store.subscription
      if @subscription.blank?
        @subscription = Subscription.new(store: @current_store)
      end

      @subscription.remote_id = @current_rac.id.to_s
      @subscription.plan = plan
    end

    def load_current_recurring_charge
      @current_rac = current_store.api.recurring_application_charge.current
    end

    def new_charge_params
      {
        name: plan.code,
        price: plan.price,
        trial_days: @current_store.trial_days_left
      }
    end

    def plan_id
      @plan_id ||= params[:plan] || session['plan']
    end

    def plan
      @plan ||= plan_id.to_s =~ /[0-9]+/ ? Plan.find(plan_id.to_i) : Plan.find_by(code: plan_id)
    end

    def redirect_to_correct_path(success)
      general_url = session.delete('post_subscribe_url')
      default_url = "/stores/settings"
      failure_url = session.delete('post_subscribe_failure_url') || general_url || default_url
      success_url = session.delete('post_subscribe_success_url') || general_url || default_url

      redirect_to(success ? success_url : failure_url)
    end

  end
end
