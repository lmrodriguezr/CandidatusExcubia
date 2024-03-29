module ApplicationHelper
  def list_preference
    cookies[:list] || 'cards'
  end

  def download_link(file, name = nil)
    path = "#{root_url}/files/#{file}"
    local_path = File.join(Rails.public_path, 'files', file)
    name ||= File.basename(file).gsub(/\..*/, '').gsub(/_/, ' ').gsub(/-/, ', ')
    text = name + ' (' + File.extname(file).delete('.').upcase + ', ' +
           number_to_human_size(File.size(local_path)) + ')'
    link_to(path) do
      fa_icon(:download, class: 'mr-2') + content_tag(:span, text)
    end
  end

  def pager(object)
    will_paginate(
      object,
      renderer: WillPaginate::ActionView::BootstrapLinkRenderer,
      list_classes: %w(pagination justify-content-center)
    )
  end

  def list_type_selector
    link_to(set_list_url) do
      if list_preference.to_s == 'table'
        content_tag(:span, 'See as cards ') +
          fa_icon('th')
      else
        content_tag(:span, 'See as table ') +
          fa_icon('list')
      end
    end
  end

  def current_contributor?
    current_user.try :contributor?
  end

  def current_curator?
    current_user.try :curator?
  end

  def current_admin?
    current_user.try :admin?
  end

  def current_editor?
    current_user.try :editor?
  end

  def adaptable_list(opts = {}, &blk)
    opts[:type] ||= list_preference.to_sym
    list = AdaptableList.new(opts)
    o = []
    o << pager(list.set) if list.set
    o << content_tag(list.tag, list.css) do
      if list.type == :cards
        blk[list]
      else
        body = content_tag(:tbody) { blk[list] }
        content_tag(:thead) do
          content_tag(:tr) do
            ([nil] + list.value_names)
              .map { |i| content_tag(:th, i, scope: :col) }
              .compact
              .inject(:+)
          end
        end + body
      end
    end
    o << pager(list.set) if list.set
    o << tag(:br)
    o.compact.inject(:+)
  end

  def adaptable_entry(list, title, link)
    entry = list.entry
    content_tag(entry.tag, entry.css) do
      o = []
      if list.type == :cards
        o << link_to(link, entry.link_css) do
          content_tag(entry.header_tag, entry.header_css) do
            content_tag(:h3, title)
          end
        end
        o << content_tag(entry.content_tag, entry.content_css) do
          content_tag(:dl) { yield(entry) }
        end
        if entry.footer_blk
          o << content_tag(entry.footer_tag, entry.footer_css) do
            entry.footer_blk.call
          end
        end
      else
        o << content_tag(entry.header_tag, entry.header_css, scope: :row) do
          link_to(title, link, entry.link_css)
        end
        o << content_tag(:div) { yield(entry) }
        if entry.footer_blk
          o << content_tag(entry.footer_tag, entry.footer_css) do
            entry.footer_blk.call
          end
        end
      end
      o.compact.inject(:+)
    end
  end

  def adaptable_value(entry, name)
    value = entry.value(name)
    o = []
    o << content_tag(:dt, name) if value.type == :cards
    o << content_tag(value.tag) { yield(value) }
    o.compact.inject(:+)
  end

  def modal(title)
    @modals ||= []
    id = "modal-#{@modals.size}"
    @modals <<
      content_tag(
        :div, id: id, class: 'modal fade', tabindex: '-1', role: 'dialog'
      ) do
        content_tag(:div, class: 'modal-dialog', role: 'document') do
          content_tag(:div, class: 'modal-content') do
            content_tag(:div, class: 'modal-header') do
              content_tag(:h5, title, class: 'modal-title') +
                content_tag(
                  :button, type: 'button', class: 'close',
                  data: { dismiss: 'modal' },
                  aria: { label: 'Close' }
                ) do
                  content_tag(
                    :span, '&times;'.html_safe, aria: { hidden: true }
                  )
                end
            end + content_tag(:div, class: 'modal-body') { yield } 
          end
        end
      end
    return id
  end

  def modal_button(id, opts = {})
    opts[:type] ||= 'button'
    opts[:class] ||= 'btn btn-primary'
    opts[:data] ||= {}
    opts[:data][:toggle] = 'modal'
    opts[:data][:target] = "##{id}"
    content_tag(:span, opts) { yield }
  end

  def help_message(title = '', opts = {})
    id = modal(title) { yield }
    opts[:class] ||= ''
    modal_button(id, opts) { fa_icon('question-circle', class: 'hover-help') }
  end

  def yield_modals
    (@modals ||= []).inject(:+)
  end
end

class AdaptableList
  attr :type, :set, :value_names

  def initialize(opts)
    @type = opts[:type]
    @set  = opts[:set]
    @value_names = []
  end

  def css
    { cards: { class: 'card-columns' }, table: { class: 'table table-hover' } }[type]
  end

  def tag
    { cards: :div, table: :table }[type]
  end

  def entry
    AdaptableListEntry.new(self)
  end

  def add_value_name(name)
    @value_names << name unless value_names.include? name
  end
end

class AdaptableListEntry
  attr :list, :footer_blk, :values

  def initialize(list)
    @list       = list
    @footer_blk = nil
    @values     = []
  end

  def type
    list.type
  end

  def css
    { cards: { class: 'card' }, table: {} }[type]
  end

  def tag
    { cards: :div, table: :tr }[type]
  end

  def link_css
    { cards: { class: 'card-header-link' }, table: {} }[type]
  end

  def header_tag
    { cards: :div, table: :th }[type]
  end

  def header_css
    { cards: { class: 'card-header'}, table: {} }[type]
  end

  def content_tag
    { cards: :div, table: nil }[type]
  end

  def content_css
    { cards: { class: 'card-body' }, table: nil }[type]
  end

  def footer(&blk)
    list.add_value_name(nil)
    @footer_blk = blk
  end

  def footer_tag
    { cards: :div, table: :td }[type]
  end

  def footer_css
    { cards: { class: 'card-footer text-right bg-dark-ce' }, table: {} }[type]
  end

  def value(name)
    list.add_value_name(name)
    AdaptableListValue.new(self)
  end
end

class AdaptableListValue
  attr :entry

  def initialize(entry)
    @entry = entry
  end

  def list
    entry.list
  end

  def type
    entry.list.type
  end

  def tag
    { cards: :dd, table: :td }[type]
  end
end

