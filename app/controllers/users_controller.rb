class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :keywords, :reset_keywords, :multiply_keywords, :log]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    respond_to do |format|
      format.html
      format.json { render json: @users.where(paused: false) }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @industries = Industry.order(:name)
  end

  # GET /users/1/edit
  def edit
    @industries = Industry.order(:name)
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params.merge! industry: Industry.find(params[:industry]))

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def reset_keywords
    @keywords = Keyword.where(owner: @user.dir).each{|k| k.update(passed: false)}
    redirect_to keywords_user_path(@user)
  end

  def multiply_keywords
    @user.multiply_keywords
    redirect_to keywords_user_path(@user)
  end

  def keywords
    @keywords = Keyword.where(owner: @user.dir).order(:passed, :position)
    @industries = Industry.order(:name).pluck(:name, :index).to_h
    @next_key = @user.get_next_key
  end

  def log
    logger.warn("#{Time.now.to_formatted_s(:short)} #{@user.dir}: #{params[:message]}")
    render text: ''
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params.merge! industry: Industry.find(params[:industry]))
        format.html { redirect_to users_path, notice: 'Success. '}
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params[:user].permit!
  end
end