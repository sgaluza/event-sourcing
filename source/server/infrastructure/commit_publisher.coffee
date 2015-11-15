
class Space.eventSourcing.CommitPublisher extends Space.Object

  @type 'Space.eventSourcing.CommitPublisher'

  dependencies:
    commits: 'Space.eventSourcing.Commits'
    configuration: 'configuration'
    eventBus: 'Space.messaging.EventBus'
    commandBus: 'Space.messaging.CommandBus'
    ejson: 'EJSON'
    log: 'Space.eventSourcing.Log'

  _publishHandle: null

  startPublishing: ->
    appId = @configuration.appId
    notReceivedYet = receivedBy: $nin: [appId]
    @log "#{this}: Start publishing commits for app #{appId}"
    # Save the observe handle so that it can be stopped later on
    @_publishHandle = @commits.find(notReceivedYet).observe {
      added: (commit) =>
        # We find and lock the event, so that it never gets read twice per app
        lockedCommit = @commits.findAndModify({
          query: $and: [_id: commit._id, notReceivedYet]
          update: $push: { receivedBy: appId }
        })
        # Only publish the event if this process was the one that locked it
        @publishCommit(@_parseCommit(lockedCommit)) if lockedCommit?
    }

  stopPublishing: ->
    @log "#{this}: Stop publishing commits for app #{@configuration.appId}"
    @_publishHandle?.stop()

  publishCommit: (commit) =>
    for event in commit.changes.events
      @log "#{this}: Publishing event #{event.typeName()}\n", event
      @eventBus.publish event
    for command in commit.changes.commands
      @log "#{this}: Publishing command #{command.typeName()}\n", command
      @commandBus.send command

  _parseCommit: (commit) ->
    events = []
    commands = []
    # Only parse events that can be handled by this app
    for event in commit.changes.events
      events.push(@_parseMessage(event)) if @_supportsEjsonType event
    # Only parse commands that can be handled by this app
    for command in commit.changes.commands
      type = JSON.parse(command).$type
      commands.push(@_parseMessage(command)) if @commandBus.hasHandlerFor type

    commit.changes.events = events
    commit.changes.commands = commands
    return commit

  _parseMessage: (message) ->
    try
      return @ejson.parse(message)
    catch error
      throw new Error "while parsing \m:#{message}\nerror:#{error}"

  _supportsEjsonType: (message) -> @ejson._getTypes()[JSON.parse(message).$type]?
