import { useEffect } from 'react'
import { useParams  } from 'react-router-dom'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'
import Collection from 'ol/Collection'

import { getSubmitPayload, simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch / submit a shape object
export default function useShapeController(isEdit, baseURL) {
  // Route params
  const { action } = useParams()

  // Fetch Shape
  const { mutate: fetchShape } = useSWR(...Params.fetch(`${baseURL}/shapes/${action}`))
  
  // Submit Shape
  const { mutate: submitShape } = useSWR(...Params.submit(`${baseURL}/shapes`, isEdit))

  useEffect(() => {
    eventEmitter.on('shape:submit', submitShape)
    eventEmitter.on('map:init', fetchShape)
  }, [])
}
class Params {
  static fetch = url => [
    url,
    {
      onSuccess(data) {
        const [line, ...fetchedWaypoints] = new GeoJSON().readFeatures(simplifyGeoJSON(data), wktOptions)

        const waypoints = new Collection(fetchedWaypoints)

        store.setAttributes({ line, waypoints })

        eventEmitter.emit('shape:receive-features', line, waypoints)
      },
      revalidateOnMount: false
    }
  ]

  static submit = (url, isEdit) => [
    url,
    async url => {
      const state = await store.getStateAsync()

      return submitFetcher(url, isEdit, getSubmitPayload(state))
    },
    {
      onError(errors) {
        errors.forEach(text => {
          window.Spruce.stores.flash.add({ type: 'error', text })
        })
      },
      revalidateOnMount: false
    }
  ]
}
