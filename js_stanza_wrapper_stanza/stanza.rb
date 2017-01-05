class JsStanzaWrapperStanza < TogoStanza::Stanza::Base
  property :params do |server, name, options|
    { "server" => server, "name" => name, "options" => options }
  end
end
