# frozen_string_literal: true

module ApplicationHelper
  def default_meta_tags
    {
      site: 'モチベーションストリーミング',
      title: 'モチベーションストリーミング',
      reverse: true,
      charset: 'utf-8',
      description: '配信活動に悩む配信者向けに、分析シートで悩みを構造化し、AIが配信者特化の分析で最適な目標と行動プランを提案するWebアプリです。',
      keywords: '配信者,モチベーション,目標達成,配信活動,YouTube,Twitch,ライブ配信',
      canonical: request.original_url,
      separator: '|',
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: 'website',
        url: request.original_url,
        image: image_url('ogp.png'),
        locale: 'ja_JP'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@beautycandybear',
        image: image_url('ogp.png')
      }
    }
  end

  def markdown(text)
    return '' if text.blank?
    
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      hard_wrap: true,
      link_attributes: { target: '_blank' }
    )
    
    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      lax_spacing: true,
      space_after_headers: true
    )
    
    sanitized_html = Sanitize.fragment(
      markdown.render(text),
      Sanitize::Config::RELAXED
    )
    
    sanitized_html.html_safe
  end
end
