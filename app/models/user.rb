class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :work_session, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }
end
