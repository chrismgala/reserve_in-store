module Admins
  class UsersController < ::Admins::ApplicationController
        
    def index
      @users = User.order(created_at: :desc)
      if params[:query]
        @users = load_users_from_search_query(params[:query])
      end

      @users = @users.page(params[:page]).per(20)
    end
    

    private

    def load_users_from_search_query(query)

      if params[:query].to_s.downcase.strip =~ /^pk_.+$/
        matched_store_ids = Store.where(public_key: params[:query].to_s.downcase.strip).pluck(:id).to_a
      elsif params[:query].to_s.strip =~ /^sk_.+$/
        matched_store_ids = Store.where(secret_key: params[:query].to_s.downcase.strip).pluck(:id).to_a
      else
        query_str = query.to_s.strip.downcase
        matched_store_ids = []
        matched_store_ids += Store.where('LOWER(shopify_domain) LIKE :query OR LOWER(name) LIKE :query', query: "%#{query_str}%").pluck(:id).to_a
        matched_store_ids += User.where('LOWER(email) LIKE :query OR LOWER(name) LIKE :query', query: "%#{query_str}%").pluck(:store_id).to_a
      end

      @users.where(store_id: matched_store_ids.to_a.uniq)
    end

    end
end
