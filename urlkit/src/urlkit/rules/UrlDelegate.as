// =================================================================
/*
 *  Copyright (c) 2009
 *  Lance Pollard
 *  http://www.viatropos.com
 *  lancejpollard at gmail dot com
 *  
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 * 
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */
// =================================================================

package urlkit.rules
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/**
	 *	The UrlDelegate is a value object for holding the child view that will
	 *	create the sub url.
	 *	
	 *	It gets the URL from that view, through "urlRules" by default,
	 *	unless you specify another id
	 */
	public class UrlDelegate extends EventDispatcher
	{
		private var _target:*;
		[Bindable(event="targetChange")]
		/**
		 *  The target of this delegate, what it wraps
		 */
		public function get target():*
		{
			return _target;
		}
		public function set target(value:*):void
		{
			if (_target == value) 
				return;
			_target = value;
			dispatchEvent(new Event("targetChange"));
		}
		
		private var _ruleId:String = 'urlRules';
		/**
		 *  id of the rule
		 */
		public function get ruleId():String
		{
			return _ruleId;
		}
		public function set ruleId(value:String):void
		{
			_ruleId = value;
		}
		
		[Bindable(event="targetChange")]
		public function get rule():IUrlRule
		{
			if (target && ruleId in target)
				return target[ruleId];
			return null;
		}
	
		/**
		 *	UrlDelegate Constructor
		 */
		public function UrlDelegate()
		{
			super();
		}
	}
}