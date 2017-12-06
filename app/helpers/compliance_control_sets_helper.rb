module ComplianceControlSetsHelper

  def organisations_filters_values
    [current_organisation, Organisation.find_by_name("STIF")].uniq
  end

  def floating_links ccs_id
    links = [new_control(ccs_id), new_block(ccs_id)]
    if links.any?
      content_tag :div, class: 'select_toolbox', id: 'floating-links' do
        content_tag :ul do
          links.collect {|link| concat content_tag(:li, link, class: 'st_action with_text') if link} 
        end
      end
    end
  end

  def new_control ccs_id
    if policy(ComplianceControl).create?
      link_to select_type_compliance_control_set_compliance_controls_path(ccs_id) do 
        concat content_tag :span, nil, class: 'fa fa-plus'
        concat content_tag :span, t('compliance_control_sets.actions.add_compliance_control')
      end
    end
  end

  def new_block ccs_id
    if policy(ComplianceControlBlock).create?
      link_to new_compliance_control_set_compliance_control_block_path(ccs_id) do 
        concat content_tag :span, nil, class: 'fa fa-plus'
        concat content_tag :span,t('compliance_control_sets.actions.add_compliance_control_block')
      end   
    end
  end
end
