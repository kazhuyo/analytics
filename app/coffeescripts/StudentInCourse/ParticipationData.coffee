define [ 'analytics/compiled/BaseData' ], (BaseData) ->

  ##
  # Loads the participation data for the student and course. Exposes the data
  # as the 'pageViews' and 'participations' properties once loaded.
  class ParticipationData extends BaseData
    constructor: (student) ->
      course = student.get('course')
      super "/api/v1/courses/#{course.get 'id'}/analytics/users/#{student.get 'id'}/activity"

    populate: (data) ->
      @bins = []

      # maintain one unique bin per date, order of insertion into @bins
      # unimportant
      binMap = {}
      binFor = (date) =>
        if !binMap[date]?
          binMap[date] =
            date: date
            views: 0
            participations: 0
            participation_events: []
          @bins.push binMap[date]
        binMap[date]

      # sort the page view data to the appropriate bins
      for date, views of data.page_views
        # this date is the utc date for the bin, not local. but we'll treat it
        # as local for the purposes of presentation.
        bin = binFor(Date.parse date)
        bin.views += views

      # sort the participation date to the appropriate bins
      for event in data.participations
        event.createdAt = Date.parse event.created_at
        # bin to the utc date corresponding to event.createdAt, so that all
        # participations fall in the same bin as their respective page views.
        offset = event.createdAt.getTimezoneOffset()
        date = event.createdAt.clone().addMinutes(offset).clearTime()
        bin = binFor(date)
        bin.participation_events.push event
        bin.participations += 1
