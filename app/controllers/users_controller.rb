# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show follow unfollow accept decline cancel]
  def index
    @users = User.all_except(current_user)
  end

  def follow
    @users = current_user.followers
    current_user.send_follow_request_to(@user)
    redirect_back fallback_location: root_path
  end

  def unfollow
    make_it_an_unfriend_request
    current_user.unfollow(@user)
    redirect_back fallback_location: root_path
  end

  def accept
    current_user.accept_follow_request_of(@user)
    make_it_a_friend_request
    redirect_back fallback_location: root_path
  end

  def decline
    current_user.decline_follow_request_of(@user)
    redirect_back fallback_location: root_path
  end

  def cancel
    current_user.remove_follow_request_for(@user)
    redirect_back fallback_location: root_path
  end

  def show
    @user = User.find(params[:id])
    @users = current_user.followers
    redirect_to '/rooms' and return unless @user.mutual_following_with?(current_user)
    @room = Room.new
    @rooms = Room.public_rooms
    @room_name = get_name(@user, current_user)
    @single_room = Room.where(name: @room_name).first || Room.create_private_room([@user, current_user], @room_name)

    @message = Message.new
    @messages = @single_room.messages.order(created_at: :asc)
    render 'rooms/index'
  end

  def show_user_profile
    @user = User.find(params[:id])
    redirect_to user_profile_path if @user == current_user
  end

  def user_profile
    @user = current_user
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def make_it_a_friend_request
    current_user.send_follow_request_to(@user)
    @user.accept_follow_request_of(current_user)
  end

  def make_it_an_unfriend_request
    @user.unfollow(current_user) if @user.mutual_following_with?(current_user)
  end

  def get_name(user1, user2)
    user = [user1, user2].sort
    "private_#{user[0].id}_#{user[1].id}"
  end
end
