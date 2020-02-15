class Animes::Filters::ByStudio < Animes::Filters::FilterBase
  def call
    scope = @scope

    positives.each do |term|
      scope = scope.where term_sql(term)
    end
    negatives.each do |term|
      scope = scope.where.not term_sql(term)
    end

    scope
  end

private

  def term_sql term
    term_with_clones = Studio.related(term.to_i)
    "studio_ids && '{#{term_with_clones.join(',')}}'"
  end
end