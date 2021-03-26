$('#export_export_type').on('change', e => {
  const { value: type } = e.target
  const baseUrl = window.location.href.split('/new')[0]

  if (type == 'line') {
    $("#export_export_type_slave").load(`${baseUrl}/refresh_form?_action=set_export_type&type=Export::Netex&export_form=line`)
  } else {
    $("#export_export_type_slave").html('')
  }
})