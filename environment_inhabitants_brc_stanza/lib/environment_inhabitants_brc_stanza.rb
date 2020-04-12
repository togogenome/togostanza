require 'togostanza'
require_relative '../stanza'

EnvironmentInhabitantsBrcStanza.root = File.expand_path('../..', __FILE__)

TogoStanza.sprockets.append_path File.expand_path('../../assets', __FILE__)
