import { useEffect, useState } from 'react'
import useSWR from 'swr'

import { submitFetcher } from '../../shape.helpers'
import { getSubmitPayload } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a save (create/update) a shape object
export default function useShapeController(isEdit, baseURL) {
  const [shouldSubmit, setShouldSubmit] = useState(false)
  const method = isEdit ? 'PUT' : 'POST'

  const onError = errors => {
    // TODO display flash message
  }

  useEffect(() => {
    const sub = eventEmitter.on('shape:submit', () => {
      setShouldSubmit(true)
    })

    return () => sub.unsubscribe()
  }, [])
  
  return useSWR(
    () => shouldSubmit ? `${baseURL}/shapes` : null,
    async url => {
      const state = await store.getStateAsync()

      return submitFetcher(url, method, getSubmitPayload(state))
    },
    { onError }
  )
}