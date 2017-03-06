var React = require('react')
var connect = require('react-redux').connect
var actions = require('../actions')
var SaveVehicleJourneysComponent = require('../components/SaveVehicleJourneys')

// let SaveVehicleJourneys = ({ dispatch, vehicleJourneys, page, status }) => {
//   if(status.isFetching == true) {
//     return false
//   }
//   if(status.fetchSuccess == true) {
//     return (
//       <form className='clearfix' onSubmit={e => {e.preventDefault()}}>
//         <button
//           className='btn btn-danger pull-right'
//           type='submit'
//           onClick={e => {
//             e.preventDefault()
//             actions.submitVehicleJourneys(dispatch, vehicleJourneys)
//           }}
//           >
//           Valider
//         </button>
//       </form>
//     )
//   } else {
//     return false
//   }
// }

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys,
    page: state.pagination.page,
    status: state.status
  }
}

const SaveVehicleJourneys = connect(mapStateToProps)(SaveVehicleJourneysComponent)

module.exports = SaveVehicleJourneys
