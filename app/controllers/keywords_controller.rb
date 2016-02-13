class KeywordsController < ApplicationController
  def revert
    keyword = Keyword.find(params[:id])
    keyword.revert! unless keyword.nil?
    redirect_to keywords_user_path(params[:user_id])
  end
end
