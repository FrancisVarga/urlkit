package urlkit.rules
{

import flexunit.framework.*
import flash.events.Event;
import mx.containers.Accordion;
import mx.containers.Canvas;
import urlkit.rules.*

public class TestUrlNavigatorRule extends TestCase
{
    public var r:UrlNavigatorRule;
    public var a:Accordion;
    public var c1:Canvas;
    public var c2:Canvas;
    public var c3:Canvas;
    public var evtCount:int = 0;
    
    override public function setUp():void
    {
        r = new UrlNavigatorRule();
        a = new Accordion();
        r.accordion = a;

        c1 = new Canvas();
        c1.label = "111";
        a.addChild(c1);

        c2 = new Canvas();
        c2.label = "222";
        a.addChild(c2);

        c3 = new Canvas();
        c3.label = "333";
        a.addChild(c3);
        
        r.addEventListener(Event.CHANGE, function(e:Event):void {evtCount++;});
    }
    
    public function testRuleApplication():void
    {
        r.containerUrl = "111";
        Assert.assertEquals(0, a.selectedIndex);
        Assert.assertEquals("c1", c1, a.selectedChild);
        Assert.assertEquals("111", r.url);

        r.containerUrl = "222";
        Assert.assertEquals(0, a.selectedIndex);
        a.initialized = true;   // delayed initialization should cause accordion to track
        Assert.assertEquals(1, a.selectedIndex);
        Assert.assertEquals("c2", c2, a.selectedChild);
        Assert.assertEquals("222", r.url);

        r.containerUrl = "";
        Assert.assertEquals(1, a.selectedIndex);
        Assert.assertEquals("c2", c2, a.selectedChild);
        Assert.assertEquals("", r.url);

        r.containerUrl = "xxx";
        Assert.assertEquals(1, a.selectedIndex);
        Assert.assertEquals("c2", c2, a.selectedChild);

        r.containerUrl = "333";
        Assert.assertEquals(2, a.selectedIndex);
        Assert.assertEquals("c3", c3, a.selectedChild);
    }
    
    public function testGeneration():void
    {
        evtCount = 0;
        a.selectedIndex = 0;
        try 
        {
            Assert.assertEquals("111", r.url);
            fail("should have thrown error");
        }
        catch (e:StateNotAvailableError)
        {
        }
        a.initialized = true;
        Assert.assertEquals("111", r.url);
        Assert.assertEquals(0, evtCount);

        a.selectedIndex = 1;
        Assert.assertEquals("222", r.url);

        a.selectedChild = c3;
        Assert.assertEquals("333", r.url);
    }
    
    public function testControlInit():void
    {
        r.accordion = null;
        r.containerUrl = "222";
        r.accordion = a;
        a.initialized = true;
        Assert.assertEquals("222", r.url);
        Assert.assertEquals(1, a.selectedIndex);
        Assert.assertEquals("c2", c2, a.selectedChild);
    }

    public function testControlInit2():void
    {
        r.accordion = null;
        r.containerUrl = "222";
        a.initialized = true;
        r.accordion = a;
        Assert.assertEquals("222", r.url);
        Assert.assertEquals(1, a.selectedIndex);
        Assert.assertEquals("c2", c2, a.selectedChild);
    }
}

}
