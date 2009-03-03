require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')

describe "posting to /users/signup" do
  before(:each) do
    @existing_user = Hancock::User.gen
    @user = Hancock::User.new(:email      => /\w+@\w+\.\w{2,3}/.gen.downcase,
                              :first_name => /\w+/.gen.capitalize,
                              :last_name  => /\w+/.gen.capitalize)
    @consumer = Hancock::Consumer.gen(:internal)
  end
  describe "with valid information" do
    it "should sign the user up" do
      post '/users/signup', :email      => @user.email,
                            :first_name => @user.first_name,
                            :last_name  => @user.last_name

      @response.should have_selector("h3:contains('Success')")
      @response.should have_selector('p:contains("Check your email and you\'ll see a registration link!")')
      @response.should match(%r!href='http://example.org/users/register/\w{40}'!)
    end
  end
  describe "with invalid information" do
    it "should not sign the user up" do
      post '/users/signup', :email      => @existing_user.email,
                            :first_name => @existing_user.first_name,
                            :last_name  => @existing_user.last_name
      @response.should have_selector("h3:contains('Signup Failed')")
      @response.should have_selector("p a[href='/users/signup']:contains('Try Again?')")
    end
  end
end
