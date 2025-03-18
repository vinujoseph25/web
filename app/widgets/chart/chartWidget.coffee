###
# Copyright (c) 2013-2018 the original author or authors.
#
# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
#
#     http://www.opensource.org/licenses/mit-license.php
#
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific 
# language governing permissions and limitations under the License. 
###

#
# Chart Widget
#
# Requires a dataService property to load data
# Support dataServices that return object-based data:
#
#    Object-based (keys are columns):
#        [ 
#            {color: "red", number: 1, state: "WA"}
#            {color: "green", number: 41, state: "CA"}
#        ]
#
# Headers are generated by looking at the complete list of data and
# extracting a list of unique columns.  Data Source-provided headers are ignored
# since some columns may have no data.
#

babbleApp.controller 'ChartWidget', ($scope, dashboardService, dataService) ->

    getPlotLineData = (row, rawData = $scope.rawData) ->
        if row.constant 
            row.value = row.constant
        else     
            rawData = rawData[0] ? {}
            data = rawData[row.dataKey] ? []
            values = data[0] ? {}
            value = values[row.valueKey] ? 0
            row.value = value   
        return row

    getChart = ->
        defaults =
            credits:
                enabled: false
            exporting:
                enabled: false
            plotOptions: {}
            title:
                text:  null

        # Merge dashboard options with the defaults
        chartOptions = $scope.widget.highchart
        if !chartOptions.ignorePlotLines?
            if chartOptions.yAxis?
                tempYAxis = _.map chartOptions.yAxis, (el) ->
                                plotLines = el?.plotLines
                                if not el.ignoreRange
                                    seriesMax = _.reduce $scope.rawData[0][el.dataKey], ((a,b) -> Math.max a,b[el.key]), -Infinity
                                    seriesMin = _.reduce $scope.rawData[0][el.dataKey], ((a,b) -> Math.min a,b[el.key]), Infinity
                                if plotLines?
                                    plotLinesUpdated = _.map plotLines, (row) -> getPlotLineData(row, $scope.rawData)
                                    plotLinesValues = _.map plotLinesUpdated, (row) -> row.value
                                    el.plotLines = plotLinesUpdated       
                                    if not el.ignoreRange 
                                        plotLineMax = _.reduce plotLinesValues, (a,b) -> Math.max a,b 
                                        plotLineMin = _.reduce plotLinesValues, (a,b) -> Math.min a,b 
                                        el.max = if plotLineMax > seriesMax then plotLineMax else seriesMax
                                        el.min = if plotLineMin < seriesMin then plotLineMin else seriesMin
                                else if not el.ignoreRange
                                    el.max = seriesMax
                                    el.min = seriesMin
                                return el
            else 
                tempYAxis = []
        chartOptions.yAxis = tempYAxis
        chart = _.merge(defaults, chartOptions)
        # chart = _.merge(defaults, $scope.widget.highchart)
        chart = _.compile(chart, {}, ['series'], true)
        return chart

    getSeries = (series, seriesData = $scope.rawData) ->

        # Compile top-level properties
        series = _.compile series, [], [], false
        if series._x then series.x = series._x
        if series._y then series.y = series._y
        if series._z then series.z = series._z
        if series._point then series.point = series._point

        # Support formating
        xTransform = null
        if series.xFormat?
            xTransform = switch series.xFormat
                when 'epoch' then (d) ->
                    moment.unix(d).valueOf()
                when 'epochmillis' then _.identity
                    # Highcharts handles natively
                when 'string' then (d) ->
                    moment(d).valueOf()
                when 'toString' then (d) ->
                    d.toString()

                else _.identity

        # If point is provided, use it's properties to create point objects
        if series.point?
            series.data = _.map seriesData, (row) ->
                point = _.cloneDeep(series.point)

                # Pull in series x/y/z unless they are defined on the point
                if !point.x? && series.x?
                    point.x = row[series.x]
                if !point.y? && series.y?
                    point.y = row[series.y]
                if !point.z? && series.z?
                    point.z = row[series.z]

                # Evaluate all properties for variables/inline JS
                point = _.compile(point, row, [], true, true)

                # Optional x-transform
                if point.x? && xTransform?
                    point.x = xTransform(point.x)

                # Optional Drilldown
                if point.drilldown?
                    point.drilldown = point.drilldown.toString()

                return point

            # Remove series-level properties since all data has been pulled into the data array
            series._x = series.x
            series._y = series.y
            series._z = series.z
            series._point = series.point
            delete series.x
            delete series.y
            delete series.z
            delete series.point

        # Handle different combinations of x/y/z
        else if series.x? && series.y? && series.z?
            series.data = _.map seriesData, (row) ->
                xValue = row[series.x] ? null
                yValue = row[series.y] ? null
                zValue = row[series.z] ? null

                # Optionally format the x axis
                if xTransform? then xValue = xTransform(xValue)

                return [xValue, yValue, zValue]


        else if series.dataKey? && series.x? && series.y?
            tempData = seriesData[0][series.dataKey] ? null
            series.data = _.map tempData, (row) ->
                xValue = row[series.x] ? null
                yValue = row[series.y] ? null

                # Optionally format the x axis
                if xTransform? then xValue = xTransform(xValue)
                
                return [xValue, yValue]
                
        else if series.x? && series.y?
            series.data = _.map seriesData, (row) ->
                xValue = row[series.x] ? null
                yValue = row[series.y] ? null

                # Optionally format the x axis
                if xTransform? then xValue = xTransform(xValue)

                return [xValue, yValue]

        # Y only
        else if !series.x? && series.y?
            series.data = _.map seriesData, (row) ->
                return row[series.y] ? null

        # X only
        else if !series.y? && series.x?
            series.data = _.map seriesData, (row) ->
                xValue = row[series.x] ? null

                # Optionally format the x axis
                if xTransform? then xValue = xTransform(xValue)

                return xValue

        else
            series.data = []
        

        if series._titleCase
            series.name = _.titleCase series.name

        return series

    $scope.createChart = ->

        # Get the chart options
        chart = getChart()

        # Load the series from the chart
        $scope.series = series = chart.series

        # Use series object if provided, otherwise generate from headers/data
        if _.isNullOrUndefined series
            # Map headers to series
            series = _.map $scope.headers, (header) ->
                { type: 'line', y: header }

        # jsExec the series name, in case it is a function.
        # If it is, it will be used to generate the series name
        _.each series, (s) ->
            s.name = _.jsExec(s.name)

        # Handle wildcard series with '*' or a regex //
        stars = _.filter(series, (s) ->
            return false unless s.y?
            return s.y == '*' || /^\/.*\/$/i.test(s.y)
        )

        if stars?
            remainingSeries = _.reject(series, (s) -> _.contains(stars, s))

            # Handle each star series in order, adding series to remanining series
            _.each stars, (star) ->

                # Get possible y series by excluding other series' x/y fields
                starSeriesY = _.reject $scope.headers, (header) ->
                    return true if star.yIgnore && _.contains(star.yIgnore, header)
                    return true if header == star.x || header == star.z
                    return true if _.some(remainingSeries, (rem) ->
                        return true if header == rem.x
                        return true if header == rem.y
                        return true if header == rem.z
                        return false
                    )

                # Filter series list by regex, if it is a regex
                if /^\/.*\/$/i.test(star.y)
                    r = new RegExp(star.y.substring(1, star.y.length-1), "i")
                    starSeriesY = _.filter starSeriesY, (y) ->
                        return r.test(y)

                remainingSeries = _.union(remainingSeries, _.map(starSeriesY, (y) ->
                    expanded = _.defaults({ y: y }, star)

                    # Expand name if present, otherwise it will just be y
                    if expanded.name?
                        if _.isFunction expanded.name
                            expanded.name = expanded.name(y)
                        else
                            expanded.name = expanded.name + ": " + _.titleCase(y)

                    return expanded
                ))

            # Replace series with expanded list
            series = remainingSeries

        # Ensure each series has a name (use y name if necessary)
        _.each series, (aSeries) ->
            if _.isNullOrUndefined aSeries.name
                aSeries.name = aSeries.y
                aSeries._titleCase = true
            else if _.isFunction aSeries.name
                # Evaluate name function with y value
                aSeries.name = aSeries.name(aSeries.y)

        # Expand each series with the actual data and apply to the chart
        chart.series = _.map series, (s) -> getSeries(s, $scope.rawData)

        # Optional drilldown
        if chart.drilldown?
            # Expand each drilldown series
            expandedSeries = _.map chart.drilldown.series, (drilldownSeries) ->
                # Group the drilldown data by the series key
                groups = _.groupBy $scope.drilldownData, (row) ->
                    _.compile drilldownSeries.key, row

                _.map groups, (group, key) ->
                    s = getSeries _.cloneDeep(drilldownSeries), group
                    s.id = key.toString()
                    return s

            # Flatten and replace
            chart.drilldown.series = _.flatten expandedSeries

        # Set the highcharts object so the directive picks it up.
        $scope.highchart = chart

    $scope.reload = ->
        if $scope.dataSource
            $scope.dataSource.execute(true)

    # Load Main data source
    dsDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget
    $scope.dataSource = dataService.get dsDefinition

    # Initialize
    if $scope.dataSource?
        $scope.dataVersion = 0
        $scope.widgetContext.loading = true

        # Data Source (re)loaded
        $scope.$on 'dataSource:' + dsDefinition.name + ':data', (event, eventData) ->
            return unless eventData.version > $scope.dataVersion
            $scope.dataVersion = eventData.version

            $scope.widgetContext.dataSourceError = false
            $scope.widgetContext.dataSourceErrorMessage = null

            data = eventData.data[dsDefinition.resultSet].data
            data = $scope.filterAndSortWidgetData(data)

            # Check for no data
            if data?
                $scope.rawData = data

                previousHeaders = $scope.headers

                # Generates data headers (e.g. possible series) by inspecting the filtered data set
                # The keys of each row are unioned to get a complete list of columns
                $scope.headers = _.reduce data, (headers, dataRow) ->
                    _.union headers, _.keys(dataRow)
                , []

                $scope.createChart()

            $scope.widgetContext.loading = false

        # Data Source error
        $scope.$on 'dataSource:' + dsDefinition.name + ':error', (event, data) ->
            $scope.widgetContext.dataSourceError = true
            $scope.widgetContext.dataSourceErrorMessage = data.error
            $scope.widgetContext.nodata = null
            $scope.widgetContext.loading = false

        # Data Source loading
        $scope.$on 'dataSource:' + dsDefinition.name + ':loading', ->
            $scope.widgetContext.loading = true

        # Initialize the Data Source
        $scope.dataSource.init dsDefinition

    # Load Drilldown Data Source (optional)
    drilldownDataSourceDefinition = dashboardService.getDataSource $scope.dashboard, $scope.widget, 'drilldownDataSource'
    $scope.drilldownDataSource = dataService.get drilldownDataSourceDefinition

    # Initialize Drilldown Data Source
    if $scope.drilldownDataSource?

        # Drilldown Data Source (re)loaded
        # (ignoring errors and loading events)
        $scope.$on 'dataSource:' + drilldownDataSourceDefinition.name + ':data', (event, eventData) ->

            $scope.drilldownData = eventData.data[dsDefinition.resultSet].data
            $scope.createChart()

        $scope.drilldownDataSource.init drilldownDataSourceDefinition

