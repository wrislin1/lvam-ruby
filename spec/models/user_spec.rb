require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is valid with an email' do
    user = build(:user)
    expect(user).to be_valid
  end
end
