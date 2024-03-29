class ApplicationController < ActionController::Base
  include PageHelper

  protect_from_forgery(with: :exception)
  
  @@search_obj = {
    publications: [Publication, %w[title doi journal abstract]],
    authors: [Author, %w[given family]],
    names: [Name, %w[name corrigendum_from]],
    # TODO Include description (rich-text) as field of names
    subjects: [Subject, %w[name]]
  }

  def main
    @publications = Publication.all.order(journal_date: :desc)
    @authors = Author.all.order(created_at: :desc)
    @names =
      Name.where(status: Name.public_status)
          .where('name LIKE "Candidatus %"')
          .or(Name.where(status: 15))
          .order(created_at: :desc)
  end

  def search
    if [:what, :q].any? { |i| params[i].nil? }
      render :search_query
    else
      @what = params[:what].to_sym
      if @@search_obj[@what]
        @q = params[:q]
        @results = search_by(@what, @q).paginate(
          page: params[:page],
          per_page: @what == :authors ? 100 : @what == :publications ? 10 : 30
        )
        redirect_to @results.first if @results.count == 1
      else
        flash[:danger] = 'Unsupported object.'
        redirect_to root_url
      end
    end
  end

  def search_query
  end

  # GET /set/list
  def set_list
    list_preference = cookies['list'] || 'cards'
    cookies.permanent[:list] = list_preference == 'cards' ? 'table' : 'cards'
    redirect_back(fallback_location: root_url)
  end

  # GET /link/Patescibacteria
  # GET /link/Patescibacteria.json
  def short_link
    par = { format: params[:format] }
    params[:path] ||= ''
    params[:path].sub!(/\A\/+/, '')
    params[:path].sub!(/\/+\z/, '')
    case params[:path]
    when /\Ap:(.+)\z/
      redirect_to(page_url($1))
    when /\A(i:)?(\d+)\z/
      redirect_to(name_url(Name.where(id: $2).first, par))
    when /\A(n:)?([a-z_\. ]+)\z/i
      name = $2.gsub('_', ' ')
      redirect_to(name_url(Name.find_by_variants(name), par))
    when /\A(r:.+)\z/i
      redirect_to(register_url(Register.where(accession: $1).first, par))
    else
      redirect_to(root_url)
    end
  end

  protected

    def authenticate_admin!
      authenticate_role! :admin?
    end

    def authenticate_contributor!
      authenticate_role! :contributor?
    end

    def authenticate_curator!
      authenticate_role! :curator?
    end

    def authenticate_editor!
      authenticate_role! :editor?
    end

  private

    def search_by(k, q)
      obj = @@search_obj[k]
      o = obj[0].none
      if q =~ /^(\S+)::(.+)/ && obj[1].include?($1)
        o = o.or(obj[0].where("LOWER(#{$1}) = ?", $2.downcase))
      else
        obj[1].each do |i|
          o = o.or(obj[0].where("LOWER(#{i}) LIKE ?", "%#{q.downcase}%"))
        end
      end
      o
    end

    def authenticate_role!(role)
      unless current_user.try(role)
        flash[:alert] = 'Action not allowed'
	redirect_to root_path
      end
    end

end
