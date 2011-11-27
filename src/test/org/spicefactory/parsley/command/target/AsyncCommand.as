/*
 * Copyright 2011 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.spicefactory.parsley.command.target {

import org.spicefactory.parsley.command.trigger.TriggerA;
/**
 * @author Jens Halm
 */
public class AsyncCommand {
	
	
	private var callback: Function;
	
	public var destroyCount: uint;
	
	public var result: Object;
	
	
	function AsyncCommand (result: Object = null) {
		this.result = result;
	}
	
	
	public function execute (event:TriggerA, callback:Function) : void {
		this.callback = callback;
	}
	
	public function invokeCallback (): void {
		callback(result);
	}
	
	public function cancel (): void {
		callback();
	}
	
	[Destroy]
	public function destroy (): void {
		destroyCount++;
	}
	
	
}
}
