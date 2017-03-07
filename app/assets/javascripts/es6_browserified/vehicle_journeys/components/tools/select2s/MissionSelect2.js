var React = require('react')
var PropTypes = require('react').PropTypes
var Select2 = require('react-select2')

// get JSON full path
var origin = window.location.origin
var path = window.location.pathname.split('/', 7).join('/')


class BSelect4 extends React.Component{
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <Select2
        defaultValue=''
        onSelect={(e) => this.props.onSelect2JourneyPattern(e) }
        ref='journey_pattern_id'
        options={{
          placeholder: 'Nom d\'une mission existante',
          allowClear: false,
          language: 'fr', /* Doesn't seem to work... :( */
          theme: 'bootstrap',
          width: '100%',
          ajax: {
            url: origin + path + '/journey_patterns_collection.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                q: {published_name_cont: params.term},
              };
            },
            processResults: function(data, params) {

              return {
                results: data.map(
                  item => Object.assign(
                    {},
                    item,
                    {text: item.published_name}
                  )
                )
              };
            },
            cache: true
          },
          minimumInputLength: 3,
          templateResult: formatRepo
        }}
      />
    )
  }
}

const formatRepo = (props) => {
  if(props.text) return props.text
}

module.exports = BSelect4
