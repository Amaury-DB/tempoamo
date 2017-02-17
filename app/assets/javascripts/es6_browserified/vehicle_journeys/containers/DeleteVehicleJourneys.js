var actions = require('../actions')
var connect = require('react-redux').connect
var DeleteVJComponent = require('../components/DeleteVehicleJourneys')

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onDeleteVehicleJourneys: () =>{
      dispatch(actions.deleteVehicleJourneys())
    },
  }
}

const DeleteVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(DeleteVJComponent)

module.exports = DeleteVehicleJourneys
