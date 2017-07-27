class HomeController < ApplicationController
  include PxModule

  before_action :px_verify_request

  def index
  end

end
