import { simplify } from '@turf/turf'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import store from './shape.store'

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

export const getLine = features => features.find(f => f.getGeometry().getType() == 'LineString')
export const getLineSegments = feature => {
  const segments = []

  feature.getGeometry().forEachSegment((start, end) => {
    segments.push({ start, end })
  })

  return segments
}

export const getWaypoints = features => features.filter(f => f.getGeometry().getType() == 'Point')

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance

export const addMapInteractions = (source, map, waypoints) => {
  const modify = new Modify({ features: waypoints })
  const draw = new Draw({ source, features: waypoints, type: 'Point' })
  const snap = new Snap({ source })
  const interactions = [modify, draw, snap]

  interactions.forEach(i => map.addInteraction(i))
  store.setAttributes({ draw, modify, snap })
}

export const lineId = 'line'

export const wktOptions = isEdit => ({ //  use options to convert feature from EPSG:4326 to EPSG:3857
  dataProjection: isEdit ? 'EPSG:3857': 'EPSG:4326',
  featureProjection: 'EPSG:3857'
})

export const submitFetcher = async (url, method, payload) => {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json', 
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
    },
    body: JSON.stringify(payload)
  })

  // Way to handle redirection on json request
  for (const [name, value] of response.headers.entries()) {
    if (name == 'location') {
      const { location, sessionStorage } = window
      const previousShapeAction = method = 'POST' ? 'shape-created' : 'shape-updated'
      
      sessionStorage.setItem('previousShapeAction', previousShapeAction) // Being used in JP react app to display or not a flash message
      location.assign(value)
    }
  }

  const data = await response.json() 

  if (!response.ok) {
    throw data['errors']
  }

  return data
}