# frozen_string_literal: true

require 'open-uri'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github]

  scope :all_except, ->(user) { where.not(id: user) }
  after_create_commit { broadcast_append_to 'users' }
  has_many :messages
  has_one_attached :avatar
  after_commit :add_default_avatar, on: %i[create update]
  followability
  
  validates :avatar, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 1..(5.megabytes) }

  validates :email, presence: { message: 'не может быть пустым' }, uniqueness: { message: 'такой аккаунт уже зарегистрирован' }, 
                    format: { with: /\A[a-zA-Z0-9.]+@[a-z]{2,6}\.[a-z]{2,3}\z/,
                    message: 'Не верный формат' }
  
  validates_numericality_of :latitude,
                            greater_than_or_equal_to: -90.0,
                            message: 'ширина должна быть в диапазоне от -90 до 90',
                            allow_nil: true

  validates_numericality_of :latitude,
                            less_than_or_equal_to: 90.0,
                            message: 'ширина должна быть в диапазоне от -90 до 90',
                            allow_nil: true

  validates_numericality_of :longitude,
                            greater_than_or_equal_to: -180.0,
                            message: 'ширина должна быть в диапазоне от -180 до 180',
                            allow_nil: true

  validates_numericality_of :latitude,
                            less_than_or_equal_to: 180.0,
                            message: 'ширина должна быть в диапазоне от -180 до 180',
                            allow_nil: true

  def unfollow(user)
    followerable_relationships.where(followable_id: user.id).destroy_all
  end

  def self.search(params)
    if params[:query].blank?
      none
    else
      where(
        'full_name LIKE ?', "%#{sanitize_sql_like(params[:query])}%"
      )
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.full_name = auth.info.name
    end
  end

  def self.from_omniauth_github(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first
    user ||= User.create(
      full_name: data['name'],
      email: data['email'],
      password: Devise.friendly_token[0, 20],
      provider: access_token.provider,
      uid: access_token.uid
    )
    user
  end

  def avatar_thumbnail
    avatar.variant(resize_to_fill: [250, 250, gravity: 'north']).processed 
  end

  def chat_avatar
    avatar.variant(resize_to_fill: [50, 50, gravity: 'north']).processed 
  end

  private

  def add_default_avatar
    unless avatar.attached?
      avatar.attach(
        io: File.open(Rails.root.join('app', 'assets', 'images', 'no-photo.png')),
        filename: 'no-photo.png',
        content_type: 'image/png'
      )
    end
  end
end
