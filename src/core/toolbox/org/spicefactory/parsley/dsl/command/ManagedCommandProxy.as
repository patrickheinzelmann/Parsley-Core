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
package org.spicefactory.parsley.dsl.command {

import org.spicefactory.lib.command.Command;
import org.spicefactory.lib.command.proxy.DefaultCommandProxy;
import org.spicefactory.parsley.core.command.ManagedCommand;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.core.messaging.Message;

/**
 * @author Jens Halm
 */
public class ManagedCommandProxy extends DefaultCommandProxy implements ManagedCommand {


	private var _context:Context;
	private var _id:String;
	private var _trigger:Message;
	

	function ManagedCommandProxy (target:Command = null,
			context:Context = null, id:String = null, trigger:Message = null) {
		this.target = target;
		_context = context;
		_id = id;
		_trigger = trigger;
	}


	public function init (context:Context, id:String = null) : void {
		this.target = target;
		_context = context;
		_id = id;
	}

	public function get context () : Context {
		return _context;
	}

	public function get id () : String {
		return _id;
	}
	
	public function get trigger () : Message {
		return _trigger;
	}
	

}
}