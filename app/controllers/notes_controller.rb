class NotesController < ApplicationController
  def index
    @note = note.new
    @notes = note.all
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @note = note.find(params[:id])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @note = note.new

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @note = note.find(params[:id])
    respond_to do |format|
      format.html 
      format.js
    end
  end

  def create
    @note = note.new(params[:note])

    respond_to do |format|
      if @note.save
        format.html { redirect_to(@note) }
        format.js
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @note = note.find(params[:id])

    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.html { redirect_to(@note) }
        format.js
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @note = note.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.html { redirect_to(notes_url) }
      format.js
    end
  end
end
