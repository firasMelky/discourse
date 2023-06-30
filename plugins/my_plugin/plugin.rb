# plugin.rb

register_asset 'javascripts/discourse/auth_api.js.es6'

after_initialize do
  require_dependency 'auth/api_controller'

  module ::Auth
    class ApiAuthController < ::Auth::ApiController
      skip_before_action :verify_authenticity_token

      def register
        # Extract required registration data from the request params
        email = params[:email]
        username = params[:username]
        password = params[:password]

        # Create a new user using Discourse User API
        user = User.new(email: email, username: username, password: password)
        if user.save
          render json: { success: true, message: 'User registered successfully' }
        else
          render json: { success: false, errors: user.errors.full_messages }
        end
      end

      def authenticate
        # Extract user credentials from the request params
        username = params[:username]
        password = params[:password]

        # Authenticate the user using Discourse User API or other methods
        if User.authenticate(username, password)
          render json: { success: true, message: 'Authentication successful' }
        else
          render json: { success: false, message: 'Authentication failed' }
        end
      end
    end
  end

  Discourse::Application.routes.append do
    post '/auth/register' => 'auth/api_auth#register'
    post '/auth/authenticate' => 'auth/api_auth#authenticate'
  end
end
