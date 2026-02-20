# frozen_string_literal: true

class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[top terms privacy contact]

  def top; end

  def terms; end

  def privacy; end

  def contact; end
end
