# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :standalone?

  private

  # スタンドアローンモードかどうかを返す
  def standalone?
    case Rails.env
    when 'production'
      false
    when 'standalone'
      true
    else
      if ENV['SMALRUBY_EDITOR_STANDALONE_MODE'] ||
          File.exist?(Rails.root.join('tmp', 'standalone'))
        true
      else
        false
      end
    end
  end
end
