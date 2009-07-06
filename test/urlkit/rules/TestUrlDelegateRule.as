package urlkit.rules
{

import flexunit.framework.*
import flash.events.Event;;
import urlkit.rules.*

public class TestUrlDelegateRule extends TestCase
{

    public var r:UrlDelegateRule;
    public var r1:UrlValueRule;
    public var evtCount:int = 0;
    public var childEvtCount:int = 0;
    
    override public function setUp():void
    {
        r = new UrlDelegateRule();
        r.addEventListener(Event.CHANGE, function(e:Event):void { evtCount++; });
        r1 = new UrlValueRule();
        r1.addEventListener(Event.CHANGE, function(e:Event):void { childEvtCount++; });
        r.rule = r1;
        evtCount = 0;
    }
    
    public function testInitialConditions():void
    {
        Assert.assertFalse("initially inactive", r.active);
        Assert.assertFalse("child initially inactive", r1.active);
    }
    
    public function testGeneration():void
    {
        r1.stringValue = "111";
        Assert.assertEquals("111", r.url);
        Assert.assertEquals("change count from children", 0, childEvtCount);
        Assert.assertEquals("change count", 0, evtCount);
        Assert.assertTrue("now active", r.active);
    }
    
    public function testRuleApplication():void
    {
        r.containerUrl = "111";
        Assert.assertEquals("change count from children", 1, childEvtCount);
        Assert.assertEquals("change count", 1, evtCount);
        Assert.assertEquals("111", r1.url);
        Assert.assertTrue("now active", r1.active);
    }
    
    public function testChildInit():void
    {
        r.rule = null;
        r.containerUrl = "111";
        r1.stringValue = "222";
        r.rule = r1;
        Assert.assertEquals("111", r.url);
        Assert.assertTrue("now active", r.active);
    }
    
    public function testStrictPrefixMatching():void
    {
        r1.urlFormat="/*";
        r.strictMatching = true;
        assertEquals("Matching is strict", "/bar", r.matchUrlPrefix("/bar/111"));
        r.strictMatching = false;
        assertEquals("Matching is relaxed", "/bar/111", r.matchUrlPrefix("/bar/111"));
    }
}
}
