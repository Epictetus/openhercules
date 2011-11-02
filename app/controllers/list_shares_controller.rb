class ListSharesController < ApplicationController
  before_filter :authenticate_user!
  
  def create
    list = List.find(params[:id])
    if list.user != current_user
      render :head => 401
    elsif user.all_associated_lists.include? list
      render :head => 409
    else
      user = User.find(params[:user_id])
      user.add_list_invitation(list, params[:permission])
    end
  end
  
  def update
  end
end
