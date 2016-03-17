class PiplsController < ApplicationController
  def index
    @all = Person.all
    @pipl = Person.mined
    @running = !Delayed::Backend::ActiveRecord::Job.count.zero?
  end

  def research
    Miner.perform_later(params)
    redirect_to pipls_path
  end
end
