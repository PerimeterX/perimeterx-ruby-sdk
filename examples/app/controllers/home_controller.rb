class HomeController < ApplicationController
  include PxModule

  before_filter :px_verify_request

  def index
  end

end
