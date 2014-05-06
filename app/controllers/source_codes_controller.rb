# -*- coding: utf-8 -*-
require 'nkf'

class SourceCodesController < ApplicationController
  before_filter :check_whether_standalone, only: [:write, :run, :load_local]

  def index
    res = {
      localPrograms: [],
      demoPrograms: [],
    }
    if standalone?
      local_program_paths.each do |path|
        # TODO: XMLからタイトルを抽出する
        # TODO: XMLからキャラクターの画像を抽出する
        filename = rb_basename(path)
        res[:localPrograms] << {
          title: filename,
          filename: filename,
        }
      end
    end

    # TODO: XMLから情報を抽出する
    res[:demoPrograms] << {
      title: '車のおいかけっこ',
      filename: 'car_chase.rb',
      imageUrl: '/smalruby/assets/car2.png',
    }
    res[:demoPrograms] << {
      title: 'ライトをぴかっとさせるでよ',
      filename: 'hardware_led.rb',
      imageUrl: '/smalruby/assets/frog1.png',
    }

    render json: res
  end

  def check
    render json: SourceCode.new(source_code_params).check_syntax
  end

  def create
    sc = SourceCode.create!(source_code_params)
    session[:source_code] = {
      id: sc.id,
      digest: sc.digest,
    }
    render json: { source_code: { id: sc.id } }
  end

  def download
    send_data(source_code.data,
              filename: url_encode_filename(source_code.filename),
              disposition: 'attachment',
              type: 'text/plain; charset=utf-8')

    destroy_source_code_and_delete_session(source_code)
  end

  def write
    res = { source_code: { filename: source_code.filename } }

    write_source_code(source_code)

    destroy_source_code_and_delete_session(source_code)

    render json: res
  rescue => e
    res[:source_code][:error] = e.message
    render json: res
  end

  def load
    f = params[:source_code][:file]
    info = get_file_info(f)
    if /\Atext\/plain/ =~ info[:type]
      info[:data] = NKF.nkf('-w', f.read)
    else
      info[:error] = 'Rubyのプログラムではありません'
    end

    render json: { source_code: info }, content_type: request.format
  end

  def load_local
    filename = source_code_params[:filename]
    program_path = local_program_paths.find { |path|
      rb_basename(path) == filename
    }
    load_local_file(program_path)
  end

  def load_demo
    filename = source_code_params[:filename]
    program_path = demo_program_paths.find { |path|
      rb_basename(path) == filename
    }
    load_local_file(program_path)
  end

  def run
    source_code = SourceCode.new(source_code_params)
    path = Pathname("~/#{source_code.filename}").expand_path
    render json: source_code.run(path)
  end

  def to_blocks
    source_code = SourceCode.new(source_code_params)
    render text: source_code.to_blocks
  rescue
    if Rails.env == 'development'
      raise
    else
      head :bad_request
    end
  end

  private

  def source_code_params
    params.require(:source_code).permit(:data, :filename)
  end

  def get_file_info(file)
    {
      filename: file.original_filename,
      type: MIME.check(file.path).try(:content_type) || file.content_type,
      size: file.size,
    }
  end

  def url_encode_filename(filename)
    if request.env['HTTP_USER_AGENT'] =~ /MSIE|Trident/
      return ERB::Util.url_encode(filename)
    else
      filename
    end
  end

  def source_code
    return @source_code if @source_code
    sc = SourceCode.find(session[:source_code][:id])
    unless sc.digest == session[:source_code][:digest]
      fail ActiveRecord::RecordNotFound
    end
    @source_code = sc
  end

  def write_source_code(source_code)
    path = Pathname("~/#{source_code.filename}").expand_path.to_s

    fail 'すでに同じ名前のプログラムがあります' if File.exist?(path) && params[:force].blank?

    File.open(path, 'w') do |f|
      f.write(source_code.data)
    end
  end

  def destroy_source_code_and_delete_session(source_code)
    source_code.destroy

    session[:source_code] = nil
  end

  def local_program_paths
    Pathname.glob(Pathname('~/*.rb.xml').expand_path)
  end

  def demo_program_paths
    Pathname.glob(Rails.root.join('demos/*.rb.xml'))
  end

  def rb_basename(path)
    path = path.basename.to_s
    path = path[0...-4] if /\.xml\z/ =~ path
    path
  end

  def load_local_file(path)
    if path
      info = {
        filename: path.basename.to_s,
        type: MIME.check(path.to_s).try(:content_type) || 'text/plain',
        data: NKF.nkf('-w', path.read),
        size: path.size,
      }
    else
      info = {
        filename: source_code_params[:filename],
        error: 'ありません',
      }
    end

    render json: { source_code: info }, content_type: request.format
  end
end
