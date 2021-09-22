class Name < ApplicationRecord
  has_many :publication_names, dependent: :destroy
  has_many :publications, through: :publication_names
  belongs_to :proposed_by, optional: true,
    class_name: 'Publication', foreign_key: 'proposed_by'
  belongs_to :corrigendum_by, optional: true,
    class_name: 'Publication', foreign_key: 'corrigendum_by'
  belongs_to :parent, optional: true, class_name: 'Name'
  belongs_to :created_by, optional: true,
    class_name: 'User', foreign_key: 'created_by'
  belongs_to :submitted_by, optional: true,
    class_name: 'User', foreign_key: 'submitted_by'
  belongs_to :validated_by, optional: true,
    class_name: 'User', foreign_key: 'validated_by'

  has_rich_text :description
  has_rich_text :notes
  has_rich_text :etymology_text
  
  validates :name, presence: true, uniqueness: true
  validates :syllabication,
    format: {
      with: /\A[A-Z\.'-]*\z/i,
      message: 'Only letters, dashes, dots, and apostrophe are allowed'
    }

  class << self
    def etymology_particles
      %i[p1 p2 p3 p4 p5 xx]
    end

    def etymology_fields
      %i[lang grammar particle description]
    end

    def ranks
      %w[domain phylum class order family genus species]
    end

    def status_hash
      {
        0 => {
          symbol: :auto, name: 'Automated discovery',
          public: true, valid: false,
          help: <<~TXT
            This name was automatically created by the system and has not
            undergone expert review
          TXT
        },
        5 => {
          symbol: :draft, name: 'Draft',
          public: false, valid: false,
          help: <<~TXT
            This name was created by an author or other registered user,
            and has not undergone expert review
          TXT
        },
        10 => {
          symbol: :submit, name: 'Submitted',
          public: false, valid: false,
          help: <<~TXT
            This name has been submitted for review by the author or other
            registered user and cannot be modified until expert review takes
            place
          TXT
        },
        15 => {
          symbol: :seqcode, name: 'Valid (SeqCode)',
          public: true, valid: true,
          help: <<~TXT
            This name has been validly published under the rules of the SeqCode
            and has priority in the scientific record
          TXT
        },
        20 => {
          symbol: :icnp, name: 'Valid (ICNP)',
          public: true, valid: true,
          help: <<~TXT
            This name has been validly published under the rules of the ICNP
            and has priority in the scientific record
          TXT
        }
      }
    end

    def public_status
      status_hash.select { |_, v| v[:public] }.keys
    end

    def valid_status
      status_hash.select { |_, v| v[:valid] }.keys
    end

    def type_material_hash
      {
        name: { name: 'Name', sp: false },
        nuccore: { name: 'INSDC Nucleotide', sp: true },
        assembly: { name: 'NCBI Assembly', sp: true },
        other: { name: 'Other', sp: true }
      }
    end
  end

  def candidatus?
    name.match? /^Candidatus /
  end

  def abbr_name(name = nil)
    name ||= self.name
    if candidatus?
      name.gsub(/^Candidatus /, '<i>Ca.</i> ').html_safe
    elsif validated?
      "<i>#{name}</i>".html_safe
    else
      "&#8220;#{name}&#8221;".html_safe
    end
  end

  def name_html(name = nil)
    name ||= self.name
    if candidatus?
      name.gsub(/^Candidatus /, '<i>Candidatus</i> ').html_safe
    elsif validated?
      "<i>#{name}</i>".html_safe
    else
      "&#8220;#{name}&#8221;".html_safe
    end
  end

  def abbr_corr_name
    abbr_name(corrigendum_from)
  end

  def corr_name_html
    name_html(corrigendum_from)
  end

  def formal_html
    y = name_html
    y = "&#8220;#{y}&#8221;" if candidatus?
    y += " corrig." if corrigendum_by
    y += " #{proposed_by.short_citation}" if proposed_by
    y.html_safe
  end

  def status_hash
    self.class.status_hash[status]
  end

  def status_name
    status_hash[:name]
  end

  def status_help
    status_hash[:help].gsub(/\n/, ' ')
  end

  def status_symbol
    status_hash[:symbol]
  end

  def validated?
    status_hash[:valid]
  end

  def public?
    status_hash[:public]
  end

  def last_epithet
    name.gsub(/.* /, '')
  end

  def etymology(component, field)
    component = component.to_sym
    component = :xx if component == :full
    field = field.to_sym
    if component == :xx && field == :particle
      last_epithet
    else
      y = send(:"etymology_#{component}_#{field}")
      y.nil? || y.empty? ? nil : y
    end
  end

  def etymology?
    return true if etymology_text?

    Name.etymology_particles.any? do |i|
      Name.etymology_fields.any? { |j| etymology(i, j) }
    end
  end

  def full_etymology(html = false)
    if etymology_text?
      y = etymology_text.body
      return(html ? y : y.to_plain_text)
    end

    y = Name.etymology_particles.map do |component|
      partial_etymology(component, html)
    end.compact.join('; ')
    y.empty? ? nil : html ? y.html_safe : y
  end

  def partial_etymology(component, html = false)
    pre = [etymology(component, :lang), etymology(component, :grammar)].compact.join(' ')
    pre = nil if pre.empty?
    par = etymology(component, :particle)
    des = etymology(component, :description)
    if html
      pre = "<b>#{pre}</b>" if pre
      par = "<i>#{par}</i>" if par
    end
    y = [[pre, par].compact.join(' '), des].compact.join(', ')
    y.empty? ? nil : html ? y.html_safe : y
  end

  def ncbi_search_url
    q = "%22#{name}%22"
    unless corrigendum_from.nil? || corrigendum_from.empty?
      q += " OR %22#{corrigendum_from}%22"
    end
    "https://www.ncbi.nlm.nih.gov/nuccore/?term=#{q}".gsub(' ', '%20')
  end

  def proposed_by?(publication)
    publication == proposed_by
  end

  def corrigendum_by?(publication)
    publication == corrigendum_by
  end

  def emended_by
    publication_names.where(emends: true).map(&:publication)
  end

  def emended_by?(publication)
    emended_by.include? publication
  end

  def children
    @children ||= Name.where(parent: self)
  end

  def inferred_rank
    @inferred_rank ||=
      if rank
        rank
      elsif %w[Archaea Bacteria Eukarya].include?(name)
        'domain'
      elsif name.sub(/^Candidatus /, '') =~ / /
        'species'
      elsif name =~ /aceae$/
        'family'
      elsif name =~ /ales$/
        'order'
      elsif name =~ /ia$/
        if children.first&.inferred_rank&.== 'species'
          'genus'
        else
          'class'
        end
      elsif name =~ /ota$/
        'phylum'
      else
        'genus'
      end
  end

  def links?
    ncbi_taxonomy?
  end

  def ncbi_taxonomy_url
    return unless ncbi_taxonomy?

    'https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=%i' % ncbi_taxonomy
  end

  def ncbi_genomes_url
    return unless ncbi_taxonomy?

    'https://www.ncbi.nlm.nih.gov/datasets/genomes/?txid=%i' % ncbi_taxonomy
  end

  def type?
    type_material? && type_accession?
  end

  def type_is_name?
    type? && type_material == 'name'
  end

  def type_link
    @type_link ||=
      case type_material
      when 'assembly', 'nuccore'
        "https://www.ncbi.nlm.nih.gov/#{type_material}/#{type_accession}"
      end
  end

  def type_name
    if type_is_name?
      @type_name ||= Name.where(id: type_accession).first
    end
  end

  def type_material_name
    self.class.type_material_hash[type_material.to_sym][:name] if type?
  end

  def type_text
    if type?
      @type_text ||= "#{type_material_name}: #{type_accession}"
    end
  end

  def possible_type_materials
    self.class.type_material_hash.select do |_, v|
      v[:sp] == (inferred_rank == 'species')
    end
  end

  def user?(user)
    created_by == user
  end

  def can_see?(user)
    return true if self.public?

    (!user.nil?) && (user.curator? || user?(user))
  end

  def can_edit?(user)
    return false if user.nil?
    return false if status >= 15
    return true if user.curator?
    return true if status == 5 && user?(user)
    false
  end

  def can_claim?(user)
    return false unless user.contributor? && created_by.nil?
    status <= 10
  end
end
