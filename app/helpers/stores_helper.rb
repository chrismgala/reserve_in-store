module StoresHelper
  
  ##
  # Generates a dropdown select that lets the user choose reserve button integration
  #
  # @param store [Store]
  # @param attr [Symbol]
  # @option extra_classes [String] (optional) extra classes to add to the field
  def render_status_integration_field(store, attr, extra_classes: '')
    action_key = "#{attr}_action".to_sym
    action_val = store.send(action_key)
    
    html = "<select id=\"store_#{action_key}\" class=\"form-control small-width-field #{extra_classes}\" name=\"store[#{action_key}]\">"
    
    html += "<option value='auto'"
    html += " selected=\"selected\"" if action_val.blank? ||  action_val == 'auto'
    html += ">ON - Automatic Integration (Default)"
    html += "</option>"

    html += "<option value='insert_after'"
    html += " selected=\"selected\"" if action_val == 'insert_after'
    html += ">ON - Custom Integration - Insert After..."
    html += "</option>"

    html += "<option value='insert_before'"
    html += " selected=\"selected\"" if action_val == 'insert_before'
    html += ">ON - Custom Integration - Insert Before..."
    html += "</option>"

    html += "<option value='append_to'"
    html += " selected=\"selected\"" if action_val == 'append_to'
    html += ">ON - Custom Integration - Append To..."
    html += "</option>"

    html += "<option value='prepend_to'"
    html += " selected=\"selected\"" if action_val == 'prepend_to'
    html += ">ON - Custom Integration - Prepend To..."
    html += "</option>"

    html += "<option value='manual'"
    html += " selected=\"selected\"" if action_val == 'manual'
    html += ">OFF - Manual Integration"
    html += "</option>"

    html += "</select>"

    html.html_safe
  end
end
