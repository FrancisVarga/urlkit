package urlkit.rules
{

import flexunit.framework.*;
import flash.events.Event;
import urlkit.rules.*

public class TestUrlRuleSet extends TestCase
{

    public var r:UrlRuleSet;
    public var r1A:UrlValueRule;
    public var r2A:UrlValueRule;
    public var evtCount:int = 0;
    
    override public function setUp():void
    {
        r = new UrlRuleSet();
        r.type = UrlRuleSet.ANY;

        var r1:UrlRuleSet = new UrlRuleSet();
        r1.urlPattern="/abc/[^/]+";
        r.addChild(r1);

        r1A = new UrlValueRule();
        r1A.urlFormat = "/abc/*";
        r1.addChild(r1A);

        var r2:UrlRuleSet = new UrlRuleSet();
        r2.urlPattern="/def/[^/]+";
        r.addChild(r2);

        r2A = new UrlValueRule();
        r2A.urlFormat = "/def/*";
        r2.addChild(r2A);

        r.addEventListener(Event.CHANGE, function(e:Event):void { evtCount++; });
    }
    
    public function testInitialConditions():void
    {
        Assert.assertTrue("initially active", r.active);
        Assert.assertEquals("initial change count", 0, evtCount);
    }
    
    public function testGeneration():void
    {
        r1A.stringValue = "111";
        r2A.stringValue = "222";
        Assert.assertEquals("/abc/111/def/222", r.url);
        Assert.assertTrue("now active", r.active);
        
        // deactivating the 2nd rule should cause its url to drop out altogether
        r2A.stringValue = "";
        Assert.assertEquals("/abc/111", r.url);
        Assert.assertTrue("still active", r.active);
    }
    
    public function testGenerationExclusive():void
    {
        r.type = UrlRuleSet.ONE;
        r1A.stringValue = "111";
        r2A.stringValue = "222";
        Assert.assertEquals("/abc/111", r.url);
        Assert.assertTrue("now active", r.active);

        r1A.stringValue = ""; // frees up 2nd rule to fire
        Assert.assertEquals("/def/222", r.url);
     }
    
    public function testRuleApplication():void
    {
        Assert.assertEquals("", r1A.url);
        Assert.assertEquals("", r2A.url);

        r.containerUrl = "/abc/111";
        Assert.assertEquals("/abc/111", r.url);
        Assert.assertEquals(r.url, "111", r1A.stringValue);
        Assert.assertEquals(r.url, "", r2A.stringValue);

        r.containerUrl = "/def/222";
        Assert.assertEquals("/def/222", r.url);
        Assert.assertEquals(r.url, "111", r1A.stringValue);   // note: undisturbed since pat rule doesn't fire
        Assert.assertEquals(r.url, "222", r2A.stringValue);

        r.containerUrl = "/abc/333/def/444";
        Assert.assertEquals("/abc/333/def/444", r.url);
        Assert.assertEquals(r.url, "333", r1A.stringValue);
        Assert.assertEquals(r.url, "444", r2A.stringValue);
    }
}
}
