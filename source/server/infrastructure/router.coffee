class Space.eventSourcing.Router extends Space.messaging.Controller

  @type 'Space.eventSourcing.Router'

  @ERRORS: {

    aggregateNotSpecified: 'Please specify a Router::aggregate class to be
    managed by the router.'

    missingInitializingCommand: 'Please specify Router::initializingCommand (a command class)
    that will be used to create new instanes of the managed aggregate.'

    noAggregateFoundToHandleCommand: (command) ->
      new Error "No aggregate <#{command.targetId}> found to
                 handle #{command.typeName()}"
  }

  dependencies: {
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'Space.eventSourcing.Log'
  }

  aggregate: null
  initializingCommand: null
  routeCommands: null

  constructor: ->
    if not @aggregate?
      throw new Error Router.ERRORS.aggregateNotSpecified
    if not @initializingCommand?
      throw new Error Router.ERRORS.missingInitializingCommand
    @routeCommands ?= []
    super

  onDependenciesReady: ->
    super
    @commandBus.registerHandler @initializingCommand, (cmd) =>
      @log "#{this}: Creating new #{@aggregate} with command #{cmd.typeName()}\n", cmd
      @repository.save new @aggregate(cmd)
    @_routeCommandToAggregate(commandType) for commandType in @routeCommands

  _routeCommandToAggregate: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _genericCommandHandler: (command) =>
    if not command? then return
    @log "#{this}: Handling command #{command.typeName()} for
          #{@aggregate}<#{command.targetId}>\n", command
    aggregate = @repository.find @aggregate, command.targetId
    if not aggregate?
      throw Router.ERRORS.noAggregateFoundToHandleCommand(command)
    aggregate.handle command
    @repository.save aggregate