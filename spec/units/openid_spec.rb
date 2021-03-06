require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')

describe "visiting /sso" do
  before(:each) do
    @user = Hancock::User.gen
    @consumer = Hancock::Consumer.gen(:internal)
    @identity_url = "http://example.org/sso/users/#{@user.id}"
  end
  it "should throw a bad request if there aren't any openid params" do
    get '/sso'
    last_response.status.should eql(400)
  end
  describe "with openid mode of associate" do
    it "should respond with Diffie Hellman data in kv format" do
      session = OpenID::Consumer::AssociationManager.create_session("DH-SHA1")
      params =  {"openid.ns"           => 'http://specs.openid.net/auth/2.0',
                 "openid.mode"         => "associate",
                 "openid.session_type" => 'DH-SHA1',
                 "openid.assoc_type"   => 'HMAC-SHA1',
                 "openid.dh_consumer_public"=> session.get_request['dh_consumer_public']}

      get "/sso", params

      message = OpenID::Message.from_kvform("#{last_response.body}")  # wtf do i have to interpolate this!
      secret = session.extract_secret(message)
      secret.should_not be_nil

      args = message.get_args(OpenID::OPENID_NS)

      args['assoc_type'].should       == 'HMAC-SHA1'
      args['assoc_handle'].should     =~ /^\{HMAC-SHA1\}\{[^\}]{8}\}\{[^\}]{8}\}$/
      args['session_type'].should     == 'DH-SHA1'
      args['enc_mac_key'].size.should == 28
      args['expires_in'].should       =~ /^\d+$/
      args['dh_server_public'].size.should == 172
    end
  end
  describe "with openid mode of checkid_setup" do
    describe "authenticated" do
      it "should redirect to the consumer app" do
        params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_setup",
            "openid.return_to"  => @consumer.url,
            "openid.identity"   => @identity_url,
            "openid.claimed_id" => @identity_url}

        login(@user) 
        get "/sso", params
        last_response.status.should == 302

        redirect_params = Addressable::URI.parse(last_response.headers['Location']).query_values

        redirect_params['openid.ns'].should               == 'http://specs.openid.net/auth/2.0'
        redirect_params['openid.mode'].should             == 'id_res'
        redirect_params['openid.return_to'].should        == @consumer.url
        redirect_params['openid.assoc_handle'].should     =~ /^\{HMAC-SHA1\}\{[^\}]{8}\}\{[^\}]{8}\}$/
        redirect_params['openid.op_endpoint'].should      == 'http://example.org/sso' 
        redirect_params['openid.claimed_id'].should       == @identity_url
        redirect_params['openid.identity'].should         == @identity_url

        redirect_params['openid.sreg.email'].should         == @user.email
        redirect_params['openid.sreg.last_name'].should     == @user.last_name
        redirect_params['openid.sreg.first_name'].should    == @user.first_name

        redirect_params['openid.sig'].should_not be_nil
        redirect_params['openid.signed'].should_not be_nil
        redirect_params['openid.response_nonce'].should_not be_nil
      end

      describe "attempting to access another identity" do
        it "should return forbidden" do
          params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_setup",
            "openid.return_to"  => @consumer.url,
            "openid.identity"   => "http://example.org/sso/users/42",
            "openid.claimed_id" => "http://example.org/sso/users/42"}

          login(@user)
          get "/sso", params
          last_response.status.should == 403
        end
      end
      describe "attempting to access from an untrusted consumer" do
        it "cancel the openid request" do
          params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_setup",
            "openid.return_to"  => "http://rogueconsumerapp.com/",
            "openid.identity"   => @identity_url,
            "openid.claimed_id" => @identity_url}

          login(@user)
          get "/sso", params
          last_response.status.should == 403
        end
      end
    end
    describe "unauthenticated user" do
      it "should require authentication" do
        params = {
          "openid.ns"         => "http://specs.openid.net/auth/2.0",
          "openid.mode"       => "checkid_setup",
          "openid.return_to"  => @consumer.url,
          "openid.identity"   => @identity_url,
          "openid.claimed_id" => @identity_url}

        get "/sso", params
        last_response.body.should be_a_login_form
      end
    end
  end
  describe "with openid mode of checkid_immediate" do
    describe "unauthenticated user" do
      it "should require authentication" do
        params = {
          "openid.ns"         => "http://specs.openid.net/auth/2.0",
          "openid.mode"       => "checkid_immediate",
          "openid.return_to"  => @consumer.url,
          "openid.identity"   => @identity_url,
          "openid.claimed_id" => @identity_url}

        get "/sso", params
        last_response.body.should be_a_login_form
      end
    end
    describe "authenticated user" do
      describe "with appropriate request parameters" do
        it "should redirect to the consumer app" do
          params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_immediate",
            "openid.return_to"  => @consumer.url,
            "openid.identity"   => @identity_url,
            "openid.claimed_id" => @identity_url}

          login(@user)
          get "/sso", params
          last_response.status.should == 302

          redirect_params = Addressable::URI.parse(last_response.headers['Location']).query_values

          redirect_params['openid.ns'].should               == 'http://specs.openid.net/auth/2.0'
          redirect_params['openid.mode'].should             == 'id_res'
          redirect_params['openid.return_to'].should        == @consumer.url
          redirect_params['openid.assoc_handle'].should     =~ /^\{HMAC-SHA1\}\{[^\}]{8}\}\{[^\}]{8}\}$/
          redirect_params['openid.op_endpoint'].should      == 'http://example.org/sso' 
          redirect_params['openid.claimed_id'].should       == @identity_url
          redirect_params['openid.identity'].should         == @identity_url

          redirect_params['openid.sreg.email'].should         == @user.email
          redirect_params['openid.sreg.last_name'].should     == @user.last_name
          redirect_params['openid.sreg.first_name'].should    == @user.first_name

          redirect_params['openid.sig'].should_not be_nil
          redirect_params['openid.signed'].should_not be_nil
          redirect_params['openid.response_nonce'].should_not be_nil
        end
      end

      describe "attempting to access another identity" do
        it "should return forbidden" do
          params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_immediate",
            "openid.return_to"  => @consumer.url,
            "openid.identity"   => "http://example.org/sso/users/42",
            "openid.claimed_id" => "http://example.org/sso/users/42" }

          login(@user)
          get "/sso", params
          last_response.status.should == 403
        end
      end

      describe "attempting to access from an untrusted consumer" do
        it "cancel the openid request" do
          params = {
            "openid.ns"         => "http://specs.openid.net/auth/2.0",
            "openid.mode"       => "checkid_immediate",
            "openid.return_to"  => "http://rogueconsumerapp.com/",
            "openid.identity"   => @identity_url,
            "openid.claimed_id" => @identity_url}
          
          login(@user)
          get "/sso", params
          last_response.status.should == 403
        end
      end
    end
  end
end
