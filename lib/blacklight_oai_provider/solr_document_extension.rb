# Meant to be applied on top of SolrDocument to implement
# methods required by the ruby-oai provider
module BlacklightOaiProvider::SolrDocumentExtension
  def timestamp
    Time.parse get('timestamp')
  end

  def to_oai_qdc
    export_as('oai_qdc_xml')
  end
end
