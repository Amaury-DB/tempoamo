var React = require('react')
var render = require('react-dom').render
var Provider = require('react-redux').Provider
var createStore = require('redux').createStore
var journeyPatternsApp = require('./reducers')
var App = require('./components/App')

// logger, DO NOT REMOVE
var applyMiddleware = require('redux').applyMiddleware
var createLogger = require('redux-logger')
var thunkMiddleware = require('redux-thunk').default
var promise = require('redux-promise')

var initialState = {
  journeyPatterns: [],
  pagination: 1,
  totalCount: window.journeyPatternLength,
  modal: {
    open: false,
    modalProps: {}
  }
}
const loggerMiddleware = createLogger()

let store = createStore(
  journeyPatternsApp,
  initialState,
  applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
)

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('journey_patterns')
)
