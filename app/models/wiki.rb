# frozen_string_literal: true
# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#

class Wiki < ActiveRecord::Base
  has_many :articles
  has_many :assignments
  has_many :revisions
  has_many :courses

  before_validation :ensure_valid_project

  # Language / project combination must be unique
  validates_uniqueness_of :project, scope: :language

  PROJECTS = %w(
    wikibooks
    wikidata
    wikinews
    wikipedia
    wikiquote
    wikisource
    wikiversity
    wikivoyage
    wiktionary
  ).freeze
  validates_inclusion_of :project, in: PROJECTS

  LANGUAGES = [nil] + %w(
    aa ab ace af ak als am an ang ar arc arz as ast av ay az azb
    ba bar bat-smg bcl be be-tarask be-x-old bg bh bi bjn bm bn bo bpy br bs
    bug bxr ca cbk-zam cdo ce ceb ch cho chr chy ckb cmn co cr crh cs csb cu
    cv cy cz da de diq dk dsb dv dz ee egl el eml en eo epo es et eu ext fa
    ff fi fiu-vro fj fo fr frp frr fur fy ga gag gan gd gl glk gn gom got gsw
    gu gv ha hak haw he hi hif ho hr hsb ht hu hy hz ia id ie ig ii ik ilo io
    is it iu ja jbo jp jv ka kaa kab kbd kg ki kj kk kl km kn ko koi kr krc
    ks ksh ku kv kw ky la lad lb lbe lez lg li lij lmo ln lo lrc lt ltg lv
    lzh mai map-bms mdf mg mh mhr mi min minnan mk ml mn mo mr mrj ms mt mus
    mwl my myv mzn na nah nan nap nb nds nds-nl ne new ng nl nn no nov nrm
    nso nv ny oc om or os pa pag pam pap pcd pdc pfl pi pih pl pms pnb pnt ps
    pt qu rm rmy rn ro roa-rup roa-tara ru rue rup rw sa sah sc scn sco sd se
    sg sgs sh si simple sk sl sm sn so sq sr srn ss st stq su sv sw szl ta te
    tet tg th ti tk tl tn to tpi tr ts tt tum tw ty tyv udm ug uk ur uz ve
    vec vep vi vls vo vro w wa war wikipedia wo wuu xal xh xmf yi yo yue za
    zea zh zh-cfr zh-classical zh-cn zh-min-nan zh-tw zh-yue zu
  ).freeze
  validates_inclusion_of :language, in: LANGUAGES

  MULTILINGUAL_PROJECTS = {
    'wikidata' => 'www.wikidata.org'
  }.freeze

  def base_url
    if language
      "https://#{language}.#{project}.org"
    else
      "https://#{MULTILINGUAL_PROJECTS[project]}"
    end
  end

  def api_url
    "#{base_url}/w/api.php"
  end

  #############
  # Callbacks #
  #############

  def ensure_valid_project
    # Multilingual projects must have language == nil.
    # Standard projects must have a language.
    if MULTILINGUAL_PROJECTS.include?(project)
      self.language = nil
    elsif language.nil?
      raise InvalidWikiError
    end
    # TODO: Validate the language/project combination by pinging its API.
  end

  class InvalidWikiError < StandardError; end

  #################
  # Class methods #
  #################

  # This provides fallback values for when a course is created without setting
  # an explicit home wiki language or project
  def self.default_wiki
    get language: ENV['wiki_language'], project: 'wikipedia'
  end

  def self.get(language:, project:)
    language = nil if MULTILINGUAL_PROJECTS.include?(project)
    find_or_create_by(language: language, project: project)
  end
end
