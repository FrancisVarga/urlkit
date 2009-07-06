/* 
 * Copyright (c) 2006 Allurent, Inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished
 * to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
package urlkit.rules
{

import flash.events.*;
import flash.external.*;
import flash.net.*;
import flash.system.*;
import flash.utils.Timer;
import flash.utils.getDefinitionByName;

import mx.controls.*;
import mx.core.*;
import mx.events.*;
import mx.managers.*;

/**
 * This class is the interface interacts with an instance of IUrlApplicationState
 * on behalf of the containing HTML browser.  It changes the app state to
 * correspond to browser-initiated changes, and also updates the browser
 * location and history to correspond to application-initiated changes.
 */
public class FlexBrowserManagerAdapter extends EventDispatcher implements IMXMLObject
{
    private var _browserManager:IBrowserManager;

    // flag indicating that our owning application document is completely set up
    private var _complete:Boolean = false;
    
    // the latest browser URL that we know of
    private var _browserUrl:String;
    
    // default application URL associated with a blank URL
    private var _defaultUrl:String = "";
    
    // our owning application document
    private var _document:Object;

    // flag indicating that the state of the application needs to be updated.
    private var _updateRequested:Boolean = false;
    
    // instance of IUrlApplicationState that is coupled to this browser manager.
    private var _applicationState:IUrlApplicationState;

    // flag indicating that the application state has been considered once after creationComplete
    private var _stateInitialized:Boolean = false;

    // flag indicating that the browser manager is enabled.
    private var _enabled:Boolean = true;

    // static handle to single instance of this adapter
    private static var _instance:FlexBrowserManagerAdapter = null;
    
    /**
     * Construct an instance of FlexBrowserManager and initialize the external interface to the browser.
     */    
    public function FlexBrowserManagerAdapter()
    {
        if (_instance == null)
        {
            _instance = this;
        }
        else
        {
            throw new Error("Attempt to instantiate FlexBrowserManagerAdapter multiple times");
        }
    }

    /**
     * Retrieve singleton instance of the FlexBrowserManagerAdapter.
     */
    public static function getInstance():FlexBrowserManagerAdapter
    {
        return _instance;
    }

    /**
     * Callback in IMXMLObject letting us know what our owning document is.
     * @param document the owning document
     * @param id component ID, if any
     * 
     */    
    public function initialized(document:Object, id:String):void
    {
        _document = document;
        _document.addEventListener(FlexEvent.CREATION_COMPLETE, creationComplete);
    }

    /**
     * Handle the eventual completion of the owning application document
     * by updating the URL state.  This is done via the normal deferred call
     * in order to pick up any URL rule changes that occur in other listeners
     * for the same creationComplete event in the same event processing cycle.
     */
    private function creationComplete(event:Event):void
    {
        _complete = true;
        if (_enabled)
        {
            updateState();
        }
    }

    /**
     * The enabled state of this FlexBrowserManagerAdapter.  Set this flag
     * to false in the MXML definition of this object in order to delay initialization
     * of the UrlKit system, then programmatically set it to true later once the
     * application is fully initialized.
     */
    public function get enabled():Boolean
    {
        return _enabled;
    }

    public function set enabled(flag:Boolean):void
    {
        if (_enabled != flag)
        {
            _enabled = flag;
            if (_enabled && _complete)
            {
                updateState();
            }
        }
    }
    
    [Bindable("change")]
    /**
     * Set the URL to be exhibited by the browser.
     * @param newUrl the updated browser URL
     * 
     */
    public function set browserUrl(newUrl:String):void
    {
        if (newUrl == _defaultUrl)
        {
            // NOTE: Workaround for Flex bug SDK-12955.
            // fake out the browser URL as blank if we determined earlier that a blank
            // fragment was present at initialization, and we're trying to change back to the default.
            newUrl = "";
        }
        
        if (_browserUrl != newUrl)
        {
            dispatchEvent(new Event(Event.CHANGE));

            if (_complete && _enabled)
            {
	            _browserManager.setFragment(newUrl);
            }
        }
    }

    /**
     * @return the current URL exhibited by the browser.
     */
    public function get browserUrl():String
    {
        return _browserManager.fragment;
    }

    /**
     * Navigate to a given URL fragment, simultaneously setting both the browser location
     * and the application state.  This function may only be called once the
     * FlexBrowserManagerAdapter has been enabled and is started.
     *
     * @param newUrl the URL fragment to which the application should navigate.
     */
    public function navigate(url:String):void
    {
        if (!(_enabled && _complete))
        {
            throw new Error("navigate() not allowed until UrlKit is enabled and started.");
        }
        browserUrl = url;
        applicationState.containerUrl = url;
    }
    

    /**
     * Event handler called in response to STATE_CHANGE events
     * dispatched by the applicationState object; schedules a deferred
     * synchronization of the browser state to the application if not
     * already scheduled.
     */
    private function updateState(e:Event=null):void
    {
        if (!_updateRequested)
        {
            UIComponent(_document).callLater(syncState, []);
            _updateRequested = true;
        }
    }
    
    /**
     * Synchronize the state of the browser to the application, if this was
     * requested.
     */
    private function syncState():void
    {
        if (_updateRequested && _complete && _enabled && applicationState != null)
        {
            try
            {
                // If this browser manager has ever been initialized before,
                // just copy the browser URL and title out to the JS world.
                // Otherwise, initialize the default URL state.
                if (_stateInitialized)
                {
                    browserUrl = applicationState.url;
                    title = applicationState.title;
                    _updateRequested = false;
                }
                else
                {
                    _updateRequested = false;
                    initializeState();
                }
            }
            catch (e:StateNotAvailableError)
            {
                // the application state could not be computed yet;
                // try again later.
                var t:Timer = new Timer(100, 1);
                t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { syncState(); });
                t.start();
            }
        }
    }

    /**    
     * Note the application state, taking it to be state for the default URL
     * to be navigated to if returning via the browser history to a URL with
     * no particular state embedded in it.
     */
    private function initializeState():void
    {
        try
        {
            _browserManager = BrowserManager.getInstance();
        }
        catch (e:Error)
        {
            // Defensively register BrowserManager singleton in case we are running
            // in a Flex 2 environment
            //
            Singleton.registerClass("mx.managers::IBrowserManager",
                Class(getDefinitionByName("mx.managers::BrowserManagerImpl")));
            _browserManager = BrowserManager.getInstance();
        }
        
        _browserManager.addEventListener(BrowserChangeEvent.BROWSER_URL_CHANGE, setPlayerUrl);
    	_browserManager.init(applicationState.url, applicationState.title);
        _stateInitialized = true;
        
        if (browserUrl == "")
        {
            // NOTE: Workaround for Flex bug SDK-12955.
            _defaultUrl = applicationState.url;  // save this URL for workaround on empty URL later
        }
        
        Application.application.addEventListener(MouseEvent.MOUSE_DOWN, ieTitleBugWorkaround);
     }
     
     /**
      * Work around a bug in IE title handling by forcing the title back to what it should be as soon
      * as there is a mouse down in the application.
      */
     private function ieTitleBugWorkaround(event:Event):void
     {
         Application.application.removeEventListener(MouseEvent.MOUSE_DOWN, ieTitleBugWorkaround);
         try
         {
             title = applicationState.title;
         }
         catch (e:StateNotAvailableError) {
         }
     }
   
    /**
     * Set the URL of the application to the given URL.
     * @param newUrl a new URL originating from the browser.
     */
    private function setPlayerUrl(e:BrowserChangeEvent):void
    {
        var url:String = browserUrl;
        if (url == "")
        {
            // NOTE: Workaround for Flex bug SDK-12955.  Initing the BrowserManager above
            // should remove any need to do this.
            url = _defaultUrl;
        }
        applicationState.containerUrl = url;
    }

    /**
     * The instance of IUrlApplicationState representing the state of the
     * application, exposing a URL and window title.
     */
    public function get applicationState():IUrlApplicationState
    {
        return _applicationState;
    }
    
    /**
     * Set the app state, listening for events indicating that the browser
     * must expose a new URL.
     */
    public function set applicationState(state:IUrlApplicationState):void
    {
        if (_applicationState != null)
        {
            _applicationState.removeEventListener(UrlBaseRule.STATE_CHANGE, updateState);
        }

        _applicationState = state;

        if (_applicationState != null)
        {
            _applicationState.addEventListener(UrlBaseRule.STATE_CHANGE, updateState);
        }
    }

    /**
     * Explicitly set the window title.
     * @param s the title of the browser window
     */
    public function set title(s:String):void
    {
    	_browserManager.setTitle(s);
    }
}
}
