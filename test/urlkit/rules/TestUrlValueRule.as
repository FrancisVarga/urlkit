package urlkit.rules
{

import flexunit.framework.*
import flash.events.Event;;
import urlkit.rules.*

public class TestUrlValueRule extends TestCase
{
    public function testUrl():void
    {
        var r:UrlValueRule = new UrlValueRule();
        Assert.assertFalse(r.active);

        // a UrlValueRule has a regexp of (.*) by default, so anything should match
        r.containerUrl = "testUrl";
        Assert.assertEquals("testUrl", r.url);
        Assert.assertEquals("testUrl", r.stringValue);
        Assert.assertTrue(r.active);

        r.containerUrl = null;
        Assert.assertEquals("", r.url);
        Assert.assertEquals("", r.stringValue);
        Assert.assertFalse(r.active);
    }
    
    public function testDefaultValue():void
    {
        var r:UrlValueRule = new UrlValueRule();
        r.urlFormat="/*";
        Assert.assertFalse(r.active);
        r.defaultValue = "foo";

        r.stringValue = "bar";
        Assert.assertTrue(r.active);
        Assert.assertEquals("/bar", r.url);
        
        r.stringValue = "foo";
        Assert.assertTrue(r.active);
        Assert.assertEquals("", r.url);
        
        r.containerUrl = "/bar";
        Assert.assertTrue(r.active);
        Assert.assertEquals("bar", r.stringValue);

        r.containerUrl = "/foo/bar";
        Assert.assertTrue(r.active);
        Assert.assertEquals("foo", r.stringValue);

        // make sure that chars not requiring escaping are handled by default url pattern regexp
        r.containerUrl = "/foo.!~*'()._-abc/bar";
        Assert.assertTrue(r.active);
        Assert.assertEquals("foo.!~*'()._-abc", r.stringValue);

        r.containerUrl = "";
        Assert.assertTrue(r.active);
        Assert.assertEquals("foo", r.stringValue);
    }
    
    public function testUrlChangeEvents():void
    {
        var r:UrlValueRule = new UrlValueRule();
        var evtCount:int = 0;
        r.addEventListener(Event.CHANGE, function(e:Event):void { evtCount++; });
        var stateChangeCount:int = 0;
        r.addEventListener(UrlBaseRule.STATE_CHANGE, function(e:Event):void { stateChangeCount++; });
        
        // The following generates no event because null URL doesn't represent any change
        r.containerUrl = null;
        Assert.assertEquals(0, evtCount);

        r.containerUrl = "foo";
        Assert.assertEquals(1, evtCount);
        r.containerUrl = "bar";
        Assert.assertEquals(2, evtCount);  // changes should occur
        
        r.containerUrl = "bar";   // reassignment of same value should not trigger change
        Assert.assertEquals(2, evtCount);
        
        // The following generates no event because it's not a browser-initiated change
        Assert.assertEquals(0, stateChangeCount);
        r.stringValue = "garble";
        Assert.assertEquals("garble", r.url);
        Assert.assertEquals(2, evtCount);
        Assert.assertEquals(1, stateChangeCount);
        
        // change in title should generate a state change event
        r.title = "newTitle";
        Assert.assertEquals("newTitle", r.title);
        Assert.assertEquals(2, evtCount);
        Assert.assertEquals(2, stateChangeCount);
    }

    public function testStringValue():void
    {
        var r:UrlValueRule = new UrlValueRule();
        r.stringValue = "foo";
        Assert.assertTrue(r.active);
        Assert.assertEquals("foo", r.url);
        r.containerUrl = "bar";
        Assert.assertEquals("bar", r.stringValue);
        
        r.stringValue="abc/def\u0099ghi\u0199jkl\u0999"
        Assert.assertEquals("abc%2Fdef%C2%99ghi%C6%99jkl%E0%A6%99", r.url);
        r.containerUrl = "xyz%2Fxyz%C2%99xyz%C6%99xyz%E0%A6%99";
        Assert.assertEquals("xyz/xyz\u0099xyz\u0199xyz\u0999", r.stringValue);
    }

    public function testNumberValue():void
    {
        var r:UrlValueRule = new UrlValueRule();
        r.numberValue = 123;
        Assert.assertStrictlyEquals("123", r.url);
        r.numberValue = 123.4;
        Assert.assertStrictlyEquals("123.4", r.url);
        r.containerUrl = "123%2E4";
        Assert.assertStrictlyEquals(123.4, r.numberValue);
        r.containerUrl = "abc";
        Assert.assertTrue(isNaN(r.numberValue));
    }

    public function testBooleanValue():void
    {
        var r:UrlValueRule = new UrlValueRule();
        r.booleanValue = false;
        Assert.assertStrictlyEquals("f", r.url);
        r.booleanValue = true;
        Assert.assertStrictlyEquals("t", r.url);
        r.containerUrl = "t";
        Assert.assertTrue(r.booleanValue);
        r.containerUrl = "f";
        Assert.assertFalse(r.booleanValue);
        r.containerUrl = "";
        Assert.assertFalse(r.booleanValue);
        r.containerUrl = "x";
        Assert.assertFalse(r.booleanValue);
    }

    public function testRequired():void
    {
        var r:UrlValueRule = new UrlValueRule();
        Assert.assertFalse(r.active);

        r.defaultValue = "";
        Assert.assertTrue(r.active);

        Assert.assertEquals("", r.url);
    }
    
    public function testSourceValue():void
    {
        var s:SourceValue = new SourceValue();
        s.initialized = true;
        
        s.foo = "abc";
        Assert.assertEquals("abc", s.r1.url);
        
        s.r1.containerUrl = "def";
        Assert.assertEquals("def", s.foo);
        
        s.c1.s1 = "111";
        Assert.assertEquals("111", s.r2.url);
        s.r2.containerUrl = "222";
        Assert.assertEquals("222", s.c1.s1);
        var c1p:ComplexValue = new ComplexValue();
        c1p.s1 = "222a";
        s.c1 = c1p;
        Assert.assertEquals("222a", s.r2.url);
        s.c1.s1 = null;
        Assert.assertEquals("", s.r2.url);
        s.r2.containerUrl = "222b";
        Assert.assertEquals("222b", s.c1.s1);
        s.c1 = null;
        Assert.assertEquals("", s.r2.url);

        s.r3.containerUrl = "000";   // should not cause trouble.
        var c2p:ComplexValue = new ComplexValue();
        c2p.s1 = "333";
        s.c2 = c2p;
        Assert.assertEquals("333", s.r3.url);
        c2p.s1 = "333a";
        Assert.assertEquals("333a", s.r3.url);
        s.r3.containerUrl = "333b";
        Assert.assertEquals("333b", s.c2.s1);
        
        Assert.assertEquals("", s.r4.url);
        var c2c1p:ComplexValue = new ComplexValue();
        c2c1p.s1 = "444";
        s.c2.c1 = c2c1p;
        Assert.assertEquals("444", s.r4.url);
    }
}

}
