class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  @@search_obj = {
    publications: [Publication, %w[title doi journal abstract]],
    authors: [Author, %w[given family]],
    names: [Name, %w[name description corrigendum_from]],
    subjects: [Subject, %w[name]]
  }

  def main
    @publications = Publication.all.order(journal_date: :desc)
    @authors = Author.all.order(created_at: :desc)
    @names = Name.where('name LIKE "Candidatus %"').order(created_at: :desc)
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

  protected

    def authenticate_admin!
      authenticate_role! :admin?
    end

    def authenticate_contributor!
      authenticate_role! :contributor?
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
