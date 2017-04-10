RSpec.describe PxModule::PerimeterxCookieValidator, "Cookie Validator Tests" do
  before(:each) do
    @params = {
      :app_id => "PX_APP_ID",
      :cookie_key => "PX_COOKIE_KEY",
      :auth_token => "PX_AUTH_TOKEN"
    }

    @req = double("http_request", {
      :cookies => Hash.new,
      :headers => Hash.new,
      :server_name => "MockServer",
      :user_agent => "MockUserAgent",
      :original_url => "http://moch.url.com/",
      :ip => "1.2.3.4",
      :server_protocol => "HTTP://1.1",
      :method => "GET"
      })
  end

  it "verification failed on reason no cookie" do
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to eq false
    expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::NO_COOKIE
  end

  it "verification failed on reason expired cookie" do
    @req.cookies[:_px] = "Z6OUpgAMGgUWg9Vtpv/zuswEAmRxQX2VxxIweMKFnjx596UMzlFxaBRKWNsjLUSs1xxMJCyTnvFml2+rGWfmZw==:1000:iUEmSkjsh8xjQAWldAxFX4NNRf0PWhpAD9HFN051dx4xoBrBnhDbSoV7gAqC23qtMvMJ4uvRWOw76N9euaYSg27zWOOIijckw4MktHpBrbFt9s99I3peS1cUC5dbZmPv+t7n8Pb32o8zqVYGDaytTP5HhAXgBi5hzeXATsMoaffS9INozQUEgU7GJbUvNDeC"
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to eq false
    expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::EXPIRED_COOKIE
  end

  it "verification failed on reason high score" do
    @req.cookies[:_px] = "8XtsLVO3+rQmDJ/b31vLvjVkXgRXpqgjIfatonVDgbw5SGE+Nzl3WscCWabCbjFuEJgrcyWulNzOW5nDE8LWSg==:1000:eMvEpsQtjPYKLqCanfa8K23kjbvS7i0j+Ex8YjWufRcGUVcpssKMCFgiXLXgTELA+/Yjoiw+nPm2sK5kjrEFajb+DEbS4YJkVXXKPJBgF+5fJq9k5rTZyqQ24/0oVIajP07245N2LJYq8z3/b3j+iK/c/hZIRGaMg2k/D0C98XtSPL8iNSOh1lGu0kAe2zMc"
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to eq false
    expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_HIGH_SCORE
  end

  it "verification failed on cookie validation" do
    @req.cookies[:_px] = "B4+RFFKBmAUf8Tw7FKu913pI64IY+rok17S6taqatyVgNJyhUgPKt34SeXgjgNk5tTUD6EyafOnsRPUjnTm5gQ==:1000:aCCffFpX/TtFJBtloLoYGl83BF+wmzwPuEiqDU9aRDxIz46Tyo5nMTTZ737h74nbODI1kGhVZ3tz/NmR+MSkJZlOsc9wlbbvPVVOKU5qJqyI5OGeglG368ZWKZF+Cd+TQtoAIamUeNmNFxEBGqiGu9BW2EcsPDyWkWdXn2i1wvyWc/n6cl4LugG4+5P0bbMb"
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to eq false
    expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_VALIDATION_FAILED
  end

  it "verification failed on cookie decryption fail and px_ctx should have px_orig_cookie" do
    @req.cookies[:_px] = "B4+RFFKBmAdUf8Tw7FKu913pI64IY+rok17S6taqatyVgNJyhUgPKt34SeXgjgNk5tTUD6EyafOnsRPUjnTm5gQ==:1000:aCCffFpdX/TtFJBtloLoYGl83BF+wmzwPuEiqDU9aRDxIz46Tyo5nMTTZ737h74nbODI1kGhVZ3tz/NmR+MSkJZlOsc9wlbbvPVVOKU5qJqyI5OGeglG368ZWKZF+Cd+TQtoAIamUeNmNFxEBGqiGu9BW2EcsPDyWkWdXn2i1wvyWc/n6cl4LugG4+5P0bbMb"
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to eq false
    expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_DECRYPTION_FAILED
    expect(px_ctx.context[:px_orig_cookie]).to eq @req.cookies[:_px]
  end

  it "verification passed succesfully" do
    @req.cookies[:_px] = "kN5gv3OjmmzaQLuPtx7D2QHQgvzKgF2LvX/hKpipNGUR9AaCwwlPZLs0XXbAZxNb2b+iLPsEv0qpAtkamYxy6Q==:1000:gMqzmSVEOMDz6x1Nwc799ULXP/LBIOMsJZA7UuQ0Yj/4zVTT5LxwwySXP5264/Ub9k6CgcMM3587cE6Mr4S8PeFdVejI5d4hDQJC+9LTD+7mNhio8wVO5nIsnFOnMVO31dRfk9u+Xff030y34CYRTiqOjb5ENTRNGR1KDAeqSRY/y/bly7pJSfNAb6Viw8eK"
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCookieValidator.new(config)

    verified, px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:s2s_call_reason]).to be_nil
    expect(verified).to eq true
  end

end
