module ApplicationHelper
  def anonymous?
    !user_signed_in? || current_user.anonymous?
  end
  
  def contextual_sign_up
    if user_signed_in?
      link_to "sign up", edit_anonymous_user_registration_path(current_user)
    else
      link_to "sign up", new_user_registration_path
    end
  end

  def preferences
    return @preferences if @preferences
    @preferences = {}
    User::PreferenceNames.each do |key|
      @preferences[key] = current_user.preferences[key].nil? ? true : current_user.preferences[key]
    end
    @preferences
  end

  def add_error_class(object, attribute)
    {:class => ("error" unless object.errors[attribute].blank?)}
  end
end
