
ProcessManager = Space.cqrs.ProcessManager

describe "#{ProcessManager}", ->

  class TestCommand
    type: 'TestCommand'

  beforeEach ->
    @processManager = new ProcessManager '123'

  it 'extends aggregate root', ->

    expect(ProcessManager.__super__.constructor).to.equal Space.cqrs.Aggregate

  describe 'working with commands', ->

    it 'a processManager generates no commands by default', ->
      expect(@processManager.getCommands()).to.be.empty

    it 'allows to add commands', ->
      command = new TestCommand()
      @processManager.trigger command

      expect(@processManager.getCommands()).to.eql [command]

  describe 'working with state', ->

    it 'has no state by default', ->
      expect(@processManager.hasState()).to.be.false

    it 'can transition to a state', ->
      state = 0
      @processManager.transitionTo state

      expect(@processManager.hasState(state)).to.be.true

    it 'can be asked if it has any state at all', ->
      @processManager.transitionTo 0

      expect(@processManager.hasState()).to.be.true