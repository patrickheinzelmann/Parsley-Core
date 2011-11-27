package org.spicefactory.parsley.command {

import org.flexunit.assertThat;
import org.hamcrest.collection.array;
import org.hamcrest.collection.arrayWithSize;
import org.hamcrest.number.greaterThanOrEqualTo;
import org.hamcrest.object.equalTo;
import org.spicefactory.lib.command.data.CommandData;
import org.spicefactory.lib.command.events.CommandFailure;
import org.spicefactory.lib.errors.AbstractMethodError;
import org.spicefactory.lib.errors.IllegalStateError;
import org.spicefactory.parsley.command.observer.CommandObservers;
import org.spicefactory.parsley.command.observer.CommandStatusFlags;
import org.spicefactory.parsley.command.target.AsyncCommand;
import org.spicefactory.parsley.command.trigger.Trigger;
import org.spicefactory.parsley.command.trigger.TriggerA;
import org.spicefactory.parsley.command.trigger.TriggerB;
import org.spicefactory.parsley.core.bootstrap.ConfigurationProcessor;
import org.spicefactory.parsley.core.command.CommandManager;
import org.spicefactory.parsley.core.command.ObservableCommand;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.scope.ScopeName;
import org.spicefactory.parsley.dsl.context.ContextBuilder;

/**
 * @author Jens Halm
 */
public class MapCommandTestBase {
	
	
	private var context: Context;
	private var manager: CommandManager;
	
	private var status: CommandStatusFlags;
	private var observers: CommandObservers;
	
	private var lastCommand: AsyncCommand;
	
	
	private function configure (mapCommandConfig: ConfigurationProcessor) : void {
		context = ContextBuilder.newBuilder().config(mapCommandConfig).config(observerConfig).build();
		manager = context.scopeManager.getScope(ScopeName.GLOBAL).commandManager;
		status = context.getObjectByType(CommandStatusFlags) as CommandStatusFlags;
		observers = context.getObjectByType(CommandObservers) as CommandObservers;
	}
	
	[Test]
	public function noMatchingCommand () : void {

		configure(singleCommandConfig);		
		
		validateManager(0);
		
		dispatch("foo");
		validateManager(0);

	}
	
	[Test]
	public function singleCommand () : void {
		
		configure(singleCommandConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(1);
		validateStatus(true);
		validateResults();
		
		complete(0, true);
		
		validateManager(0);
		validateStatus(false);
		validateResults(true);
		validateLifecycle();
		
	}
	
	[Test]
	public function commandSequence () : void {
		
		configure(commandSequenceConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(1);
		validateStatus(true);
		validateResults();
		
		complete(0);
		
		validateManager(1);
		validateStatus(true);
		validateResults("1");
		validateLifecycle();

		complete(0);
		
		validateManager(0);
		validateStatus(false);
		validateResults("1", "2");
		validateLifecycle();
		
	}
	
	[Test]
	public function parallelCommands () : void {
		
		configure(parallelCommandsConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(2);
		validateStatus(true);
		validateResults();
		
		complete(0);
		
		validateManager(1);
		validateStatus(true);
		validateResults("1");
		validateLifecycle();

		complete(0);
		
		validateManager(0);
		validateStatus(false);
		validateResults("1", "2");
		validateLifecycle();
		
	}
	
	[Test]
	public function commandFlow () : void {
		
		configure(commandFlowConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(1);
		validateStatus(true);
		validateResults();
		
		complete(0);
		
		validateManager(1);
		validateStatus(true);
		validateResults("1");
		validateLifecycle();

		complete(0);
		
		validateManager(0);
		validateStatus(false);
		validateResults("1", "2");
		validateLifecycle();
		
	}
	
	[Test]
	public function cancelSequence () : void {
		
		configure(commandSequenceConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(1);
		validateStatus(true);
		validateResults();
		
		complete(0);
		
		validateManager(1);
		validateStatus(true);
		validateResults("1");
		validateLifecycle();

		cancel(0);
		
		validateManager(0);
		validateStatus(false);
		validateResults("1");
		validateLifecycle();
		
	}
	
	[Test]
	public function errorInSequence () : void {
		
		configure(commandSequenceConfig);
		
		validateManager(0);
		
		dispatch(new TriggerA());
		
		validateManager(1);
		validateStatus(true);
		validateResults();
		
		complete(0);
		
		validateManager(1);
		validateStatus(true);
		validateResults("1");
		validateLifecycle();

		var e:Object = new IllegalStateError();
		complete(0, e);
		
		validateManager(0);
		validateStatus(false);
		validateResults("1");
		validateError(e);
		validateLifecycle();
		
	}
	
	
	private function dispatch (msg: Object): void {
		context.scopeManager.dispatchMessage(msg); 
	}
	
	private function complete (index: uint, result: Object = null): void {
		setLastCommand(index);
		if (result) lastCommand.result = result;
		lastCommand.invokeCallback();
	}
	
	private function cancel (index: uint, result: Object = null): void {
		setLastCommand(index);
		lastCommand.cancel();
	}
	
	private function setLastCommand (index: uint): void {
		var commands:Array = getActiveCommands(Trigger, AsyncCommand);
		assertThat(commands.length, greaterThanOrEqualTo(index + 1));
		lastCommand = commands[index].command as AsyncCommand;
	}
	
	private function validateManager (cnt: uint): void {
		var commands:Array = getActiveCommands(Trigger, AsyncCommand);
		assertThat(commands, arrayWithSize(cnt));
		commands = getActiveCommands(TriggerA, AsyncCommand);
		assertThat(commands, arrayWithSize(cnt));
		commands = getActiveCommands(TriggerB, AsyncCommand);
		assertThat(commands, arrayWithSize(0));
	}
	
	private function getActiveCommands (trigger: Class, command: Class): Array {
		var commands:Array = manager.getActiveCommandsByTrigger(trigger);
		var result:Array = new Array();
		for each (var com:ObservableCommand in commands) {
			if (com.command is command) result.push(com);
		}
		return result;
	}
	
	private function validateStatus (active: Boolean, result: Object = null, error: Object = null): void {
		assertThat(status.trigger, equalTo(active));
		assertThat(status.triggerA, equalTo(active));
		assertThat(status.triggerB, equalTo(false));
	}
	
	private function validateResults (...results): void {
		assertThat(removeExecutorResults(observers.results), array(results));
		assertThat(removeExecutorResults(observers.resultsA), array(results));
		assertThat(removeExecutorResults(observers.resultsB), arrayWithSize(0));
	}
	
	private function removeExecutorResults (results: Array) : Array {
		var filtered:Array = [];
		for each (var result:Object in results) {
			if (result is CommandData) continue;
			filtered.push(result);
		}
		return filtered;
	}
	
	private function validateError (error: Object): void {	
		if (error) {
			assertThat(observers.errors, arrayWithSize(1));
			assertThat(rootCause(observers.errors[0]), equalTo(error));
		}
		else {
			assertThat(observers.errors, arrayWithSize(0));
		}
	}
	
	private function rootCause (error: Object): Object {
		if (error is CommandFailure) {
			return rootCause(CommandFailure(error).cause);
		}
		else {
			return error;
		}
	}
	
	private function validateLifecycle (destroyCount:uint = 1) : void {
		assertThat(lastCommand.destroyCount, equalTo(1));
	}

	
	public function get commandSequenceConfig () : ConfigurationProcessor {
		throw new AbstractMethodError();
	}
	
	public function get parallelCommandsConfig () : ConfigurationProcessor {
		throw new AbstractMethodError();
	}
	
	public function get commandFlowConfig () : ConfigurationProcessor {
		throw new AbstractMethodError();
	}
	
	public function get singleCommandConfig () : ConfigurationProcessor {
		throw new AbstractMethodError();
	}
	
	public function get observerConfig () : ConfigurationProcessor {
		throw new AbstractMethodError();
	}
	
	
}
}
