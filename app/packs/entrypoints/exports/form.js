Spruce.store('export', {
	ready: true,
	type: 'Export::Gtfs',
	exportedLines: 'all_line_ids',
	period: 'all_periods',
	referentialId: '',
	isExport: null,
	workbenchOrWorkgroupId: location.pathname.match(/(\d+)/)[0],
	setSelectURL(select, name) {
		let prefix

		if (this.isExport) {
			prefix = (name == 'line_providers') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/referentials/${this.referentialId}`
		} else {
			prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
		}

		select.dataset.url = `${prefix}/autocomplete/${name}`
	},
	setState(newState) {
		Object.entries(newState).forEach(([key, value]) => {
			this[key] = value
		})
	},
})

Spruce.watch('export.isExport', isExport => {
	const { export: store } = Spruce.stores

	!isExport && store.setState({ exportType: 'full' })

	store.setState({
		baseName: isExport ? 'export_options' : 'publication_setup_export_options'
	})
})

Spruce.watch('export.referentialId', _referentialId => {
	const { export: store } = Spruce.stores

	Array.of(
		['line_ids', 'lines'],
		['company_ids', 'companies']
	).forEach(([inputName, name]) => {
		const input = document.getElementById(`${store.baseName}_${inputName}`)

		if (input) {
			input.tomselect.clear()
			input.tomselect.clearOptions()
			store.setSelectURL(input, name)
			input.tomselect.load('')
		}
	})
})