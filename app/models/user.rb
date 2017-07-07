class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  has_many :friendships, -> { where(is_confirmed: true) }
  has_many :friends, through: :friendships
  has_many :conversations, foreign_key: :sender_id
  has_many :messages
  def unread(user, friend)
    conversation = Conversation.between(user.id, friend.id).first
    if !conversation.nil?
      conversation.messages.where(read: false, user_id: friend.id).count
    else
      0
    end
  end

  attr_writer :login

  def login
    @login || username || email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end
end
