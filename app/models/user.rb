class User < ActiveRecord::Base
    has_secure_password
    validates :email, uniqueness: true
    has_one :passenger
    has_one :driver
end
