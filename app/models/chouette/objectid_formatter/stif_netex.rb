class Chouette::ObjectidFormatter::StifNetex
  def before_validation(model)
    model.attributes = {objectid: "__pending_id__#{SecureRandom.uuid}"} unless model.read_attribute(:objectid)
  end

  def after_commit(model)
    model.update_attributes(objectid: Chouette::Objectid::StifNetex.new(provider_id: "stif", object_type: model.class.name.gsub(/Chouette::/,''), local_id: model.local_id).to_s)
  end

  def get_objectid(definition)
    parts = definition.try(:split, ":")
    Chouette::Objectid::StifNetex.new(provider_id: parts[0], object_type: parts[1], local_id: parts[2], creation_id: parts[3]) rescue nil
  end
end